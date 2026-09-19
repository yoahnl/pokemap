import 'dart:async';
import 'package:flutter/foundation.dart';

final class StudioResourceNotifications extends ChangeNotifier {
  bool _pending = false;
  bool _closed = false;

  void emitLater() {
    if (_closed || _pending) return;
    _pending = true;
    scheduleMicrotask(() {
      _pending = false;
      if (!_closed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
