import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

Map<ShortcutActivator, VoidCallback> textAwareEditorShortcuts(
  Map<ShortcutActivator, VoidCallback> bindings,
) => {
  for (final entry in bindings.entries)
    _EditorShortcutActivator(entry.key): entry.value,
};

class _EditorShortcutActivator extends ShortcutActivator {
  const _EditorShortcutActivator(this.delegate);

  final ShortcutActivator delegate;

  @override
  Iterable<LogicalKeyboardKey>? get triggers => delegate.triggers;

  @override
  String debugDescribeKeys() => delegate.debugDescribeKeys();

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    if (!delegate.accepts(event, state)) return false;
    if (event.logicalKey == LogicalKeyboardKey.keyS &&
        (state.isControlPressed || state.isMetaPressed)) {
      return true;
    }
    final context = FocusManager.instance.primaryFocus?.context;
    return context?.widget is! EditableText &&
        context?.findAncestorWidgetOfExactType<EditableText>() == null;
  }
}
