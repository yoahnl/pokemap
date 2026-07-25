import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

/// Keeps logical pause selection stable while responsive layouts remount nodes.
final class RuntimePlayerFocusController extends ChangeNotifier {
  RuntimePlayerFocusController({
    String? logicalSelectionId,
    PlayerInputSource activeInputSource = PlayerInputSource.keyboard,
  })  : _logicalSelectionId = logicalSelectionId,
        _activeInputSource = activeInputSource;

  final _nodes = <String, FocusNode>{};
  final _nodeListeners = <String, VoidCallback>{};
  String? _logicalSelectionId;
  PlayerInputSource _activeInputSource;
  int _focusRequestGeneration = 0;
  bool _disposed = false;

  String? get logicalSelectionId => _logicalSelectionId;
  PlayerInputSource get activeInputSource => _activeInputSource;
  bool get showFocusHighlight =>
      _activeInputSource == PlayerInputSource.keyboard ||
      _activeInputSource == PlayerInputSource.controller;

  FocusNode nodeFor(
    String logicalId, {
    required String debugLabel,
  }) {
    return _nodes.putIfAbsent(logicalId, () {
      final node = FocusNode(debugLabel: debugLabel);
      void listener() {
        if (!node.hasFocus || _disposed) return;
        if (_logicalSelectionId != logicalId) {
          _logicalSelectionId = logicalId;
          notifyListeners();
        }
      }

      _nodeListeners[logicalId] = listener;
      node.addListener(listener);
      return node;
    });
  }

  void noteInputSource(PlayerInputSource source) {
    if (_activeInputSource == source || _disposed) return;
    _activeInputSource = source;
    notifyListeners();
  }

  void select(
    String logicalId, {
    PlayerInputSource? source,
    bool requestFocus = false,
  }) {
    if (_disposed) return;
    if (source != null) _activeInputSource = source;
    final changed = _logicalSelectionId != logicalId;
    _logicalSelectionId = logicalId;
    if (changed || source != null) notifyListeners();
    if (requestFocus) _requestFocusAfterLayout(logicalId);
  }

  void restoreSelection(String? logicalId) {
    if (_disposed || logicalId == null) return;
    _logicalSelectionId = logicalId;
    _requestFocusAfterLayout(logicalId);
  }

  void _requestFocusAfterLayout(String logicalId) {
    final generation = ++_focusRequestGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || generation != _focusRequestGeneration) return;
      final node = _nodes[logicalId];
      if (node != null && node.context != null && node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _focusRequestGeneration++;
    for (final entry in _nodes.entries) {
      final listener = _nodeListeners[entry.key];
      if (listener != null) entry.value.removeListener(listener);
      entry.value.dispose();
    }
    _nodes.clear();
    _nodeListeners.clear();
    super.dispose();
  }
}
