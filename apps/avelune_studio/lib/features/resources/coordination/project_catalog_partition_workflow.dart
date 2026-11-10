class ProjectCatalogPartitionWorkflow {
  ProjectCatalogPartitionWorkflow({
    required this.partition,
    required this.reopen,
    required this.confirm,
    required this.isActive,
    required this.changed,
  });

  final Future<void> Function() partition, reopen;
  final Future<bool> Function() confirm;
  final bool Function() isActive;
  final void Function() changed;
  Future<bool> Function()? childGuard;
  bool busy = false;
  bool _converted = false, _closed = false;
  String? error;

  bool get active => !_closed && isActive();

  Future<bool> allowExit() async {
    if (!active || busy) return false;
    return (await childGuard?.call() ?? true) && active && !busy;
  }

  Future<bool> optimize() async {
    if (!active || busy) return false;
    busy = true;
    error = null;
    changed();
    try {
      if (!(await childGuard?.call() ?? true) || !active) return false;
      if (!_converted) {
        if (!await confirm() || !active) return false;
        await partition();
        _converted = true;
      }
      if (!active) return false;
      await reopen();
      return active;
    } on Object catch (failure) {
      if (active) {
        error = 'La conversion ou sa réouverture n’a pas pu aboutir : $failure';
      }
      return false;
    } finally {
      busy = false;
      if (active) changed();
    }
  }

  void dispose() => _closed = true;
}
