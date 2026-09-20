import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

enum CinematicMapMode { select, pan, destination, placement, path }

class CinematicViewState {
  final mapTransform = TransformationController();
  final timelineScroll = ScrollController();
  final selection = <String>{};
  String? actorId;
  String? initialPlacementChoice;
  String inspectorTab = 'properties';
  CinematicMapMode mode = CinematicMapMode.select;
  bool libraryOpen = true, inspectorOpen = true, followCamera = false;
  double timelineScale = .06;
  bool timelineFitted = false;
  double mapShare = .48;
  String? error;
  String? spatialError;
  String? inspectorError;
  String? get stepId => selection.firstOrNull;
  void reconcile(CinematicAsset asset) {
    final ids = asset.timeline.steps.map((step) => step.id).toSet();
    selection.removeWhere((id) => !ids.contains(id));
    if (!asset.requiredActors.any((actor) => actor.actorId == actorId)) {
      actorId = asset.requiredActors.firstOrNull?.actorId;
    }
  }

  void dispose() {
    mapTransform.dispose();
    timelineScroll.dispose();
  }
}

class CinematicViewStore {
  final search = TextEditingController();
  final _states = <String, CinematicViewState>{};
  String folderId = '';
  bool archived = false;
  CinematicViewState forAsset(String id) =>
      _states.putIfAbsent(id, CinematicViewState.new);
  void dispose() {
    search.dispose();
    for (final state in _states.values) {
      state.dispose();
    }
  }
}
