import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// Semantic snap origin kept outside the timeline widget so extraction does
/// not turn local UI state into a second authoring model.
enum CinematicTimelineProbeSnapHint {
  timelineStart,
  timelineEnd,
  blockStart,
  blockEnd,
}

/// Owns transient Cinematic Builder selection state only.
///
/// Project mutations remain in the authoring transaction callbacks. This
/// controller deliberately contains no persistence, asset cloning or runtime
/// playback logic, which protects the behavior-constant boundary of NSC-61.
final class CinematicBuilderController extends ChangeNotifier {
  CinematicBuilderController({required CinematicAsset asset})
      : _assetId = asset.id;

  String _assetId;
  String? _selectedStepId;
  int? _timelineProbeTimeMs;
  CinematicTimelineProbeSnapHint? _timelineProbeSnapHint;
  String? _selectedStagePointId;
  bool _addStagePointMode = false;

  String get assetId => _assetId;

  String? get selectedStepId => _selectedStepId;
  set selectedStepId(String? value) => _update(
        _selectedStepId != value,
        () => _selectedStepId = value,
      );

  int? get timelineProbeTimeMs => _timelineProbeTimeMs;
  set timelineProbeTimeMs(int? value) => _update(
        _timelineProbeTimeMs != value,
        () => _timelineProbeTimeMs = value,
      );

  CinematicTimelineProbeSnapHint? get timelineProbeSnapHint =>
      _timelineProbeSnapHint;
  set timelineProbeSnapHint(CinematicTimelineProbeSnapHint? value) => _update(
        _timelineProbeSnapHint != value,
        () => _timelineProbeSnapHint = value,
      );

  String? get selectedStagePointId => _selectedStagePointId;
  set selectedStagePointId(String? value) => _update(
        _selectedStagePointId != value,
        () => _selectedStagePointId = value,
      );

  bool get addStagePointMode => _addStagePointMode;
  set addStagePointMode(bool value) => _update(
        _addStagePointMode != value,
        () => _addStagePointMode = value,
      );

  /// Preserves local state for an updated snapshot of the same asset, while
  /// rejecting a selected step that no longer exists. Switching assets clears
  /// all ephemeral context and cannot leak one Cinematic selection to another.
  void synchronize(CinematicAsset asset) {
    if (_assetId != asset.id) {
      _assetId = asset.id;
      _reset(notify: true);
      return;
    }
    final selectedStepId = _selectedStepId;
    if (selectedStepId != null &&
        !asset.timeline.steps.any((step) => step.id == selectedStepId)) {
      _selectedStepId = null;
      notifyListeners();
    }
  }

  void clearTimelineProbe() {
    final changed =
        _timelineProbeTimeMs != null || _timelineProbeSnapHint != null;
    _timelineProbeTimeMs = null;
    _timelineProbeSnapHint = null;
    if (changed) notifyListeners();
  }

  void _reset({required bool notify}) {
    _selectedStepId = null;
    _timelineProbeTimeMs = null;
    _timelineProbeSnapHint = null;
    _selectedStagePointId = null;
    _addStagePointMode = false;
    if (notify) notifyListeners();
  }

  void _update(bool changed, VoidCallback update) {
    if (!changed) return;
    update();
    notifyListeners();
  }
}
