part of 'map_workspace_screen.dart';

extension _WorkspaceNavigationBinding on _MapWorkspaceScreenState {
  void _show(WorkspaceSpace space) {
    final inPresentation = _space == WorkspaceSpace.presentation;
    if (inPresentation && space != _space) {
      _presentations?.suspendPreview?.call();
    }
    if (inPresentation && _presentations?.flushEdits?.call() == false) return;
    if (_space == WorkspaceSpace.cinematic) {
      _cinematics?.transport.pause();
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    if (space != WorkspaceSpace.map) _cinematicMapReturn = false;
    if (_space == WorkspaceSpace.dialogue) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    if (space != WorkspaceSpace.map) _eventMapReturn = false;
    if (space != WorkspaceSpace.map) _verificationMapReturn = false;
    if (_space == WorkspaceSpace.events) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    if (_space == WorkspaceSpace.progression) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (space == WorkspaceSpace.story) {
        _storyViewState.storyId = _stories?.activeId;
        _storyViewState.stepId = null;
      }
    }
    _closeContextMenu();
    _navigationRequest++;
    _interactionNotice?.close();
    _narrative?.cancelOpening();
    _enterSpace(space);
  }
}
