part of 'map_workspace_screen.dart';

extension _WorkspaceKeyboardBinding on _MapWorkspaceScreenState {
  bool get _keyboardBusy =>
      _space != WorkspaceSpace.map ||
      _controller.loading ||
      _actions.testing ||
      _actions.closing;

  bool get _typing =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  void _keyboard(void Function() action) {
    if (_keyboardBusy || _typing) return;
    action();
    _toolChanged();
  }

  /// Saving is the one command an author expects to work while still writing:
  /// the entry is committed first, then the document is written.
  void _keyboardWhileTyping(void Function() action) {
    if (_keyboardBusy) return;
    action();
    _toolChanged();
  }
}
