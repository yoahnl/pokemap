export '../../../features/narrative/application/narrative_overview_selection.dart'
    show NarrativeOverviewTab;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/narrative/application/narrative_overview.dart';
import '../../../features/narrative/application/narrative_overview_cache.dart';
import '../../../features/narrative/application/narrative_overview_selection.dart';

class NarrativeOverviewViewState extends NarrativeOverviewSelection {
  final search = TextEditingController();
  final cache = NarrativeOverviewCache();
  final _scrolls = {
    for (final tab in NarrativeOverviewTab.values) tab: ScrollController(),
  };
  ScrollController get scroll => _scrolls[tab]!;
  final resultsScroll = ScrollController();

  @override
  List<StorylineAsset> visibleStories(NarrativeOverview overview) {
    query = search.text;
    return super.visibleStories(overview);
  }

  @override
  List<NarrativeOverviewInteraction> visibleInteractions(
    NarrativeOverview overview,
  ) {
    query = search.text;
    return super.visibleInteractions(overview);
  }

  @override
  List<NarrativeFactDefinition> visibleFacts(NarrativeOverview overview) {
    query = search.text;
    return super.visibleFacts(overview);
  }

  void dispose() {
    search.dispose();
    resultsScroll.dispose();
    for (final controller in _scrolls.values) {
      controller.dispose();
    }
  }
}
