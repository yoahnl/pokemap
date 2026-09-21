part of 'map_workspace_screen.dart';

extension _WorkspaceKeyboardBinding on _MapWorkspaceScreenState {
  void _keyboard(void Function() action) {
    if (_space != WorkspaceSpace.map) return;
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null ||
        _controller.loading ||
        _actions.testing ||
        _actions.closing) {
      return;
    }
    action();
    _toolChanged();
  }
}
