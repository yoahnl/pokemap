import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

final class SpatialSceneComponents {
  SpatialSceneComponents(this.parent);

  final Component parent;
  Map<Object, _SceneBatch> _active = {};
  _PendingScene? _pending;

  Future<bool> replace(
    Iterable<Component> next, {
    bool Function()? isCurrent,
    void Function()? onCommit,
  }) =>
      replaceGroups({Object(): next}, isCurrent: isCurrent, onCommit: onCommit);

  Future<bool> replaceGroups(
    Map<Object, Iterable<Component>> groups, {
    bool Function()? isCurrent,
    void Function()? onCommit,
  }) async {
    cancelPending();
    final next = <Object, _SceneBatch>{};
    final staged = <_SceneBatch>[];
    for (final entry in groups.entries) {
      final children = entry.value.toList();
      final previous = _active[entry.key];
      if (previous != null && previous.matches(children)) {
        next[entry.key] = previous;
      } else {
        final batch = _SceneBatch(children);
        next[entry.key] = batch;
        staged.add(batch);
      }
    }
    final descendants = [
      for (final batch in staged)
        for (final child in batch.source)
          ...child.descendants(includeSelf: true),
    ];
    final pending = _PendingScene(staged);
    _pending = pending;
    try {
      parent.addAll(staged);
      final ready = parent.isMounted
          ? Future.wait([
              for (final batch in staged) batch.mounted,
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
      for (final batch in previous.values) {
        if (!next.containsValue(batch)) batch.visible = false;
      }
      for (final batch in next.values) {
        batch.visible = true;
      }
      _active = next;
      _pending = null;
      try {
        onCommit?.call();
      } on Object {
        for (final batch in staged) {
          batch.visible = false;
        }
        for (final batch in previous.values) {
          batch.visible = true;
        }
        _active = previous;
        rethrow;
      }
      for (final batch in previous.values) {
        if (!next.containsValue(batch)) batch.removeFromParent();
      }
      return true;
    } on Object {
      _cancel(pending);
      rethrow;
    }
  }

  void replaceSubset(Iterable<Component> previous, Iterable<Component> next) {
    final previousChildren = previous.toList();
    final batch =
        _active.values
            .where(
              (candidate) => previousChildren.any(
                (component) => identical(component.parent, candidate),
              ),
            )
            .firstOrNull ??
        _active.values.lastOrNull;
    if (batch == null) return;
    batch.removeAll(
      previousChildren.where((component) => identical(component.parent, batch)),
    );
    batch.addAll(next);
  }

  void cancelPending() {
    final pending = _pending;
    if (pending != null) _cancel(pending);
  }

  void _cancel(_PendingScene pending) {
    for (final batch in pending.batches) {
      batch.visible = false;
      batch.removeFromParent();
    }
    if (!pending.cancelled.isCompleted) pending.cancelled.complete(false);
    if (identical(_pending, pending)) _pending = null;
  }

  void dispose() {
    cancelPending();
    for (final batch in _active.values) {
      batch.visible = false;
      batch.removeFromParent();
    }
    _active = {};
  }
}

final class _PendingScene {
  _PendingScene(this.batches);

  final List<_SceneBatch> batches;
  final cancelled = Completer<bool>();
}

final class _SceneBatch extends Component {
  _SceneBatch(this.source) : super(children: source);

  final List<Component> source;

  bool matches(List<Component> next) {
    if (source.length != next.length) return false;
    for (var index = 0; index < source.length; index++) {
      if (!identical(source[index], next[index])) return false;
    }
    return true;
  }

  bool visible = false;

  @override
  void renderTree(Canvas canvas) {
    if (visible) super.renderTree(canvas);
  }
}
