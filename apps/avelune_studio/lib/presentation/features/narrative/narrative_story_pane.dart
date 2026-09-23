import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../../features/narrative/application/narrative_overview.dart';
import '../../../features/narrative/domain/narrative_port.dart';
import '../../../features/scenes/application/scene_workspace_controller.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import '../../../features/verification/application/verification_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import 'narrative_overview_content.dart';
import 'narrative_overview_detail.dart';
import 'narrative_overview_header.dart';
import 'narrative_overview_landing.dart';
import 'narrative_overview_navigation.dart';
import 'narrative_overview_view_state.dart';
import '../stories/story_create_dialog.dart';
import 'narrative_name_dialog.dart';

part 'narrative_story_pane_overview.dart';
part 'narrative_story_pane_creation.dart';

class NarrativeStoryPane extends StatefulWidget {
  const NarrativeStoryPane({
    super.key,
    required this.controller,
    required this.viewState,
    required this.onOpen,
    required this.onLocate,
    required this.onCreateInteraction,
    this.onScenes,
    this.onWorld,
    this.onVerification,
    this.onDialogues,
    this.onCinematics,
    this.onEvents,
    this.onProgression,
    this.onOpenScene,
    this.storyOwner,
    this.sceneOwner,
    this.dialogueOwner,
    this.eventOwner,
    this.verification,
    this.onOpenStep,
    this.onOpenDialogue,
    this.onOpenEvent,
    this.onOpenMap,
  });
  final NarrativeWorkspaceController controller;
  final NarrativeOverviewViewState viewState;
  final Future<String?> Function(String) onOpen, onLocate;
  final VoidCallback onCreateInteraction;
  final VoidCallback? onWorld;
  final VoidCallback? onVerification;
  final VoidCallback? onScenes,
      onProgression,
      onEvents,
      onDialogues,
      onCinematics;
  final Future<String?> Function(String)? onOpenScene;
  final StoryWorkspaceController? storyOwner;
  final SceneWorkspaceController? sceneOwner;
  final DialogueWorkspaceController? dialogueOwner;
  final EventWorkspaceController? eventOwner;
  final VerificationWorkspaceController? verification;
  final void Function(String storyId, String stepId)? onOpenStep;
  final ValueChanged<String>? onOpenDialogue, onOpenEvent, onOpenMap;

  @override
  State<NarrativeStoryPane> createState() => _NarrativeStoryPaneState();
}

class _NarrativeStoryPaneState extends State<NarrativeStoryPane> {
  var _navigationRequest = 0;
  NarrativeOverviewViewState get state => widget.viewState;
  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final overview = state.cache.read(widget.controller);
    if (!state.initialized) {
      state.initialized = true;
      state.storyId = overview.stories.firstOrNull?.id;
      if (overview.stories.isEmpty) {
        state.tab = NarrativeOverviewTab.interactions;
      }
    }
    state.reconcileSelection(overview);
    final stories = state.visibleStories(overview);
    final story = overview.stories
        .where((candidate) => candidate.id == state.storyId)
        .firstOrNull;
    if (state.showOverview) return _buildOverview(overview);
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            state.detailVisible) {
          setState(() => state.detailVisible = false);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 1050 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final detail = NarrativeOverviewDetail(
            overview: overview,
            state: state,
            story: story,
            onChanged: refresh,
            busy: widget.controller.busy,
            onOpen: (id) => _navigate(widget.onOpen, id),
            onLocate: (id) => _navigate(widget.onLocate, id),
            onOpenScene: widget.onOpenScene == null
                ? null
                : (id) => _navigate(widget.onOpenScene!, id),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NarrativeOverviewHeader(
                controller: widget.controller,
                compactDetail:
                    compact &&
                    (state.detailVisible || constraints.maxHeight < 680),
                summary:
                    '${widget.controller.project.name} · ${overview.stories.length} histoire(s) · ${overview.interactions.length} interaction(s) · ${overview.dirtyCount} brouillon(s) narratif(s)',
                onCreated: refresh,
                onScenes: widget.onScenes,
                onWorld: widget.onWorld,
                onVerification: widget.onVerification,
                onDialogues: widget.onDialogues,
                onCinematics: widget.onCinematics,
                onEvents: widget.onEvents,
                onProgression: widget.onProgression,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StudioButton(
                    label: 'Vue d’ensemble',
                    icon: Icons.arrow_back,
                    secondary: true,
                    onPressed: () => setState(() => state.showOverview = true),
                  ),
                ),
              ),
              if (widget.controller.publicationError case final error?)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StudioNotice(error, isError: true),
                ),
              if (compact && state.detailVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StudioButton(
                      label: 'Retour à la liste',
                      secondary: true,
                      icon: Icons.arrow_back,
                      onPressed: () =>
                          setState(() => state.detailVisible = false),
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: StudioSearchField(
                    controller: state.search,
                    label: 'Rechercher dans Histoire',
                    hint:
                        'Histoires, chapitres, étapes, interactions, cartes et sources connues',
                    onChanged: (_) => refresh(),
                  ),
                ),
                if (compact)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: StudioTabs(
                      items: const {
                        NarrativeOverviewTab.stories: 'Histoires',
                        NarrativeOverviewTab.interactions: 'Interactions',
                        NarrativeOverviewTab.facts: 'États',
                      },
                      selected: state.tab,
                      onChanged: (tab) => setState(() {
                        state.tab = tab;
                        state.select();
                        state.detailVisible = false;
                      }),
                    ),
                  ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: compact && state.detailVisible
                      ? detail
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!compact) ...[
                              SizedBox(
                                width: 210,
                                child: NarrativeOverviewNavigation(
                                  state: state,
                                  stories: stories,
                                  onChanged: refresh,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: NarrativeOverviewContent(
                                overview: overview,
                                state: state,
                                story: story,
                                stories: stories,
                                compact: compact,
                                onChanged: refresh,
                                onCreateInteraction: widget.onCreateInteraction,
                              ),
                            ),
                            if (!compact) ...[
                              const SizedBox(width: 12),
                              SizedBox(width: 320, child: detail),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _navigate(
    Future<String?> Function(String) action,
    String id,
  ) async {
    final request = ++_navigationRequest;
    final error = await action(id);
    if (mounted &&
        request == _navigationRequest &&
        state.interactionId == id &&
        error != null) {
      setState(() => state.notice = error);
    }
  }

  Future<void> _navigateDocument(
    Future<String?> Function(String) action,
    String id,
  ) async {
    final request = ++_navigationRequest;
    final error = await action(id);
    if (mounted && request == _navigationRequest && error != null) {
      setState(() => state.notice = error);
    }
  }
}
