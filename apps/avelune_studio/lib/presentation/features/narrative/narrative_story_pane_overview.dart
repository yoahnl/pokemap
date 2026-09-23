part of 'narrative_story_pane.dart';

extension _NarrativeStoryPaneOverview on _NarrativeStoryPaneState {
  Widget _buildOverview(NarrativeOverview overview) {
    return Column(
      children: [
        if (state.notice case final notice?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: StudioNotice(notice, isError: true),
          ),
        Expanded(
          child: NarrativeOverviewLanding(
            artworkPort: widget.controller.port is NarrativeArtworkPort
                ? widget.controller.port as NarrativeArtworkPort
                : null,
            overview: overview,
            project: widget.controller.project,
            scenes:
                widget.sceneOwner?.scenes ?? widget.controller.project.scenes,
            dialogues:
                widget.dialogueOwner?.entries ??
                widget.controller.project.dialogues,
            events:
                widget.eventOwner?.records ??
                widget.controller.project.eventRegistry?.records ??
                const [],
            verification: widget.verification,
            search: state.search,
            onSearch: (_) {
              if (state.resultsScroll.hasClients) state.resultsScroll.jumpTo(0);
              refresh();
            },
            resultsScroll: state.resultsScroll,
            onLibrary: () {
              state.showOverview = false;
              refresh();
            },
            onCreateStory: widget.storyOwner == null ? null : _createStory,
            onCreateScene:
                widget.sceneOwner == null || widget.onOpenScene == null
                ? null
                : _createScene,
            onCreateEvent:
                widget.eventOwner == null || widget.onOpenEvent == null
                ? null
                : _createEvent,
            onProgression: widget.onProgression,
            onScenes: widget.onScenes,
            onEvents: widget.onEvents,
            onVerification: widget.onVerification,
            onOpenStory: (id) {
              state.storyId = id;
              if (widget.onProgression case final open?) {
                open();
              } else {
                state.showOverview = false;
                refresh();
              }
            },
            onOpenStep: (storyId, stepId) {
              state.storyId = storyId;
              if (widget.onOpenStep case final open?) {
                open(storyId, stepId);
              } else {
                state.tab = NarrativeOverviewTab.stories;
                state.select(step: stepId);
                state.showOverview = false;
                refresh();
              }
            },
            onOpenScene: widget.onOpenScene == null
                ? null
                : (id) => _navigateDocument(widget.onOpenScene!, id),
            onOpenInteraction: (id) => _navigate(widget.onOpen, id),
            onOpenDialogue: widget.onOpenDialogue,
            onOpenEvent: widget.onOpenEvent,
            onOpenMap: widget.onOpenMap,
            activeStoryId: widget.storyOwner?.activeId,
            activeSceneId: widget.sceneOwner?.active?.current.id,
            activeDialogueId: widget.dialogueOwner?.activeId,
            activeEventId: widget.eventOwner?.activeId,
            dirtyStoryIds: widget.controller.pendingStories.keys.toSet(),
            dirtySceneIds:
                widget.sceneOwner?.sessions.entries
                    .where((entry) => entry.value.dirty)
                    .map((entry) => entry.key)
                    .toSet() ??
                const {},
            dirtyDialogueIds:
                widget.dialogueOwner?.entries
                    .where(
                      (entry) =>
                          widget.dialogueOwner?.session(entry.id)?.dirty ==
                          true,
                    )
                    .map((entry) => entry.id)
                    .toSet() ??
                const {},
            dirtyEventIds: widget.eventOwner?.dirtyIds ?? const {},
          ),
        ),
      ],
    );
  }
}
