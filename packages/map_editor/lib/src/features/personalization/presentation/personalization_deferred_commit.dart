import 'dart:async';

const personalizationTextCommitDelay = Duration(milliseconds: 350);

final class PersonalizationDeferredCommitCoordinator {
  final Set<PersonalizationDeferredCommit> _commits =
      <PersonalizationDeferredCommit>{};

  void register(PersonalizationDeferredCommit commit) => _commits.add(commit);

  void unregister(PersonalizationDeferredCommit commit) =>
      _commits.remove(commit);

  void flush() {
    for (final commit in List<PersonalizationDeferredCommit>.of(_commits)) {
      commit.flush();
    }
  }
}

final class PersonalizationDeferredCommit {
  PersonalizationDeferredCommit([this._coordinator]) {
    _coordinator?.register(this);
  }

  final PersonalizationDeferredCommitCoordinator? _coordinator;
  Timer? _timer;
  void Function()? _pending;

  bool get hasPending => _pending != null;

  void schedule(void Function() commit) {
    _timer?.cancel();
    _pending = commit;
    _timer = Timer(personalizationTextCommitDelay, flush);
  }

  void flush() {
    final pending = _pending;
    if (pending == null) return;
    _timer?.cancel();
    _timer = null;
    _pending = null;
    pending();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  void dispose() {
    _coordinator?.unregister(this);
    cancel();
  }
}
