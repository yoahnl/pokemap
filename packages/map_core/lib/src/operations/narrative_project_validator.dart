import 'package:meta/meta.dart' show immutable;

import '../diagnostics/cinematic_diagnostics.dart';
import '../diagnostics/event_scene_link_diagnostics.dart';
import '../diagnostics/scene_diagnostics.dart';
import '../diagnostics/storyline_scene_link_diagnostics.dart';
import '../diagnostics/world_rule_diagnostics.dart';
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';
import '../models/world_rule.dart';
import '../read_models/narrative_event_validation_read_model.dart';
import '../validation/beta_playability_validator.dart';
import 'build_narrative_event_project_catalog.dart';
import 'build_narrative_event_validation_report.dart';
import 'narrative_validator.dart';

/// Severity shared by every diagnostic displayed by Narrative Validator.
enum NarrativeProjectDiagnosticSeverity { info, warning, error }

/// Stable product domains used by filters and navigation.
enum NarrativeProjectDiagnosticDomain {
  storyline,
  scene,
  event,
  dialogue,
  cinematic,
  fact,
  worldRule,
  map,
  runtime,
}

/// Product routes supported by the global Validator.
enum NarrativeProjectDiagnosticDestination {
  overview,
  map,
  event,
  scene,
  storyline,
  dialogue,
  cinematic,
  fact,
  worldRule,
}

enum NarrativeMapEventsGroupKind { map, outcomes, unassigned }

@immutable
final class NarrativeProjectDiagnostic {
  const NarrativeProjectDiagnostic({
    required this.code,
    required this.severity,
    required this.domain,
    required this.message,
    required this.path,
    required this.destination,
    this.suggestedFixLabel,
    this.mapId,
    this.eventId,
    this.sceneId,
    this.dialogueId,
    this.cinematicId,
    this.storylineId,
    this.chapterId,
    this.stepId,
    this.factId,
    this.worldRuleId,
  });

  final String code;
  final NarrativeProjectDiagnosticSeverity severity;
  final NarrativeProjectDiagnosticDomain domain;
  final String message;
  final String path;
  final NarrativeProjectDiagnosticDestination destination;
  final String? suggestedFixLabel;
  final String? mapId;
  final String? eventId;
  final String? sceneId;
  final String? dialogueId;
  final String? cinematicId;
  final String? storylineId;
  final String? chapterId;
  final String? stepId;
  final String? factId;
  final String? worldRuleId;

  /// Validator V1 never advertises a mutation unless it is deterministic.
  /// No aggregated diagnostic currently satisfies that contract.
  bool get hasDeterministicRepair => false;

  String get stableKey => <String?>[
        severity.name,
        domain.name,
        code,
        path,
        mapId,
        eventId,
        sceneId,
        dialogueId,
        cinematicId,
        storylineId,
        chapterId,
        stepId,
        factId,
        worldRuleId,
      ].map((value) => value ?? '').join('\u001f');
}

@immutable
final class NarrativeMapEventEntry {
  const NarrativeMapEventEntry({
    required this.eventId,
    required this.label,
    required this.enabled,
    required this.sourceKind,
    required this.sourceConnected,
    required this.sceneId,
    required this.sceneConnected,
    required this.conditionCount,
    required this.diagnosticCount,
    this.warningCount = 0,
    this.mapId,
    this.sourceOwnerId,
    this.sourceOwnerLabel,
    this.sourceEntityKind,
    this.sceneLabel,
  });

  final String eventId;
  final String label;
  final bool? enabled;
  final NarrativeEventSourceKind? sourceKind;
  final String? mapId;
  final String? sourceOwnerId;
  final String? sourceOwnerLabel;
  final MapEntityKind? sourceEntityKind;
  final bool sourceConnected;
  final String? sceneId;
  final String? sceneLabel;
  final bool sceneConnected;
  final int conditionCount;
  final int diagnosticCount;
  final int warningCount;
}

@immutable
final class NarrativeMapEventsView {
  NarrativeMapEventsView({
    required this.groupKind,
    required this.mapId,
    required this.label,
    required List<NarrativeMapEventEntry> events,
  }) : events = List<NarrativeMapEventEntry>.unmodifiable(events);

  final NarrativeMapEventsGroupKind groupKind;
  final String? mapId;
  final String label;
  final List<NarrativeMapEventEntry> events;

  int get errorCount =>
      events.fold(0, (sum, event) => sum + event.diagnosticCount);
  int get orphanSourceCount =>
      events.where((event) => !event.sourceConnected).length;
}

@immutable
final class NarrativeProjectValidationReport {
  NarrativeProjectValidationReport({
    required List<NarrativeProjectDiagnostic> diagnostics,
    required List<NarrativeMapEventsView> mapEventViews,
  })  : diagnostics =
            List<NarrativeProjectDiagnostic>.unmodifiable(diagnostics),
        mapEventViews =
            List<NarrativeMapEventsView>.unmodifiable(mapEventViews);

  final List<NarrativeProjectDiagnostic> diagnostics;
  final List<NarrativeMapEventsView> mapEventViews;

  int get errorCount => diagnostics
      .where(
          (item) => item.severity == NarrativeProjectDiagnosticSeverity.error)
      .length;
  int get warningCount => diagnostics
      .where(
          (item) => item.severity == NarrativeProjectDiagnosticSeverity.warning)
      .length;
  int get infoCount => diagnostics
      .where((item) => item.severity == NarrativeProjectDiagnosticSeverity.info)
      .length;
  int get totalEventCount => mapEventViews.fold(
        0,
        (sum, view) => sum + view.events.length,
      );
  bool get isPlayable => errorCount == 0;

  List<NarrativeProjectDiagnostic> byCode(String code) =>
      List<NarrativeProjectDiagnostic>.unmodifiable(
        diagnostics.where((item) => item.code == code),
      );

  List<NarrativeProjectDiagnostic> byDomain(
    NarrativeProjectDiagnosticDomain domain,
  ) =>
      List<NarrativeProjectDiagnostic>.unmodifiable(
        diagnostics.where((item) => item.domain == domain),
      );
}

/// Builds the single narrative playability verdict used by the editor.
///
/// Existing domain diagnostics remain the source of truth. This operation
/// maps them into one stable report, then adds only the cross-domain static
/// solvability checks that cannot belong to an individual asset validator.
NarrativeProjectValidationReport validateNarrativeProject(
  ProjectManifest project, {
  required List<MapData> maps,
  Set<String>? knownSpeciesIds,
  Set<String>? knownMoveIds,
  bool requirePokemonCatalogs = false,
}) {
  final diagnostics = <NarrativeProjectDiagnostic>[];
  final mapsById = {for (final map in maps) map.id: map};
  final normalizedKnownSpeciesIds =
      knownSpeciesIds == null ? null : _trimmedNonBlankIds(knownSpeciesIds);
  final normalizedKnownMoveIds =
      knownMoveIds == null ? null : _trimmedNonBlankIds(knownMoveIds);

  _appendLegacyNarrativeDiagnostics(project, maps, diagnostics);
  _appendSceneDiagnostics(project, diagnostics);
  _appendSceneBattleReadinessDiagnostics(
    project,
    diagnostics,
    knownSpeciesIds: normalizedKnownSpeciesIds,
    knownMoveIds: normalizedKnownMoveIds,
  );
  _appendStorylineLinkDiagnostics(project, diagnostics);
  _appendCinematicDiagnostics(project, diagnostics);
  _appendWorldRuleDiagnostics(project, maps, diagnostics);
  _appendEventSceneLinkDiagnostics(project, maps, diagnostics);
  _appendEventV2Diagnostics(project, maps, diagnostics);
  _appendRuntimeReadinessDiagnostics(
    project,
    mapsById,
    diagnostics,
    knownSpeciesIds: normalizedKnownSpeciesIds,
    knownMoveIds: normalizedKnownMoveIds,
    requirePokemonCatalogs: requirePokemonCatalogs,
  );
  _appendSolvabilityDiagnostics(project, maps, diagnostics);

  final normalized = <String, NarrativeProjectDiagnostic>{};
  for (final diagnostic in diagnostics) {
    normalized.putIfAbsent(diagnostic.stableKey, () => diagnostic);
  }
  final sorted = normalized.values.toList()..sort(_compareDiagnostics);
  final mapViews = _buildMapEventViews(
    project,
    mapsById: mapsById,
    diagnostics: sorted,
  );
  return NarrativeProjectValidationReport(
    diagnostics: sorted,
    mapEventViews: mapViews,
  );
}

void _appendLegacyNarrativeDiagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseNarrativeProject(project, maps: maps).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.kind.name,
        severity: _legacySeverityForProject(project, diagnostic),
        domain: _legacyDomain(diagnostic.kind),
        message: diagnostic.message,
        path: diagnostic.path,
        destination: _legacyDestination(diagnostic),
        mapId: diagnostic.mapId,
        sceneId: diagnostic.scenarioId,
        dialogueId: _legacyDialogueId(diagnostic),
      ),
    );
  }
}

void _appendSceneDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final scene in project.scenes) {
    for (final diagnostic
        in diagnoseSceneAgainstProject(scene, project).diagnostics) {
      final dialogueId =
          diagnostic.code == SceneDiagnosticCode.dialogueRefUnknown
              ? _sceneNodeDialogueId(scene, diagnostic.nodeId)
              : null;
      target.add(
        NarrativeProjectDiagnostic(
          code: diagnostic.code.name,
          severity: switch (diagnostic.severity) {
            SceneDiagnosticSeverity.error =>
              NarrativeProjectDiagnosticSeverity.error,
            SceneDiagnosticSeverity.warning =>
              NarrativeProjectDiagnosticSeverity.warning,
            SceneDiagnosticSeverity.info =>
              NarrativeProjectDiagnosticSeverity.info,
          },
          domain: dialogueId == null
              ? NarrativeProjectDiagnosticDomain.scene
              : NarrativeProjectDiagnosticDomain.dialogue,
          message: diagnostic.message,
          path: 'scenes.${scene.id}.${diagnostic.target.name}',
          destination: dialogueId == null
              ? NarrativeProjectDiagnosticDestination.scene
              : NarrativeProjectDiagnosticDestination.dialogue,
          suggestedFixLabel: diagnostic.suggestedFixLabel,
          sceneId: scene.id,
          dialogueId: dialogueId,
        ),
      );
    }
  }
}

void _appendStorylineLinkDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseStorylineSceneLinks(project: project).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code.name,
        severity: switch (diagnostic.severity) {
          StorylineSceneLinkDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          StorylineSceneLinkDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          StorylineSceneLinkDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.storyline,
        message: diagnostic.message,
        path:
            'storylines.${diagnostic.storylineId}.${diagnostic.chapterId}.${diagnostic.stepId}',
        destination: NarrativeProjectDiagnosticDestination.storyline,
        suggestedFixLabel: diagnostic.suggestedFixLabel,
        storylineId: diagnostic.storylineId,
        chapterId: diagnostic.chapterId,
        stepId: diagnostic.stepId,
        sceneId: diagnostic.sceneId,
      ),
    );
  }
}

void _appendCinematicDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseCinematicsAgainstProject(project).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code.name,
        severity: switch (diagnostic.severity) {
          CinematicDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          CinematicDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          CinematicDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.cinematic,
        message: diagnostic.message,
        path: 'cinematics.${diagnostic.cinematicId}.${diagnostic.target.name}',
        destination: NarrativeProjectDiagnosticDestination.cinematic,
        suggestedFixLabel: diagnostic.suggestedFixLabel,
        cinematicId: diagnostic.cinematicId,
      ),
    );
  }
}

void _appendWorldRuleDiagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseWorldRules(project, maps: maps).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code.name,
        severity: switch (diagnostic.severity) {
          WorldRuleDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          WorldRuleDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          WorldRuleDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.worldRule,
        message: diagnostic.message,
        path: 'worldRules.${diagnostic.ruleId}',
        destination: NarrativeProjectDiagnosticDestination.worldRule,
        suggestedFixLabel: diagnostic.suggestedFixLabel,
        mapId: diagnostic.mapId,
        worldRuleId: diagnostic.ruleId,
      ),
    );
  }
}

void _appendEventSceneLinkDiagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  for (final diagnostic
      in diagnoseEventSceneLinks(project: project, maps: maps).diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code.name,
        severity: switch (diagnostic.severity) {
          EventSceneLinkDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          EventSceneLinkDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          EventSceneLinkDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.event,
        message: diagnostic.message,
        path:
            'maps.${diagnostic.mapId}.events.${diagnostic.eventId}.pages.${diagnostic.pageNumber}',
        destination: NarrativeProjectDiagnosticDestination.event,
        suggestedFixLabel: diagnostic.suggestedFixLabel,
        mapId: diagnostic.mapId,
        eventId: diagnostic.eventId,
        sceneId: diagnostic.sceneId,
      ),
    );
  }
}

void _appendEventV2Diagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  final registry = project.eventRegistry;
  if (registry == null) return;
  final catalog =
      buildNarrativeEventProjectCatalog(project: project, maps: maps);
  final report = buildNarrativeEventValidationReport(
    registry: registry,
    catalog: catalog,
  );
  for (final diagnostic in report.diagnostics) {
    final destination = diagnostic.destination;
    target.add(
      NarrativeProjectDiagnostic(
        code: diagnostic.code,
        severity: switch (diagnostic.severity) {
          NarrativeEventValidationSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          NarrativeEventValidationSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          NarrativeEventValidationSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.event,
        message: diagnostic.message,
        path: diagnostic.path,
        destination: _eventDestination(destination.kind, destination.mapId),
        mapId: destination.mapId ?? _eventMapId(project, diagnostic.eventId),
        eventId: diagnostic.eventId ?? destination.eventId,
        sceneId: destination.sceneId,
      ),
    );
  }
}

void _appendRuntimeReadinessDiagnostics(
  ProjectManifest project,
  Map<String, MapData> mapsById,
  List<NarrativeProjectDiagnostic> target, {
  required Set<String>? knownSpeciesIds,
  required Set<String>? knownMoveIds,
  required bool requirePokemonCatalogs,
}) {
  final newGame = project.newGame;
  _appendConfiguredNewGameSpawnDiagnostics(project, mapsById, target);
  _appendPokemonCatalogAvailabilityDiagnostics(
    project,
    target,
    knownSpeciesIds: knownSpeciesIds,
    knownMoveIds: knownMoveIds,
    required: requirePokemonCatalogs,
  );
  final report = validateBetaPlayability(
    project,
    context: BetaPlayabilityValidationContext(
      mapsById: mapsById,
      startMapId: newGame.enabled ? newGame.startMapId : null,
      knownSpeciesIds: knownSpeciesIds ?? const <String>{},
      knownMoveIds: knownMoveIds ?? const <String>{},
      speciesCatalogIsAuthoritative: knownSpeciesIds != null,
      moveCatalogIsAuthoritative: knownMoveIds != null,
      initialPartySpeciesIds: {
        for (final pokemon in newGame.initialParty) pokemon.speciesId,
        for (final option in newGame.starterOptions) option.pokemon.speciesId,
      },
      initialPartyMoveIds: {
        for (final pokemon in newGame.initialParty)
          for (final move in pokemon.knownMoveIds) move,
        for (final option in newGame.starterOptions)
          for (final move in option.pokemon.knownMoveIds) move,
      },
      requiresInitialParty: false,
      requiresTrainerBattle: project.trainers.isNotEmpty,
      requiresSaveLoad: true,
      hasSaveLoadSupport: true,
    ),
  );
  for (final diagnostic in report.diagnostics) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtime${_upperFirst(diagnostic.kind.name)}',
        severity: switch (diagnostic.severity) {
          BetaPlayabilityDiagnosticSeverity.error =>
            NarrativeProjectDiagnosticSeverity.error,
          BetaPlayabilityDiagnosticSeverity.warning =>
            NarrativeProjectDiagnosticSeverity.warning,
          BetaPlayabilityDiagnosticSeverity.info =>
            NarrativeProjectDiagnosticSeverity.info,
        },
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message: diagnostic.message,
        path: diagnostic.path ?? 'runtime',
        destination: diagnostic.mapId == null
            ? NarrativeProjectDiagnosticDestination.overview
            : NarrativeProjectDiagnosticDestination.map,
        suggestedFixLabel: diagnostic.actionHint,
        mapId: diagnostic.mapId,
      ),
    );
  }
}

void _appendPokemonCatalogAvailabilityDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target, {
  required Set<String>? knownSpeciesIds,
  required Set<String>? knownMoveIds,
  required bool required,
}) {
  if (!required) return;
  if (knownSpeciesIds == null) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimePokemonSpeciesCatalogUnavailable',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le catalogue des espèces Pokémon n’a pas pu être chargé pour la validation.',
        path: 'pokemon.speciesDir',
        destination: NarrativeProjectDiagnosticDestination.overview,
        suggestedFixLabel: 'Vérifier le dossier ${project.pokemon.speciesDir}.',
      ),
    );
  }
  if (knownMoveIds == null) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimePokemonMoveCatalogUnavailable',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le catalogue des capacités Pokémon n’a pas pu être chargé pour la validation.',
        path: 'pokemon.catalogFiles.moves',
        destination: NarrativeProjectDiagnosticDestination.overview,
        suggestedFixLabel: 'Vérifier le fichier du catalogue des capacités.',
      ),
    );
  }
}

void _appendConfiguredNewGameSpawnDiagnostics(
  ProjectManifest project,
  Map<String, MapData> mapsById,
  List<NarrativeProjectDiagnostic> target,
) {
  final newGame = project.newGame;
  final spawnId = newGame.startSpawnId?.trim();
  if (!newGame.enabled || spawnId == null || spawnId.isEmpty) return;

  final mapId = newGame.startMapId.trim();
  final map = mapsById[mapId];
  if (map == null) return;

  MapEntity? spawn;
  for (final entity in map.entities) {
    if (entity.id == spawnId) {
      spawn = entity;
      break;
    }
  }
  final path = 'maps.$mapId.entities.$spawnId';
  if (spawn == null) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimeNewGameStartSpawnMissing',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le point de départ New Game « $spawnId » est absent de la map configurée.',
        path: path,
        destination: NarrativeProjectDiagnosticDestination.map,
        suggestedFixLabel: 'Choisir un point de départ joueur existant.',
        mapId: mapId,
      ),
    );
    return;
  }

  if (spawn.kind != MapEntityKind.spawn ||
      spawn.spawn?.role != EntitySpawnRole.playerStart) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimeNewGameStartSpawnNotPlayerStart',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le point de départ New Game « $spawnId » doit être un Spawn de rôle playerStart.',
        path: path,
        destination: NarrativeProjectDiagnosticDestination.map,
        suggestedFixLabel: 'Configurer cette entité comme départ joueur.',
        mapId: mapId,
      ),
    );
    return;
  }

  if (!_entityOriginIsInsideMap(map, spawn)) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'runtimeNewGameStartSpawnOutOfBounds',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.runtime,
        message:
            'Le point de départ New Game « $spawnId » se trouve hors des limites de la map.',
        path: path,
        destination: NarrativeProjectDiagnosticDestination.map,
        suggestedFixLabel: 'Replacer le départ joueur dans la map.',
        mapId: mapId,
      ),
    );
  }
}

void _appendSceneBattleReadinessDiagnostics(
  ProjectManifest project,
  List<NarrativeProjectDiagnostic> target, {
  required Set<String>? knownSpeciesIds,
  required Set<String>? knownMoveIds,
}) {
  final trainersById = {
    for (final trainer in project.trainers) trainer.id.trim(): trainer,
  };
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneBattlePayload ||
          (payload.battleKind != 'trainer' && payload.battleKind != 'static')) {
        continue;
      }
      final trainerId = payload.trainerId?.trim();
      final trainer = trainerId == null ? null : trainersById[trainerId];
      // Unknown references are already diagnosed by diagnoseSceneAgainstProject.
      if (trainerId == null || trainerId.isEmpty || trainer == null) continue;

      final nodePath = 'scenes.${scene.id}.nodes.${node.id}.battle';
      if (trainer.team.isEmpty) {
        target.add(
          _sceneBattleDiagnostic(
            code: 'sceneBattleTrainerHasEmptyTeam',
            message:
                'L’adversaire « $trainerId » de ce combat ne possède aucun Pokémon.',
            path: '$nodePath.trainerId',
            sceneId: scene.id,
            suggestedFixLabel: 'Ajouter au moins un Pokémon à son équipe.',
          ),
        );
        continue;
      }

      for (var index = 0; index < trainer.team.length; index += 1) {
        final pokemon = trainer.team[index];
        final pokemonPath = '$nodePath.trainer.$trainerId.team.$index';
        final speciesId = pokemon.speciesId.trim();
        if (speciesId.isEmpty) {
          target.add(
            _sceneBattleDiagnostic(
              code: 'sceneBattleTrainerPokemonMissingSpecies',
              message:
                  'Un Pokémon de l’adversaire « $trainerId » ne référence aucune espèce.',
              path: '$pokemonPath.speciesId',
              sceneId: scene.id,
              suggestedFixLabel: 'Choisir une espèce dans le catalogue.',
            ),
          );
        } else if (knownSpeciesIds != null &&
            !knownSpeciesIds.contains(speciesId)) {
          target.add(
            _sceneBattleDiagnostic(
              code: 'sceneBattleTrainerPokemonSpeciesUnknown',
              message:
                  'L’espèce « $speciesId » de l’adversaire « $trainerId » est absente du catalogue.',
              path: '$pokemonPath.speciesId',
              sceneId: scene.id,
              suggestedFixLabel: 'Choisir une espèce existante.',
            ),
          );
        }

        final normalizedMoveIds = pokemon.moves
            .map((moveId) => moveId.trim())
            .where((moveId) => moveId.isNotEmpty)
            .toList(growable: false);
        if (normalizedMoveIds.isEmpty) {
          target.add(
            _sceneBattleDiagnostic(
              code: 'sceneBattleTrainerPokemonMissingMoves',
              message:
                  'Un Pokémon de l’adversaire « $trainerId » ne possède aucune capacité utilisable.',
              path: '$pokemonPath.moves',
              sceneId: scene.id,
              suggestedFixLabel: 'Ajouter au moins une capacité.',
            ),
          );
        } else if (normalizedMoveIds.length != pokemon.moves.length) {
          target.add(
            _sceneBattleDiagnostic(
              code: 'sceneBattleTrainerPokemonMoveIdBlank',
              message:
                  'Une capacité de l’adversaire « $trainerId » possède une référence vide.',
              path: '$pokemonPath.moves',
              sceneId: scene.id,
              suggestedFixLabel: 'Retirer ou remplacer la capacité vide.',
            ),
          );
        }
        if (knownMoveIds != null) {
          for (final moveId in normalizedMoveIds) {
            if (knownMoveIds.contains(moveId)) continue;
            target.add(
              _sceneBattleDiagnostic(
                code: 'sceneBattleTrainerPokemonMoveUnknown',
                message:
                    'La capacité « $moveId » de l’adversaire « $trainerId » est absente du catalogue.',
                path: '$pokemonPath.moves',
                sceneId: scene.id,
                suggestedFixLabel: 'Choisir une capacité existante.',
              ),
            );
          }
        }
      }
    }
  }
}

Set<String> _trimmedNonBlankIds(Iterable<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet();

NarrativeProjectDiagnostic _sceneBattleDiagnostic({
  required String code,
  required String message,
  required String path,
  required String sceneId,
  required String suggestedFixLabel,
}) {
  return NarrativeProjectDiagnostic(
    code: code,
    severity: NarrativeProjectDiagnosticSeverity.error,
    domain: NarrativeProjectDiagnosticDomain.scene,
    message: message,
    path: path,
    destination: NarrativeProjectDiagnosticDestination.scene,
    suggestedFixLabel: suggestedFixLabel,
    sceneId: sceneId,
  );
}

void _appendSolvabilityDiagnostics(
  ProjectManifest project,
  List<MapData> maps,
  List<NarrativeProjectDiagnostic> target,
) {
  final reachability = _solveNarrativeReachability(project, maps);
  final reachableSceneIds = reachability.sceneIds;
  final producedFacts = reachability.trueFactIds;
  final completedSteps = reachability.completedStepIds;
  final registry = project.eventRegistry;

  final requiredFacts = <String>{};
  if (registry != null) {
    for (final record in registry.records) {
      final definition = record.definitionOrNull;
      if (definition == null || record.enabledOrNull != true) continue;
      for (final condition in definition.conditions) {
        condition.when(
          fact: (factId, expectedValue) {
            if (expectedValue) requiredFacts.add(factId);
          },
          narrativeEventConsumed: (_, __) {},
        );
      }
    }
  }
  for (final rule in project.worldRules) {
    if (rule.enabled &&
        rule.source.kind == WorldRuleSourceKind.fact &&
        rule.source.predicate == WorldRuleSourcePredicate.isTrue) {
      requiredFacts.add(rule.source.sourceId);
    }
  }
  for (final factId in requiredFacts.difference(producedFacts)) {
    target.add(
      NarrativeProjectDiagnostic(
        code: 'requiredFactNeverProduced',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.fact,
        message:
            'Le Fact « $factId » est requis par le parcours mais aucune Scene ni configuration initiale ne le produit.',
        path: 'facts.$factId',
        destination: NarrativeProjectDiagnosticDestination.fact,
        suggestedFixLabel: 'Ajouter une conséquence Définir un Fact.',
        factId: factId,
      ),
    );
  }

  for (final storyline in project.storylines) {
    if (storyline.status == StorylineStatus.disabled ||
        storyline.status == StorylineStatus.archived) {
      continue;
    }
    final steps = <({String chapterId, StorylineStep step})>[
      for (final chapter
          in (storyline.chapters.toList()
            ..sort((a, b) => a.order.compareTo(b.order))))
        for (final step
            in (chapter.steps.toList()
              ..sort((a, b) => a.order.compareTo(b.order))))
          (chapterId: chapter.id, step: step),
    ];
    var impossible = false;
    if (steps.isEmpty) {
      impossible = true;
      target.addAll([
        _storylineShapeDiagnostic(
          code: 'storylineMissingBeginning',
          message: 'La storyline ne possède aucune étape de départ.',
          storyline: storyline,
        ),
        _storylineShapeDiagnostic(
          code: 'storylineMissingEnding',
          message: 'La storyline ne possède aucune étape de fin.',
          storyline: storyline,
        ),
      ]);
    } else {
      final first = steps.first;
      if (!_stepHasReachableScene(first.step, reachableSceneIds)) {
        impossible = true;
        target.add(
          _stepDiagnostic(
            code: 'storylineMissingBeginning',
            message: 'La première étape ne possède aucune Scene déclenchable.',
            storyline: storyline,
            chapterId: first.chapterId,
            step: first.step,
          ),
        );
      }
      for (final entry in steps) {
        if (!_stepHasReachableScene(entry.step, reachableSceneIds)) {
          impossible = true;
          target.add(
            _stepDiagnostic(
              code: 'storylineStepInaccessible',
              message: 'L’étape ne possède aucune Scene liée à un Event actif.',
              storyline: storyline,
              chapterId: entry.chapterId,
              step: entry.step,
            ),
          );
        }
        if (!completedSteps.contains(entry.step.id)) {
          impossible = true;
          target.add(
            _stepDiagnostic(
              code: 'storylineStepNeverCompleted',
              message: 'Aucune conséquence narrative ne termine cette étape.',
              storyline: storyline,
              chapterId: entry.chapterId,
              step: entry.step,
            ),
          );
        }
      }
      final last = steps.last;
      if (!completedSteps.contains(last.step.id)) {
        target.add(
          _stepDiagnostic(
            code: 'storylineMissingEnding',
            message: 'La dernière étape ne peut pas être terminée.',
            storyline: storyline,
            chapterId: last.chapterId,
            step: last.step,
          ),
        );
      }
    }
    if (impossible) {
      target.add(
        _storylineShapeDiagnostic(
          code: 'storylineImpossible',
          message: storyline.type == StorylineType.sideQuest
              ? 'Cette quête ne possède pas de parcours statiquement solvable.'
              : 'Cette storyline ne possède pas de parcours statiquement solvable.',
          storyline: storyline,
        ),
      );
    }
  }
}

({
  Set<String> sceneIds,
  Set<String> trueFactIds,
  Set<String> completedStepIds,
}) _solveNarrativeReachability(
  ProjectManifest project,
  List<MapData> maps,
) {
  final mapsById = {for (final map in maps) map.id: map};
  final possibleFactValues = <String, Set<bool>>{
    for (final fact in project.facts)
      fact.id: <bool>{
        project.newGame.initialFacts[fact.id] ?? fact.defaultValue,
      },
  };
  for (final entry in project.newGame.initialFacts.entries) {
    possibleFactValues.putIfAbsent(entry.key, () => <bool>{entry.value});
  }
  final reachableSceneIds = <String>{};
  final reachableSceneOutcomeKeys = <String>{};
  final reachableEventIds = <String>{};
  final completedStepIds = <String>{};

  final registry = project.eventRegistry;
  var changed = true;
  while (changed) {
    changed = false;

    for (final map in maps) {
      for (final event in map.events) {
        final pages = _staticallyApplicableLegacyPages(
          event,
          mapId: map.id,
          possibleFactValues: possibleFactValues,
          reachableEventIds: reachableEventIds,
        );
        for (final page in pages) {
          if (page.isDisabled) continue;
          final sceneId = page.sceneTarget?.sceneId.trim();
          if (sceneId != null &&
              sceneId.isNotEmpty &&
              reachableSceneIds.add(sceneId)) {
            changed = true;
          }
        }
      }
    }

    if (registry != null) {
      for (final record in registry.records) {
        if (record.enabledOrNull != true ||
            reachableEventIds.contains(record.id)) {
          continue;
        }
        final definition = record.definitionOrNull;
        if (definition == null ||
            !_eventSourceStaticallyReachable(
              definition.source,
              mapsById: mapsById,
              reachableSceneOutcomeKeys: reachableSceneOutcomeKeys,
            ) ||
            !_eventConditionsStaticallyReachable(
              definition.conditions,
              possibleFactValues: possibleFactValues,
              reachableEventIds: reachableEventIds,
            )) {
          continue;
        }
        if (reachableEventIds.add(record.id)) changed = true;
        if (reachableSceneIds.add(definition.sceneId)) changed = true;
      }
    }

    for (final scene in project.scenes) {
      if (!reachableSceneIds.contains(scene.id)) continue;
      final reachableNodeIds = _reachableSceneNodeIds(
        scene,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
        completedStepIds: completedStepIds,
      );
      for (final node in scene.graph.nodes) {
        if (!reachableNodeIds.contains(node.id)) continue;
        final payload = node.payload;
        if (payload is SceneEndPayload && payload.sceneOutcomeId != null) {
          if (reachableSceneOutcomeKeys.add(
            _sceneOutcomeKey(scene.id, payload.sceneOutcomeId!),
          )) {
            changed = true;
          }
          continue;
        }
        if (payload is! SceneActionPayload || payload.consequence == null) {
          continue;
        }
        switch (payload.consequence!) {
          case SceneSetFactConsequence(:final factId, :final value):
            if (possibleFactValues
                .putIfAbsent(factId, () => <bool>{})
                .add(value)) {
              changed = true;
            }
          case SceneCompleteStoryStepConsequence(:final stepId):
            if (completedStepIds.add(stepId)) changed = true;
          case SceneMarkEventConsumedConsequence(:final eventId):
            if (reachableEventIds.add(eventId)) changed = true;
          case SceneGiveItemConsequence():
          case SceneTakeItemConsequence():
          case SceneGiveMoneyConsequence():
          case SceneGivePokemonConsequence():
          case SceneGiveConfiguredStarterConsequence():
            break;
        }
      }
    }

    for (final storyline in project.storylines) {
      for (final link in storyline.sceneLinks) {
        final sceneId = link.sceneRef?.targetId.trim();
        if (sceneId == null || !reachableSceneIds.contains(sceneId)) continue;
        for (final outcome in link.outcomeLinks) {
          if (!reachableSceneOutcomeKeys.contains(
            _sceneOutcomeKey(sceneId, outcome.outcomeId),
          )) {
            continue;
          }
          for (final effect in outcome.effects) {
            if (effect.type == StorylineEffectType.completeStep &&
                completedStepIds.add(effect.targetId)) {
              changed = true;
            }
            if (effect.type == StorylineEffectType.emitFact) {
              final value = effect.value?.trim().toLowerCase() != 'false';
              if (possibleFactValues
                  .putIfAbsent(effect.targetId, () => <bool>{})
                  .add(value)) {
                changed = true;
              }
            }
          }
        }
      }
    }
  }

  return (
    sceneIds: reachableSceneIds,
    trueFactIds: <String>{
      for (final entry in possibleFactValues.entries)
        if (entry.value.contains(true)) entry.key,
    },
    completedStepIds: completedStepIds,
  );
}

bool _eventSourceStaticallyReachable(
  NarrativeEventSourceRef source, {
  required Map<String, MapData> mapsById,
  required Set<String> reachableSceneOutcomeKeys,
}) {
  return source.when(
    entityInteract: (mapId, entityId) => _sourceConnected(
      NarrativeEventSourceRef.entityInteract(mapId, entityId),
      mapsById,
    ),
    triggerEnter: (mapId, triggerId) => _sourceConnected(
      NarrativeEventSourceRef.triggerEnter(mapId, triggerId),
      mapsById,
    ),
    mapEnter: (mapId) => mapsById.containsKey(mapId),
    outcomeReceived: (outcome) =>
        outcome.producerKind != NarrativeOutcomeProducerKind.scene ||
        reachableSceneOutcomeKeys.contains(
          _sceneOutcomeKey(outcome.producerId, outcome.outcomeId),
        ),
  );
}

List<MapEventPage> _staticallyApplicableLegacyPages(
  MapEventDefinition event, {
  required String mapId,
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
}) {
  // EventPageResolver observes list order. We therefore evaluate the complete
  // condition chain for each possible authored boolean state and retain the
  // first selected page for that state. Merely taking the first page that can
  // be true is insufficient: it would incorrectly hide a fallback whenever
  // the same condition can also become false. Conversely, evaluating pages in
  // isolation would invent a fallback after exhaustive `flag set` / `unset`
  // pages. Unsupported or malformed conditions fail closed for the residual
  // states instead of exposing a producer the runtime may never select.
  final variables = <String>{};
  for (final page in event.pages) {
    final condition = page.condition;
    if (condition != null) {
      _collectLegacyConditionVariables(condition, variables);
    }
  }

  final orderedVariables = variables.toList(growable: false)..sort();
  const maxAssignments = 4096;
  var assignmentCount = 1;
  for (final variable in orderedVariables) {
    final valueCount = _legacyVariableValues(
      variable,
      possibleFactValues: possibleFactValues,
      reachableEventIds: reachableEventIds,
    ).length;
    if (valueCount == 0 || assignmentCount > maxAssignments ~/ valueCount) {
      return _deterministicallyApplicableLegacyPages(
        event,
        mapId: mapId,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
      );
    }
    assignmentCount *= valueCount;
  }
  final selectedIndexes = <int>{};
  final assignment = <String, bool>{};

  void selectForAssignment() {
    for (var index = 0; index < event.pages.length; index++) {
      final condition = event.pages[index].condition;
      if (condition == null) {
        selectedIndexes.add(index);
        return;
      }
      final matches = _evaluateLegacyConditionForAssignment(
        condition,
        mapId: mapId,
        assignment: assignment,
      );
      if (matches == null) return;
      if (matches) {
        selectedIndexes.add(index);
        return;
      }
    }
  }

  void enumerateAssignments(int index) {
    if (index == orderedVariables.length) {
      selectForAssignment();
      return;
    }
    final variable = orderedVariables[index];
    final values = _legacyVariableValues(
      variable,
      possibleFactValues: possibleFactValues,
      reachableEventIds: reachableEventIds,
    );
    for (final value in values) {
      assignment[variable] = value;
      enumerateAssignments(index + 1);
    }
    assignment.remove(variable);
  }

  enumerateAssignments(0);
  return [
    for (var index = 0; index < event.pages.length; index++)
      if (selectedIndexes.contains(index)) event.pages[index],
  ];
}

Set<bool> _legacyVariableValues(
  String variable, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
}) {
  final separatorIndex = variable.indexOf('\u001f');
  if (separatorIndex < 1 || separatorIndex == variable.length - 1) {
    return const <bool>{};
  }
  final kind = variable.substring(0, separatorIndex);
  final id = variable.substring(separatorIndex + 1);
  return switch (kind) {
    'fact' => possibleFactValues[id] ?? const <bool>{false},
    'event' => reachableEventIds.contains(id)
        ? const <bool>{false, true}
        : const <bool>{false},
    _ => const <bool>{},
  };
}

List<MapEventPage> _deterministicallyApplicableLegacyPages(
  MapEventDefinition event, {
  required String mapId,
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
}) {
  final assignment = <String, bool>{};
  for (final page in event.pages) {
    final condition = page.condition;
    if (condition == null) return [page];

    final conditionVariables = <String>{};
    _collectLegacyConditionVariables(condition, conditionVariables);
    for (final variable in conditionVariables) {
      final values = _legacyVariableValues(
        variable,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
      );
      if (values.length != 1) return const <MapEventPage>[];
      assignment[variable] = values.single;
    }
    final matches = _evaluateLegacyConditionForAssignment(
      condition,
      mapId: mapId,
      assignment: assignment,
    );
    if (matches == null) return const <MapEventPage>[];
    if (matches) return [page];
  }
  return const <MapEventPage>[];
}

void _collectLegacyConditionVariables(
  ScriptCondition condition,
  Set<String> target,
) {
  switch (condition.type) {
    case ScriptConditionType.flagIsSet:
    case ScriptConditionType.flagIsUnset:
      final factId = condition.params[ScriptConditionParams.flagName]?.trim();
      if (factId != null && factId.isNotEmpty) {
        target.add('fact\u001f$factId');
      }
    case ScriptConditionType.eventIsConsumed:
      final eventId = condition.params[ScriptConditionParams.eventId]?.trim();
      if (eventId != null && eventId.isNotEmpty) {
        target.add('event\u001f$eventId');
      }
    case ScriptConditionType.allOf:
    case ScriptConditionType.anyOf:
    case ScriptConditionType.not:
    case ScriptConditionType.playerOnMap:
    case ScriptConditionType.variableEquals:
    case ScriptConditionType.variableGreaterThan:
    case ScriptConditionType.variableLessThan:
    case ScriptConditionType.fieldAbilityUnlocked:
    case ScriptConditionType.partyHasMove:
    case ScriptConditionType.partyHasUsableMove:
      break;
  }
  for (final child in condition.children) {
    _collectLegacyConditionVariables(child, target);
  }
}

bool? _evaluateLegacyConditionForAssignment(
  ScriptCondition condition, {
  required String mapId,
  required Map<String, bool> assignment,
}) {
  final children = [
    for (final child in condition.children)
      _evaluateLegacyConditionForAssignment(
        child,
        mapId: mapId,
        assignment: assignment,
      ),
  ];
  switch (condition.type) {
    case ScriptConditionType.allOf:
      if (children.any((child) => child == null)) return null;
      return children.every((child) => child!);
    case ScriptConditionType.anyOf:
      if (children.any((child) => child == null)) return null;
      return children.any((child) => child!);
    case ScriptConditionType.not:
      if (children.length != 1 || children.single == null) return null;
      return !children.single!;
    case ScriptConditionType.flagIsSet:
    case ScriptConditionType.flagIsUnset:
      final factId = condition.params[ScriptConditionParams.flagName]?.trim();
      if (factId == null || factId.isEmpty) return null;
      final expected = condition.type == ScriptConditionType.flagIsSet;
      return assignment['fact\u001f$factId'] == expected;
    case ScriptConditionType.eventIsConsumed:
      final eventId = condition.params[ScriptConditionParams.eventId]?.trim();
      if (eventId == null || eventId.isEmpty) return null;
      return assignment['event\u001f$eventId'];
    case ScriptConditionType.playerOnMap:
      final expectedMapId =
          condition.params[ScriptConditionParams.mapId]?.trim();
      if (expectedMapId == null || expectedMapId.isEmpty) return null;
      return expectedMapId == mapId;
    case ScriptConditionType.variableEquals:
    case ScriptConditionType.variableGreaterThan:
    case ScriptConditionType.variableLessThan:
    case ScriptConditionType.fieldAbilityUnlocked:
    case ScriptConditionType.partyHasMove:
    case ScriptConditionType.partyHasUsableMove:
      return null;
  }
}

String _sceneOutcomeKey(String sceneId, String outcomeId) =>
    '$sceneId\u001f$outcomeId';

bool _entityOriginIsInsideMap(MapData map, MapEntity entity) {
  return entity.pos.x >= 0 &&
      entity.pos.y >= 0 &&
      entity.pos.x < map.size.width &&
      entity.pos.y < map.size.height;
}

bool _eventConditionsStaticallyReachable(
  List<NarrativeEventCondition> conditions, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
}) {
  return conditions.every(
    (condition) => condition.when(
      fact: (factId, expectedValue) =>
          possibleFactValues[factId]?.contains(expectedValue) == true,
      narrativeEventConsumed: (eventId, expectedValue) =>
          expectedValue ? reachableEventIds.contains(eventId) : true,
    ),
  );
}

List<NarrativeMapEventsView> _buildMapEventViews(
  ProjectManifest project, {
  required Map<String, MapData> mapsById,
  required List<NarrativeProjectDiagnostic> diagnostics,
}) {
  final mapLabels = {for (final entry in project.maps) entry.id: entry.name};
  final groups = <String?, List<NarrativeMapEventEntry>>{};
  final registry = project.eventRegistry;
  if (registry != null) {
    for (final record in registry.records) {
      final source = _recordSource(record);
      final identity = _sourceIdentity(source);
      final presentation = _sourceOwnerPresentation(source, mapsById);
      final mapId = identity.mapId;
      final groupKey = source == null
          ? '__unassigned__'
          : source.kind == NarrativeEventSourceKind.outcomeReceived
              ? '__outcomes__'
              : mapId;
      final sceneId = _recordSceneId(record);
      groups.putIfAbsent(groupKey, () => <NarrativeMapEventEntry>[]).add(
            NarrativeMapEventEntry(
              eventId: record.id,
              label: _recordLabel(record),
              enabled: record.enabledOrNull,
              sourceKind: source?.kind,
              mapId: mapId,
              sourceOwnerId: identity.ownerId,
              sourceOwnerLabel: presentation.label,
              sourceEntityKind: presentation.entityKind,
              sourceConnected: _sourceConnected(source, mapsById),
              sceneId: sceneId,
              sceneLabel: _sceneLabel(project, sceneId),
              sceneConnected: sceneId != null &&
                  project.scenes.any((scene) => scene.id == sceneId),
              conditionCount: _recordConditions(record).length,
              diagnosticCount: diagnostics
                  .where((diagnostic) =>
                      diagnostic.eventId == record.id &&
                      diagnostic.severity ==
                          NarrativeProjectDiagnosticSeverity.error)
                  .length,
              warningCount: diagnostics
                  .where((diagnostic) =>
                      diagnostic.eventId == record.id &&
                      diagnostic.severity ==
                          NarrativeProjectDiagnosticSeverity.warning)
                  .length,
            ),
          );
    }
  }

  final views = <NarrativeMapEventsView>[
    for (final entry in project.maps)
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.map,
        mapId: entry.id,
        label: entry.name,
        events: groups.remove(entry.id) ?? const [],
      ),
  ];
  for (final entry in groups.entries.where(
    (entry) => entry.key != '__outcomes__' && entry.key != '__unassigned__',
  )) {
    views.add(
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.map,
        mapId: entry.key,
        label: mapLabels[entry.key] ?? entry.key ?? 'Map inconnue',
        events: entry.value,
      ),
    );
  }
  final outcomes = groups['__outcomes__'];
  if (outcomes != null && outcomes.isNotEmpty) {
    views.add(
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.outcomes,
        mapId: null,
        label: 'Résultats narratifs',
        events: outcomes,
      ),
    );
  }
  final unassigned = groups['__unassigned__'];
  if (unassigned != null && unassigned.isNotEmpty) {
    views.add(
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.unassigned,
        mapId: null,
        label: 'Sources à configurer',
        events: unassigned,
      ),
    );
  }
  return views;
}

NarrativeProjectDiagnostic _storylineShapeDiagnostic({
  required String code,
  required String message,
  required StorylineAsset storyline,
}) =>
    NarrativeProjectDiagnostic(
      code: code,
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: NarrativeProjectDiagnosticDomain.storyline,
      message: message,
      path: 'storylines.${storyline.id}',
      destination: NarrativeProjectDiagnosticDestination.storyline,
      storylineId: storyline.id,
    );

NarrativeProjectDiagnostic _stepDiagnostic({
  required String code,
  required String message,
  required StorylineAsset storyline,
  required String chapterId,
  required StorylineStep step,
}) =>
    NarrativeProjectDiagnostic(
      code: code,
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: NarrativeProjectDiagnosticDomain.storyline,
      message: message,
      path: 'storylines.${storyline.id}.$chapterId.${step.id}',
      destination: NarrativeProjectDiagnosticDestination.storyline,
      storylineId: storyline.id,
      chapterId: chapterId,
      stepId: step.id,
    );

bool _stepHasReachableScene(StorylineStep step, Set<String> enabledSceneIds) =>
    step.sceneLinkIds.any(enabledSceneIds.contains);

Set<String> _reachableSceneNodeIds(
  SceneAsset scene, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
  required Set<String> completedStepIds,
}) {
  final nodesById = {for (final node in scene.graph.nodes) node.id: node};
  final outgoing = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    if (!nodesById.containsKey(edge.fromNodeId) ||
        !nodesById.containsKey(edge.toNodeId)) {
      continue;
    }
    outgoing.putIfAbsent(edge.fromNodeId, () => <SceneEdge>[]).add(edge);
  }
  final reachable = <String>{};
  final pending = <String>[scene.graph.startNodeId];
  while (pending.isNotEmpty) {
    final nodeId = pending.removeLast();
    final node = nodesById[nodeId];
    if (node == null || !reachable.add(nodeId)) continue;
    for (final edge in outgoing[nodeId] ?? const <SceneEdge>[]) {
      if (_sceneEdgeIsStaticallyTraversable(
        node,
        edge,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
        completedStepIds: completedStepIds,
      )) {
        pending.add(edge.toNodeId);
      }
    }
  }
  return reachable;
}

bool _sceneEdgeIsStaticallyTraversable(
  SceneNode node,
  SceneEdge edge, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
  required Set<String> completedStepIds,
}) {
  switch (node.kind) {
    case SceneNodeKind.start:
    case SceneNodeKind.merge:
      return edge.fromPortId == 'completed' &&
          edge.kind == SceneEdgeKind.defaultFlow;
    case SceneNodeKind.end:
    case SceneNodeKind.branchByOutcome:
      return false;
    case SceneNodeKind.action:
      return edge.fromPortId == 'completed' &&
          (edge.kind == SceneEdgeKind.defaultFlow ||
              edge.kind == SceneEdgeKind.actionCompleted);
    case SceneNodeKind.cinematic:
      return edge.fromPortId == 'completed' &&
          edge.kind == SceneEdgeKind.cinematicCompleted;
    case SceneNodeKind.battle:
      return edge.fromPortId == 'victory' &&
              edge.kind == SceneEdgeKind.battleVictory ||
          edge.fromPortId == 'defeat' &&
              edge.kind == SceneEdgeKind.battleDefeat;
    case SceneNodeKind.yarnDialogue:
      final payload = node.payload as SceneYarnDialoguePayload;
      if (edge.fromPortId == 'completed') {
        return edge.kind == SceneEdgeKind.defaultFlow;
      }
      return payload.expectedOutcomes.contains(edge.fromPortId) &&
          edge.kind == SceneEdgeKind.dialogueOutcome;
    case SceneNodeKind.condition:
      final possibility = _sceneConditionPossibility(
        (node.payload as SceneConditionPayload).conditionSource,
        possibleFactValues: possibleFactValues,
        reachableEventIds: reachableEventIds,
        completedStepIds: completedStepIds,
      );
      return edge.fromPortId == 'true' &&
              edge.kind == SceneEdgeKind.conditionTrue &&
              possibility.canBeTrue ||
          edge.fromPortId == 'false' &&
              edge.kind == SceneEdgeKind.conditionFalse &&
              possibility.canBeFalse;
  }
}

({bool canBeTrue, bool canBeFalse}) _sceneConditionPossibility(
  SceneConditionSource? source, {
  required Map<String, Set<bool>> possibleFactValues,
  required Set<String> reachableEventIds,
  required Set<String> completedStepIds,
}) {
  if (source == null) return (canBeTrue: true, canBeFalse: true);

  Set<bool>? values;
  switch (source.sourceKind) {
    case SceneConditionSourceKind.fact:
    case SceneConditionSourceKind.factLikeStoryFlag:
      values = possibleFactValues[source.sourceId];
    case SceneConditionSourceKind.storyStepCompletion:
      values = completedStepIds.contains(source.sourceId)
          ? const <bool>{false, true}
          : const <bool>{false};
    case SceneConditionSourceKind.consumedEvent:
      values = reachableEventIds.contains(source.sourceId)
          ? const <bool>{false, true}
          : const <bool>{false};
    case SceneConditionSourceKind.storyStepActive:
    case SceneConditionSourceKind.inventoryItem:
    case SceneConditionSourceKind.partyState:
    case SceneConditionSourceKind.trainerDefeated:
    case SceneConditionSourceKind.dialogueOutcome:
    case SceneConditionSourceKind.battleOutcome:
    case SceneConditionSourceKind.scriptVariable:
    case SceneConditionSourceKind.worldState:
      return (canBeTrue: true, canBeFalse: true);
  }
  if (values == null || values.isEmpty) {
    return (canBeTrue: true, canBeFalse: true);
  }

  bool? matches(bool value) {
    return switch (source.operator) {
      SceneConditionOperator.isTrue => value,
      SceneConditionOperator.isFalse => !value,
      SceneConditionOperator.equals => switch (source.value) {
          'true' || SceneConditionValues.completed => value,
          'false' || SceneConditionValues.notCompleted => !value,
          _ => null,
        },
    };
  }

  final results = {for (final value in values) matches(value)};
  if (results.contains(null)) {
    return (canBeTrue: true, canBeFalse: true);
  }
  return (
    canBeTrue: results.contains(true),
    canBeFalse: results.contains(false),
  );
}

String? _sceneNodeDialogueId(SceneAsset scene, String? nodeId) {
  if (nodeId == null) return null;
  for (final node in scene.graph.nodes) {
    if (node.id == nodeId && node.payload is SceneYarnDialoguePayload) {
      return (node.payload as SceneYarnDialoguePayload).dialogueId;
    }
  }
  return null;
}

String? _legacyDialogueId(NarrativeValidationDiagnostic diagnostic) {
  return switch (diagnostic.kind) {
    NarrativeValidationDiagnosticKind.openDialogueReferencesUnknownDialogue ||
    NarrativeValidationDiagnosticKind
          .conditionalDialogueReferencesUnknownDialogue =>
      diagnostic.referencedId,
    _ => null,
  };
}

NarrativeProjectDiagnosticDomain _legacyDomain(
  NarrativeValidationDiagnosticKind kind,
) =>
    switch (kind) {
      NarrativeValidationDiagnosticKind.openDialogueReferencesUnknownDialogue ||
      NarrativeValidationDiagnosticKind
            .conditionalDialogueReferencesUnknownDialogue =>
        NarrativeProjectDiagnosticDomain.dialogue,
      NarrativeValidationDiagnosticKind.flagReadNeverProduced ||
      NarrativeValidationDiagnosticKind.setFlagNeverRead =>
        NarrativeProjectDiagnosticDomain.fact,
      NarrativeValidationDiagnosticKind
          .visibilityRuleConditionalMissingPredicate ||
      NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId =>
        NarrativeProjectDiagnosticDomain.worldRule,
      _ => NarrativeProjectDiagnosticDomain.storyline,
    };

NarrativeProjectDiagnosticDestination _legacyDestination(
  NarrativeValidationDiagnostic diagnostic,
) {
  if (diagnostic.mapId != null) {
    return NarrativeProjectDiagnosticDestination.map;
  }
  if (_legacyDialogueId(diagnostic) != null) {
    return NarrativeProjectDiagnosticDestination.dialogue;
  }
  if (_legacyDomain(diagnostic.kind) == NarrativeProjectDiagnosticDomain.fact) {
    return NarrativeProjectDiagnosticDestination.fact;
  }
  return NarrativeProjectDiagnosticDestination.storyline;
}

NarrativeProjectDiagnosticSeverity _legacySeverity(
  NarrativeValidationSeverity severity,
) =>
    switch (severity) {
      NarrativeValidationSeverity.error =>
        NarrativeProjectDiagnosticSeverity.error,
      NarrativeValidationSeverity.warning =>
        NarrativeProjectDiagnosticSeverity.warning,
    };

NarrativeProjectDiagnosticSeverity _legacySeverityForProject(
  ProjectManifest project,
  NarrativeValidationDiagnostic diagnostic,
) {
  if (diagnostic.kind ==
          NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource &&
      project.storylines.isNotEmpty) {
    ScenarioAsset? scenario;
    for (final candidate in project.scenarios) {
      if (candidate.id == diagnostic.scenarioId) {
        scenario = candidate;
        break;
      }
    }
    if (scenario?.scope == ScenarioScope.globalStory &&
        scenario!.metadata.containsKey('authoring.globalStoryStudioSchema')) {
      return NarrativeProjectDiagnosticSeverity.warning;
    }
  }
  return _legacySeverity(diagnostic.severity);
}

NarrativeProjectDiagnosticDestination _eventDestination(
  NarrativeEventValidationDestinationKind kind,
  String? mapId,
) =>
    switch (kind) {
      NarrativeEventValidationDestinationKind.mapSource =>
        NarrativeProjectDiagnosticDestination.map,
      NarrativeEventValidationDestinationKind.eventSource when mapId != null =>
        NarrativeProjectDiagnosticDestination.map,
      NarrativeEventValidationDestinationKind.scene =>
        NarrativeProjectDiagnosticDestination.scene,
      _ => NarrativeProjectDiagnosticDestination.event,
    };

String? _eventMapId(ProjectManifest project, String? eventId) {
  if (eventId == null) return null;
  final registry = project.eventRegistry;
  if (registry == null) return null;
  for (final record in registry.records) {
    if (record.id == eventId) {
      return _sourceIdentity(_recordSource(record)).mapId;
    }
  }
  return null;
}

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) =>
    record.when(
      draft: (draft) => draft.source,
      configured: (definition, _) => definition.source,
    );

String? _recordSceneId(NarrativeEventRecord record) => record.when(
      draft: (draft) => draft.sceneId,
      configured: (definition, _) => definition.sceneId,
    );

String? _sceneLabel(ProjectManifest project, String? sceneId) {
  if (sceneId == null) return null;
  for (final scene in project.scenes) {
    if (scene.id == sceneId) return scene.name;
  }
  return null;
}

String _recordLabel(NarrativeEventRecord record) => record.when(
      draft: (draft) => draft.name,
      configured: (definition, _) => definition.name,
    );

List<NarrativeEventCondition> _recordConditions(NarrativeEventRecord record) =>
    record.when(
      draft: (draft) => draft.conditions,
      configured: (definition, _) => definition.conditions,
    );

({String? mapId, String? ownerId}) _sourceIdentity(
  NarrativeEventSourceRef? source,
) =>
    source?.when(
      entityInteract: (mapId, entityId) => (mapId: mapId, ownerId: entityId),
      triggerEnter: (mapId, triggerId) => (mapId: mapId, ownerId: triggerId),
      mapEnter: (mapId) => (mapId: mapId, ownerId: null),
      outcomeReceived: (_) => (mapId: null, ownerId: null),
    ) ??
    (mapId: null, ownerId: null);

bool _sourceConnected(
  NarrativeEventSourceRef? source,
  Map<String, MapData> mapsById,
) {
  if (source == null) return false;
  return source.when(
    entityInteract: (mapId, entityId) =>
        mapsById[mapId]?.entities.any((entity) => entity.id == entityId) ??
        false,
    triggerEnter: (mapId, triggerId) =>
        mapsById[mapId]?.triggers.any((trigger) => trigger.id == triggerId) ??
        false,
    mapEnter: mapsById.containsKey,
    outcomeReceived: (_) => true,
  );
}

({String? label, MapEntityKind? entityKind}) _sourceOwnerPresentation(
  NarrativeEventSourceRef? source,
  Map<String, MapData> mapsById,
) {
  if (source == null) return (label: null, entityKind: null);
  return source.when(
    entityInteract: (mapId, entityId) {
      MapEntity? entity;
      for (final candidate
          in mapsById[mapId]?.entities ?? const <MapEntity>[]) {
        if (candidate.id == entityId) {
          entity = candidate;
          break;
        }
      }
      return (
        label: entity?.inspectorHeadline,
        entityKind: entity?.kind,
      );
    },
    triggerEnter: (mapId, triggerId) {
      MapTrigger? trigger;
      for (final candidate
          in mapsById[mapId]?.triggers ?? const <MapTrigger>[]) {
        if (candidate.id == triggerId) {
          trigger = candidate;
          break;
        }
      }
      final name = trigger?.name.trim();
      return (
        label: name == null || name.isEmpty ? trigger?.id : name,
        entityKind: null,
      );
    },
    mapEnter: (mapId) => (
      label: mapsById[mapId]?.name,
      entityKind: null,
    ),
    outcomeReceived: (outcome) => (
      label: outcome.outcomeId,
      entityKind: null,
    ),
  );
}

int _compareDiagnostics(
  NarrativeProjectDiagnostic left,
  NarrativeProjectDiagnostic right,
) {
  final severity = right.severity.index.compareTo(left.severity.index);
  if (severity != 0) return severity;
  return left.stableKey.compareTo(right.stableKey);
}

String _upperFirst(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
