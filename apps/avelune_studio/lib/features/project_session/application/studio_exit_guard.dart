class StudioExitGuard {
  Future<bool> Function()? _guard;
  String? _sessionId;

  void register(String sessionId, Future<bool> Function()? guard) {
    if (guard != null) {
      _guard = guard;
      _sessionId = sessionId;
    } else if (_sessionId == sessionId) {
      _guard = null;
      _sessionId = null;
    }
  }

  Future<bool> confirmLeave() async {
    final guard = _guard;
    return guard == null || await guard();
  }
}
