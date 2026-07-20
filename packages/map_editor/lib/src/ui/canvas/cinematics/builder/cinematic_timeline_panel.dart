import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

final class CinematicTimelineEditingController extends ChangeNotifier {
  final Set<String> _selectedStepIds = {};
  final Map<String, CinematicTimelineTrackState> _trackStates = {};

  Set<String> get selectedStepIds => Set.unmodifiable(_selectedStepIds);
  Map<String, CinematicTimelineTrackState> get trackStates =>
      Map.unmodifiable(_trackStates);

  void select(String stepId, {bool additive = false}) {
    if (!additive) _selectedStepIds.clear();
    if (additive && _selectedStepIds.contains(stepId)) {
      _selectedStepIds.remove(stepId);
    } else {
      _selectedStepIds.add(stepId);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedStepIds.isEmpty) return;
    _selectedStepIds.clear();
    notifyListeners();
  }

  void toggleCollapsed(String laneId) => _updateTrack(
        laneId,
        (state) => state.copyWith(isCollapsed: !state.isCollapsed),
      );
  void toggleLocked(String laneId) => _updateTrack(
        laneId,
        (state) => state.copyWith(isLocked: !state.isLocked),
      );
  void toggleMuted(String laneId) => _updateTrack(
        laneId,
        (state) => state.copyWith(isMuted: !state.isMuted),
      );
  void toggleSolo(String laneId) => _updateTrack(
        laneId,
        (state) => state.copyWith(isSolo: !state.isSolo),
      );

  void _updateTrack(
    String laneId,
    CinematicTimelineTrackState Function(CinematicTimelineTrackState) update,
  ) {
    _trackStates[laneId] =
        update(_trackStates[laneId] ?? const CinematicTimelineTrackState());
    notifyListeners();
  }
}

/// Render-neutral owner for the deterministic Cinematic timeline surface.
final class CinematicTimelinePanel extends StatelessWidget {
  const CinematicTimelinePanel({
    super.key,
    required this.child,
    this.controller,
    this.onDuplicateSelection,
    this.onDeleteSelection,
    this.onCopySelection,
    this.onPaste,
    this.onMoveSelectionEarlier,
    this.onMoveSelectionLater,
  });

  static const surfaceKey = ValueKey<String>('cinematic-timeline-panel');

  final Widget child;
  final CinematicTimelineEditingController? controller;
  final Future<void> Function()? onDuplicateSelection;
  final Future<void> Function()? onDeleteSelection;
  final Future<void> Function()? onCopySelection;
  final Future<void> Function()? onPaste;
  final Future<void> Function()? onMoveSelectionEarlier;
  final Future<void> Function()? onMoveSelectionLater;

  @override
  Widget build(BuildContext context) => Focus(
        autofocus: controller != null,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final hardware = HardwareKeyboard.instance;
          final command = hardware.isMetaPressed || hardware.isControlPressed;
          if (command && event.logicalKey == LogicalKeyboardKey.keyD) {
            onDuplicateSelection?.call();
            return KeyEventResult.handled;
          }
          if (command && event.logicalKey == LogicalKeyboardKey.keyC) {
            onCopySelection?.call();
            return KeyEventResult.handled;
          }
          if (command && event.logicalKey == LogicalKeyboardKey.keyV) {
            onPaste?.call();
            return KeyEventResult.handled;
          }
          if (command && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            onMoveSelectionEarlier?.call();
            return KeyEventResult.handled;
          }
          if (command && event.logicalKey == LogicalKeyboardKey.arrowRight) {
            onMoveSelectionLater?.call();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onDeleteSelection?.call();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: KeyedSubtree(key: surfaceKey, child: child),
      );
}
