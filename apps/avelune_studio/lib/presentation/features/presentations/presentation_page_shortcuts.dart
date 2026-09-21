part of 'presentation_workspace_page.dart';

extension _PresentationPageShortcuts on _PresentationWorkspacePageState {
  bool get editingText {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    return focused.widget is EditableText ||
        focused.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool handleShortcut(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    if (controller.active == null || editingText) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final keyboard = HardwareKeyboard.instance;
    final command = keyboard.isMetaPressed || keyboard.isControlPressed;
    if (command) {
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        unawaited(save());
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (!flush()) return true;
        keyboard.isShiftPressed ? controller.redo() : controller.undo();
        refresh();
        return true;
      }
      return false;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        transport.playing ? transport.pause() : transport.play();
      case LogicalKeyboardKey.arrowRight:
        transport.stepForward();
      case LogicalKeyboardKey.arrowLeft:
        transport.stepBackward();
      case LogicalKeyboardKey.home:
        transport.seek(0);
      case LogicalKeyboardKey.end:
        transport.seek(transport.durationUs);
      default:
        return false;
    }
    return true;
  }
}
