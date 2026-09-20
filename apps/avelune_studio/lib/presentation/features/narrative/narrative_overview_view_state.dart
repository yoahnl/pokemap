import 'package:flutter/widgets.dart';
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

  void select({String? step, String? interaction, String? fact}) {
    stepId = step;
    interactionId = interaction;
    factId = fact;
    detailVisible = true;
    notice = null;
  }

  void dispose() {
    search.dispose();
    for (final controller in _scrolls.values) {
      controller.dispose();
    }
  }
}
