import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_authoring/map_authoring_presentation_editing.dart';

enum PresentationPose { start, end, trajectory }

class PresentationViewState {
  PresentationViewState(PresentationCinematicAsset asset)
    : editing = PresentationTimelineEditingController(asset: asset);
  final PresentationTimelineEditingController editing;
  final canvasTransform = TransformationController();
  final timelineScroll = ScrollController();
  final invalidFields = <String>{};
  bool libraryOpen = true, inspectorOpen = true;
  bool elements = false, portrait = false, compare = false, pan = false;
  bool reduceMotion = false, reduceFlashes = false, captions = true;
  String inspectorTab = 'properties';
  PresentationPose pose = PresentationPose.trajectory;
  bool orientationOverride = false;
  double canvasShare = .58, pixelsPerSecond = 60;
  String? actionError;
  String? get selectedId => editing.selectedClipIds.firstOrNull;
  PresentationClip? get selected =>
      selectedId == null ? null : editing.sourceClip(selectedId!);
  void reconcile(PresentationCinematicAsset asset) =>
      editing.configureAsset(asset);
  void dispose() {
    editing.dispose();
    canvasTransform.dispose();
    timelineScroll.dispose();
  }
}

class PresentationViewStore {
  final search = TextEditingController();
  final _states = <String, PresentationViewState>{};
  String folderId = '';
  bool archived = false;
  PresentationViewState forAsset(PresentationCinematicAsset asset) =>
      _states.putIfAbsent(asset.id, () => PresentationViewState(asset));
  void dispose() {
    search.dispose();
    for (final state in _states.values) {
      state.dispose();
    }
  }
}
