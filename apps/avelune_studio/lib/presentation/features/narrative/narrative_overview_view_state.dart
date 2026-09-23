import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/narrative_overview.dart';
import '../../../features/narrative/application/narrative_overview_cache.dart';

enum NarrativeOverviewTab { stories, interactions, facts }

class NarrativeOverviewViewState {
  final search = TextEditingController();
  final cache = NarrativeOverviewCache();
  final _scrolls = {
    for (final tab in NarrativeOverviewTab.values) tab: ScrollController(),
  };
  ScrollController get scroll => _scrolls[tab]!;
  final collapsedChapters = <String>{};
  NarrativeOverviewTab tab = NarrativeOverviewTab.stories;
  String? storyId;
  String? stepId;
  String? interactionId;
  String? factId;
  String? mapId;
  String? notice;
  bool onlyDirty = false;
  bool detailVisible = false;
  bool initialized = false;
  bool showOverview = true;
  final resultsScroll = ScrollController();

  List<StorylineAsset> visibleStories(NarrativeOverview overview) {
    final query = search.text.trim().toLowerCase();
    return overview.stories
        .where(
          (story) =>
              story.title.toLowerCase().contains(query) ||
              story.chapters.any(
                (chapter) =>
                    chapter.title.toLowerCase().contains(query) ||
                    chapter.steps.any(
                      (step) => step.title.toLowerCase().contains(query),
                    ),
              ),
        )
        .toList();
  }

  List<NarrativeOverviewInteraction> visibleInteractions(
    NarrativeOverview overview,
  ) {
    final query = search.text.trim().toLowerCase();
    return overview.interactions
        .where(
          (item) =>
              item.searchText.contains(query) &&
              (mapId == null || item.mapId == mapId) &&
              (!onlyDirty || item.dirty),
        )
        .toList();
  }

  List<NarrativeFactDefinition> visibleFacts(NarrativeOverview overview) {
    final query = search.text.trim().toLowerCase();
    return overview.facts
        .where((fact) => fact.label.toLowerCase().contains(query))
        .toList();
  }

  void reconcileSelection(NarrativeOverview overview) {
    switch (tab) {
      case NarrativeOverviewTab.stories:
        final story = visibleStories(
          overview,
        ).where((item) => item.id == storyId).firstOrNull;
        if (story == null) {
          storyId = null;
          stepId = null;
          detailVisible = false;
          notice = null;
        } else if (stepId != null &&
            !story.chapters.any(
              (chapter) => chapter.steps.any((step) => step.id == stepId),
            )) {
          stepId = null;
          detailVisible = false;
          notice = null;
        }
      case NarrativeOverviewTab.interactions:
        if (interactionId != null &&
            !visibleInteractions(
              overview,
            ).any((item) => item.id == interactionId)) {
          interactionId = null;
          detailVisible = false;
          notice = null;
        }
      case NarrativeOverviewTab.facts:
        if (factId != null &&
            !visibleFacts(overview).any((item) => item.id == factId)) {
          factId = null;
          detailVisible = false;
          notice = null;
        }
    }
  }

  void select({String? step, String? interaction, String? fact}) {
    stepId = step;
    interactionId = interaction;
    factId = fact;
    detailVisible = true;
    notice = null;
  }

  void dispose() {
    search.dispose();
    resultsScroll.dispose();
    for (final controller in _scrolls.values) {
      controller.dispose();
    }
  }
}
