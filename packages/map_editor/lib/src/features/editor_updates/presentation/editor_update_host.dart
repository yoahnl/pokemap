import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/editor_update_providers.dart';

final class EditorUpdateHost extends ConsumerStatefulWidget {
  const EditorUpdateHost({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<EditorUpdateHost> createState() => _EditorUpdateHostState();
}

final class _EditorUpdateHostState extends ConsumerState<EditorUpdateHost> {
  bool _automaticCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _automaticCheckScheduled) {
        return;
      }
      _automaticCheckScheduled = true;
      unawaited(
        ref.read(editorUpdateControllerProvider).scheduleAutomaticCheck(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(editorUpdateControllerProvider);
    return widget.child;
  }
}
