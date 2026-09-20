import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'story_view_state.dart';

class StoryProgressionViewStore {
  final search = TextEditingController();
  StorylineType? type;
  final _views = <(Object, String), StoryProgressionDocumentView>{};
  StoryProgressionDocumentView forStory(Object project, String storyId) =>
      _views.putIfAbsent((project, storyId), StoryProgressionDocumentView.new);
  void dispose() {
    search.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
  }
}

class StoryProgressionDocumentView {
  final graph = StoryViewState();
  final scroll = ScrollController();
  StoryGraphSelection? selection;
  bool structure = false;
  bool library = false;
  bool inspector = false;
  void dispose() {
    graph.dispose();
    scroll.dispose();
  }
}
