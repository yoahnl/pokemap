import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

final class SpatialSceneComponents {
  SpatialSceneComponents(this.parent);

  final Component parent;
  _SceneBatch? _active;
  _PendingScene? _pending;

  Future<bool> replace(
    Iterable<Component> next, {
    bool Function()? isCurrent,
    void Function()? onCommit,
  }) async {
    cancelPending();
    final children = next.toList();
    final descendants = [
      for (final child in children) ...child.descendants(includeSelf: true),
    ];
    final batch = _SceneBatch(children);
    final pending = _PendingScene(batch);
    _pending = pending;
    try {
      parent.add(batch);
      final ready = parent.isMounted
          ? Future.wait([
              batch.mounted,
              for (final child in descendants) child.mounted,
            ]).then((_) => true)
          : Future.value(true);
      final mounted = await Future.any([ready, pending.cancelled.future]);
      if (!mounted ||
          !identical(_pending, pending) ||
          !(isCurrent?.call() ?? true)) {
        _cancel(pending);
        return false;
      }
      final previous = _active;
      previous?.visible = false;
      batch.visible = true;
      _active = batch;
      _pending = null;
      try {
        onCommit?.call();
      } on Object {
        batch.visible = false;
        previous?.visible = true;
        _active = previous;
        rethrow;
      }
      previous?.removeFromParent();
      return true;
    } on Object {
      _cancel(pending);
      rethrow;
    }
  }

  void replaceSubset(Iterable<Component> previous, Iterable<Component> next) {
    final batch = _active;
    if (batch == null) return;
    batch.removeAll(
      previous.where((component) => identical(component.parent, batch)),
    );
    batch.addAll(next);
  }

  void cancelPending() {
    final pending = _pending;
    if (pending != null) _cancel(pending);
  }

  void _cancel(_PendingScene pending) {
    pending.batch.visible = false;
    pending.batch.removeFromParent();
    if (!pending.cancelled.isCompleted) pending.cancelled.complete(false);
    if (identical(_pending, pending)) _pending = null;
  }

  void dispose() {
    cancelPending();
    _active?.visible = false;
    _active?.removeFromParent();
    _active = null;
  }
}

final class _PendingScene {
  _PendingScene(this.batch);

  final _SceneBatch batch;
  final cancelled = Completer<bool>();
}

final class _SceneBatch extends Component {
  _SceneBatch(List<Component> children) : super(children: children);

  bool visible = false;

  @override
  void renderTree(Canvas canvas) {
    if (visible) super.renderTree(canvas);
  }
}
