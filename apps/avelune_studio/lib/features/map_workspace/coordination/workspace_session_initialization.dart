part of 'workspace_session_controllers.dart';

extension WorkspaceSessionInitialization on WorkspaceSessionControllers {
  void initializePokemon() {
    if (pokemon != null) return;
    final port = pokemonPort;
    if (port != null) {
      pokemon = PokemonWorkspaceController(
        port,
        changed: changed,
        commerce: pokemonCommercePort == null
            ? null
            : PokemonCommerceController(pokemonCommercePort!, changed: changed),
        combat: pokemonCombatPort == null
            ? null
            : PokemonCombatController(
                pokemonCombatPort!,
                changed: changed,
                projectChanged: (manifest) {
                  final current = controller.project;
                  if (current != null && current != manifest) {
                    controller.acceptResources(
                      current,
                      mergeProjectMetadataSections(current, manifest, const {
                        'pokemon',
                        'trainers',
                        'encounterTables',
                      }),
                    );
                  }
                },
              ),
      );
    }
  }

  void initializeLoaded(LoadedWorkspaceSession loaded) {
    loadedSession = loaded;
    narrative = loaded.narrative;
    _initializeScenes();
    _initializeStories();
    _initializeEvents();
    _initializeDialogues();
    _initializeCinematics();
    _initializePresentations();
    if (regionalMapPort case final port?) {
      regionalMap = RegionalMapController(
        port,
        changed: changed,
        mapDraftProblem: (ids) =>
            controller.documents.values.any(
              (document) => document.dirty && ids.contains(document.current.id),
            )
            ? 'Enregistrez les cartes liées avant de publier la carte régionale.'
            : null,
        projectChanged: (before, after) {
          final current = controller.project;
          if (current == null || current.regionalMap != before.regionalMap) {
            throw const MapWorkspaceFailure(
              MapWorkspaceProblem.conflict,
              'La carte régionale a changé pendant la publication.',
            );
          }
          controller.acceptResources(
            current,
            mergeProjectMetadataSections(current, after, const {'regionalMap'}),
          );
        },
      );
    }
    _initializeWorld();
    _initializeVerification();
  }

  void _initializeScenes() {
    if (scenePort case final port?) {
      scenes = SceneWorkspaceController(
        controller,
        port,
        narrative: narrative,
        changed: changed,
      );
    }
  }

  void _initializeStories() {
    final narrative = this.narrative;
    final port = storyPort;
    if (narrative == null || port == null) return;
    stories = StoryWorkspaceController(
      narrative,
      port,
      changed: changed,
      sceneDrafts: () => scenes?.scenes ?? narrative.project.scenes,
    );
  }

  void _initializeEvents() {
    if (narrative case final narrative?) {
      if (eventPort case final port?) {
        events = EventWorkspaceController(
          narrative,
          port,
          changed: changed,
          sceneDrafts: () => scenes?.scenes ?? narrative.project.scenes,
        );
        eventEditing = EventEditingSession(events!, changed: changed);
      }
    }
  }

  void _initializeDialogues() {
    final narrative = this.narrative, port = dialoguePort;
    if (narrative == null || port == null) return;
    dialogues = DialogueWorkspaceController(
      narrative,
      port,
      changed: changed,
      sceneDrafts: () =>
          scenes?.sessions.values.map((s) => s.current).toList() ?? [],
    );
    dialogues!.onPublished = (id, revision) =>
        scenes?.refreshDialogueResults(id);
  }

  void _initializeCinematics() {
    final narrative = this.narrative, port = cinematicPort;
    if (narrative == null || port == null) return;
    cinematics = CinematicWorkspaceController(
      narrative,
      port,
      changed: changed,
      sceneDrafts: () =>
          scenes?.sessions.values.map((s) => s.current).toList() ?? [],
    );
  }

  void _initializePresentations() {
    final narrative = this.narrative, port = presentationPort;
    if (narrative == null || port == null) return;
    presentations = PresentationWorkspaceController(
      narrative,
      port,
      changed: changed,
      sceneDrafts: () =>
          scenes?.sessions.values.map((s) => s.current).toList() ?? [],
    );
    presentations!.onScenePublished = (link, published) {
      final session = scenes?.sessions[link.scene.id];
      if (session == null) return;
      if (session.current == link.scene) session.commit(published);
      session.acceptSave(published, 'presentation-publication');
      changed();
    };
  }

  void _initializeWorld() {
    final narrative = this.narrative, port = worldPort;
    if (narrative == null || port == null) return;
    world = WorldWorkspaceController(narrative, port, changed: changed);
  }

  void _initializeVerification() {
    final narrative = this.narrative, port = verificationPort;
    if (narrative == null || port == null) return;
    verification = VerificationWorkspaceController(
      narrative,
      port,
      changed: changed,
      world: () => world,
      scenes: () => scenes,
      dialogues: () => dialogues,
      events: () => events,
      cinematics: () => cinematics,
      presentations: () => presentations,
    )..flushEdits = flushEditors;
  }
}
