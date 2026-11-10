import '../../../features/presentations/application/presentation_pose_projection.dart';

import 'package:avelune_studio/features/presentations/coordination/presentation_editing_sessions.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_authoring/map_authoring_presentation_editing.dart';

export '../../../features/presentations/application/presentation_pose_projection.dart'
    show PresentationPose;

class PresentationViewState {
  PresentationViewState(
    PresentationCinematicAsset asset, {
    PresentationTimelineEditingController? editing,
    Set<String>? invalidFields,
  }) : invalidFields = invalidFields ?? <String>{},
       editing = editing ?? PresentationTimelineEditingController(asset: asset),
       _ownsEditing = editing == null;
  final bool _ownsEditing;
  final PresentationTimelineEditingController editing;
  final canvasTransform = TransformationController();
  final timelineScroll = ScrollController();
  final Set<String> invalidFields;
  bool inspectorOpen = true;
  bool portrait = false, compare = false, pan = false;
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
    if (_ownsEditing) editing.dispose();
    canvasTransform.dispose();
    timelineScroll.dispose();
  }
}

class PresentationViewStore {
  PresentationViewStore({PresentationEditingSessions? editingSessions})
    : editingSessions = editingSessions ?? PresentationEditingSessions(),
      _ownsEditing = editingSessions == null;
  final PresentationEditingSessions editingSessions;
  final bool _ownsEditing;
  final _states = <String, PresentationViewState>{};
  PresentationViewState forAsset(PresentationCinematicAsset asset) =>
      _states.putIfAbsent(
        asset.id,
        () => PresentationViewState(
          asset,
          editing: editingSessions.forAsset(asset),
          invalidFields: editingSessions.invalidFieldsFor(asset.id),
        ),
      );
  void dispose() {
    for (final state in _states.values) {
      state.dispose();
    }
    if (_ownsEditing) editingSessions.dispose();
  }
}
