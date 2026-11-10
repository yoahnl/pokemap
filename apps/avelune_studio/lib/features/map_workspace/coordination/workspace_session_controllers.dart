import '../../presentations/coordination/presentation_editing_sessions.dart';
import '../../presentations/coordination/presentation_visual_session.dart';
import 'package:map_core/map_core_domain.dart';

import '../../pokemon/application/pokemon_workspace_controller.dart';
import '../../pokemon/application/pokemon_commerce_controller.dart';
import '../../pokemon/application/pokemon_combat_controller.dart';
import '../../pokemon/domain/pokemon_workspace_port.dart';
import '../../pokemon/domain/pokemon_workspace_models.dart';
import '../../pokemon/domain/pokemon_commerce_port.dart';
import '../../pokemon/domain/pokemon_combat_port.dart';
import '../../regional_map/application/regional_map_controller.dart';
import '../../regional_map/domain/regional_map_port.dart';
import '../../scenes/application/scene_workspace_controller.dart';
import '../../scenes/application/scene_dialogue_results.dart';
import '../../scenes/domain/scene_port.dart';
import '../../stories/application/story_workspace_controller.dart';
import '../../stories/domain/story_port.dart';
import '../../events/application/event_workspace_controller.dart';
import '../../events/application/event_editing_session.dart';
import '../../events/domain/event_port.dart';
import '../../dialogues/application/dialogue_workspace_controller.dart';
import '../../dialogues/domain/dialogue_port.dart';
import '../../cinematics/application/cinematic_workspace_controller.dart';
import '../../cinematics/domain/cinematic_port.dart';
import '../../presentations/application/presentation_workspace_controller.dart';
import '../../world/application/world_workspace_controller.dart';
import '../../verification/application/verification_workspace_controller.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../../project_surf/application/project_surf_controller.dart';
import '../../project_surf/domain/project_surf_port.dart';
import '../../project_cs/application/project_cs_controller.dart';
import '../../project_cs/domain/project_cs_port.dart';
import '../../project_audio/application/project_audio_controller.dart';
import '../../project_audio/domain/project_audio_port.dart';
import '../../project_settings/application/project_identity_controller.dart';
import '../../project_visuals/application/project_visuals_controller.dart';
import '../../project_visuals/domain/project_visuals_port.dart';
import '../../game_export/domain/studio_game_export_port.dart';
import '../../../platform/rendering/contracts/presentation_workspace_visuals.dart';
import '../application/map_workspace_controller.dart';
import '../application/map_draft_reference_guard.dart';
import '../domain/map_workspace_port.dart';
import 'workspace_session_loader.dart';

part 'workspace_session_initialization.dart';

class WorkspaceSessionControllers {
  WorkspaceSessionControllers({
    required this.controller,
    required this.changed,
    required this.visualCatalogChanged,
    required this.flushEditors,
    this.pokemonPort,
    this.pokemonCommercePort,
    this.pokemonCombatPort,
    this.regionalMapPort,
    this.scenePort,
    this.storyPort,
    this.eventPort,
    this.dialoguePort,
    this.cinematicPort,
    this.presentationPort,
    this.worldPort,
    this.verificationPort,
    this.audioPreview,
    this.gameExport,
    this.isActive,
  });

  final MapWorkspaceController controller;
  final void Function() changed;
  final void Function(ProjectManifest?) visualCatalogChanged;
  final Future<bool> Function() flushEditors;
  final PokemonWorkspacePort? pokemonPort;
  final PokemonCommercePort? pokemonCommercePort;
  final PokemonCombatPort? pokemonCombatPort;
  final RegionalMapPort? regionalMapPort;
  final ScenePort? scenePort;
  final StoryPort? storyPort;
  final EventPort? eventPort;
  final DialoguePort? dialoguePort;
  final CinematicPort? cinematicPort;
  final PresentationPort? presentationPort;
  final WorldPort? worldPort;
  final VerificationPort? verificationPort;
  final ProjectAudioPreviewPort? audioPreview;
  final StudioGameExportPort? gameExport;
  final bool Function()? isActive;
  PokemonWorkspaceController? pokemon;
  NarrativeWorkspaceController? narrative;
  RegionalMapController? regionalMap;
  SceneWorkspaceController? scenes;
  StoryWorkspaceController? stories;
  EventWorkspaceController? events;
  EventEditingSession? eventEditing;
  DialogueWorkspaceController? dialogues;
  PresentationWorkspaceController? presentations;
  CinematicWorkspaceController? cinematics;
  WorldWorkspaceController? world;
  VerificationWorkspaceController? verification;
  ProjectSurfController? projectSurf;
  ProjectCsController? projectCs;
  ProjectAudioController? projectAudio;
  ProjectIdentityController? projectIdentity;
  ProjectVisualsController? projectVisuals;
  final presentationPreview = PresentationVisualSession();
  PresentationWorkspaceVisuals? synchronizePresentationVisuals(
    PresentationMediaWorkspaceVisuals factory,
  ) {
    final owner = presentations;
    if (_disposal != null || owner == null) return null;
    return presentationPreview.synchronize(
      factory: factory,
      activeId: owner.activeId,
      session: owner.active,
    );
  }
  final presentationEditing = PresentationEditingSessions();
  LoadedWorkspaceSession? loadedSession;

  PokemonWorkspaceController _scenePokemonOwner() {
    final owner = pokemon ?? (throw StateError('Catalogue indisponible.'));
    _checkScenePokemonOwner(owner);
    return owner;
  }

  void _checkScenePokemonOwner(PokemonWorkspaceController owner) {
    if (_disposal != null ||
        !(isActive?.call() ?? !controller.isDisposed) ||
        !identical(owner, pokemon)) {
      throw StateError('Le projet a changé.');
    }
  }

  Future<List<PokemonSpeciesSummary>> loadSceneSpecies() async {
    final owner = _scenePokemonOwner();
    final index = await owner.port.loadIndex();
    _checkScenePokemonOwner(owner);
    if (!index.enabled) throw StateError('Catalogue Pokémon désactivé.');
    return index.entries;
  }

  Future<Map<String, String>> loadSceneMoves() async {
    final owner = _scenePokemonOwner();
    await owner.load(refresh: true);
    _checkScenePokemonOwner(owner);
    final moves = owner.index?.moves;
    if (owner.error != null ||
        moves == null ||
        !moves.available ||
        moves.diagnostics.isNotEmpty) {
      throw StateError('Le catalogue des capacités est indisponible ou ambigu.');
    }
    return {for (final move in moves.entries) move.id: move.name};
  }

  Future<Map<String, String>> loadSceneCaptureItems() =>
      loadSceneItems(captureOnly: true);

  Future<Map<String, String>> loadSceneItems({bool captureOnly = false}) async {
    final owner = _scenePokemonOwner();
    final index = await owner.port.loadIndex();
    _checkScenePokemonOwner(owner);
    if (!index.enabled) throw StateError('Catalogue Pokémon désactivé.');
    final catalog = index.itemCatalog;
    final itemIds = <String>{};
    if (catalog == null ||
        catalog.entries.any(
          (item) =>
              item.id.isEmpty ||
              item.id.trim() != item.id ||
              item.displayName.trim().isEmpty ||
              !itemIds.add(item.id),
        )) {
      throw StateError('Le catalogue des objets est indisponible ou ambigu.');
    }
    return {
      for (final item in catalog.entries)
        if (!captureOnly || item.capture != null) item.id: item.displayName,
    };
  }

  List<String> get resourceUsageDraftOwners => [
    if (narrative?.dirty == true) 'Narration',
    if (scenes?.dirty == true) 'Scènes',
    if (events?.dirty == true) 'Événements',
    if (dialogues?.dirty == true) 'Dialogues',
    if (cinematics?.dirty == true) 'Cinématiques',
    if (presentations?.dirty == true) 'Présentations',
    if (regionalMap?.dirty == true) 'Carte régionale',
    if (pokemon?.hasPendingChanges == true) 'Pokémon',
  ];
  ProjectSurfController? get surfOwner {
    final source = controller.port;
    if (source is! ProjectSurfPort) return null;
    return projectSurf ??= ProjectSurfController(
      session: controller.session,
      port: source as ProjectSurfPort,
      dimension: controller.project!.settings.dimension,
      onSaved: _acceptSurfConfiguration,
      onRevisionChanged: _adoptSettingsRevision,
    );
  }

  void _acceptSurfConfiguration(ProjectSurfSettings? configuration) {
    controller.acceptSurfConfiguration(configuration, notifyChange: false);
    visualCatalogChanged(controller.visualProject);
    controller.notify();
  }

  ProjectCsController? get csOwner {
    final source = controller.port;
    if (source is! ProjectCsPort) return null;
    return projectCs ??= ProjectCsController(
      session: controller.session,
      port: source as ProjectCsPort,
      onRevisionChanged: _adoptSettingsRevision,
      onSaved: (configuration) {
        controller.acceptFieldAbilities(configuration, notifyChange: false);
        _acceptSettingsVisuals();
      },
    );
  }

  ProjectAudioController? get audioOwner {
    final source = controller.port;
    if (source is! ProjectAudioPort) return null;
    return projectAudio ??= ProjectAudioController(
      session: controller.session,
      port: source as ProjectAudioPort,
      audition: audioPreview,
      onRevisionChanged: _adoptSettingsRevision,
      onSaved: (configuration) {
        controller.acceptAudio(configuration, notifyChange: false);
        _acceptSettingsVisuals();
      },
    );
  }

  ProjectIdentityController? get identityOwner {
    final export = gameExport;
    if (export == null) return null;
    return projectIdentity ??= ProjectIdentityController(port: export);
  }

  void _adoptSettingsRevision(String before, String after) {
    projectSurf?.adoptRevision(before, after);
    projectCs?.adoptRevision(before, after);
    projectAudio?.adoptRevision(before, after);
  }

  void _acceptSettingsVisuals() {
    visualCatalogChanged(controller.visualProject);
    controller.notify();
  }

  ProjectVisualsController get visualOwner {
    final owner = projectVisuals ??= ProjectVisualsController(
      session: controller.session,
      port: controller.port as ProjectVisualsPort,
    );
    controller.settingsVisualsOwner = owner;
    return owner;
  }

  late final draftReferences = MapDraftReferenceIndex(draftReferenceSources);

  Future<void>? _disposal;
  Future<void> dispose({
    void Function()? releaseWorldViews,
    void Function()? releaseVerificationViews,
    void Function()? releasePresentationViews,
  }) => _disposal ??= _dispose(
    releaseWorldViews: releaseWorldViews,
    releaseVerificationViews: releaseVerificationViews,
    releasePresentationViews: releasePresentationViews,
  );

  Future<void> _dispose({
    void Function()? releaseWorldViews,
    void Function()? releaseVerificationViews,
    void Function()? releasePresentationViews,
  }) async {
    final released = <Future<void>>[
      if (loadedSession != null) loadedSession!.dispose(),
    ];
    pokemon?.dispose();
    scenes?.dispose();
    stories?.dispose();
    events?.dispose();
    dialogues?.dispose();
    presentations?.dispose();
    regionalMap?.dispose();
    world?.dispose();
    if (identical(controller.settingsVisualsOwner, projectVisuals)) {
      controller.settingsVisualsOwner = null;
    }
    projectVisuals?.dispose();
    projectSurf?.dispose();
    projectCs?.dispose();
    projectAudio?.dispose();
    projectIdentity?.dispose();
    releaseWorldViews?.call();
    verification?.dispose();
    releaseVerificationViews?.call();
    releasePresentationViews?.call();
    presentationEditing.dispose();
    released.add(presentationPreview.close());
    cinematics?.dispose();
    await Future.wait(released);
  }

  MapDraftReferenceSources draftReferenceSources() {
    final world = this.world;
    final events = this.events;
    final narrative = this.narrative;
    return MapDraftReferenceSources(
      eventDrafts: [
        if (events != null)
          for (final id in events.dirtyIds) ?events.record(id),
      ],
      ruleTargets: [
        if (world != null)
          for (final draft in world.pendingRules.values)
            if (draft.target?.entityId case final entityId?)
              (
                mapId: draft.target!.mapId,
                kind: MapDraftReferenceKind.entity,
                id: entityId,
              ),
      ],
      interactionDrafts: [
        if (narrative != null)
          for (final session in narrative.sessions.values)
            if (session.dirty)
              if (session.current.interaction.source.toJson() case final source)
                if (source['mapId'] case final String mapId) ...[
                  if (source['entityId'] case final String entityId)
                    (
                      mapId: mapId,
                      kind: MapDraftReferenceKind.entity,
                      id: entityId,
                    ),
                  if (source['triggerId'] case final String triggerId)
                    (
                      mapId: mapId,
                      kind: MapDraftReferenceKind.trigger,
                      id: triggerId,
                    ),
                ],
      ],
    );
  }
}
