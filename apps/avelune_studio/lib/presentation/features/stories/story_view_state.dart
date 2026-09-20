import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../scenes/scene_canvas_types.dart';

class StoryGraphSelection {
  const StoryGraphSelection.node(this.node) : edge = null;
  const StoryGraphSelection.edge(this.edge) : node = null;
  final StorylineProgressionNode? node;
  final StorylineProgressionEdge? edge;
  String get id => node?.id ?? edge!.id;
}

class StoryViewState extends ChangeNotifier {
  StoryViewState() {
    viewport.addListener(notifyListeners);
  }
  final viewport = SceneGraphViewport();
  final positions = <String, Offset>{};
  final revealedFacts = <String>{};
  final revealedStories = <String>{};
  final _undo = <Map<String, Offset>>[];
  final _redo = <Map<String, Offset>>[];
  String? revealId;
  bool showMinimap = true;
  int sourcesRevision = 0;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  void moveGroup(String id, Offset position) {
    if (positions[id] == position) return;
    _undo.add(Map.of(positions));
    if (_undo.length > 60) _undo.removeAt(0);
    _redo.clear();
    positions[id] = position;
    notifyListeners();
  }

  void undo() => _restore(_undo, _redo);
  void redo() => _restore(_redo, _undo);
  void _restore(List<Map<String, Offset>> from, List<Map<String, Offset>> to) {
    if (from.isEmpty) return;
    to.add(Map.of(positions));
    positions
      ..clear()
      ..addAll(from.removeLast());
    notifyListeners();
  }

  void reveal(StoryGraphSelection selection) {
    revealId = selection.id;
    notifyListeners();
  }

  void revealFact(String id) {
    if (!revealedFacts.add(id)) return;
    sourcesRevision++;
    revealId = 'fact:$id';
    notifyListeners();
  }

  void revealStory(String id) {
    if (!revealedStories.add(id)) return;
    sourcesRevision++;
    revealId = 'storyline:$id';
    notifyListeners();
  }

  void fit(Rect bounds) {
    final reserve =
        showMinimap && viewport.size.width > 450 && viewport.size.height > 300
        ? 136.0
        : 0.0;
    viewport.fit(
      Rect.fromLTRB(
        bounds.left,
        bounds.top,
        bounds.right,
        bounds.bottom + reserve,
      ),
    );
    viewport.translate(
      Offset(0, 60 - bounds.top * viewport.zoom - viewport.pan.dy),
    );
  }

  void toggleMinimap() {
    showMinimap = !showMinimap;
    notifyListeners();
  }

  @override
  void dispose() {
    viewport.removeListener(notifyListeners);
    viewport.dispose();
    super.dispose();
  }
}
