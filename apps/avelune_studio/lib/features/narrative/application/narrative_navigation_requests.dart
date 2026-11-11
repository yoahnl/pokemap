class NarrativeNavigationRequests {
  int _latest = 0;

  Future<String?> run(
    Future<String?> Function(String) action,
    String id, {
    bool Function()? relevant,
  }) async {
    final request = ++_latest;
    final error = await action(id);
    if (request != _latest) return null;
    if (relevant != null && !relevant()) return null;
    return error;
  }
}
