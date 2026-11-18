import 'dart:async';

import '../domain/verification_port.dart';
import 'verification_problems.dart';
import 'verification_snapshot.dart';

enum ProjectVerificationPhase {
  idle,
  project,
  maps,
  dialogues,
  analysis,
  done,
  failed,
  cancelled,
}

final class ProjectVerificationController {
  ProjectVerificationController({required this.port, required this.changed});

  final VerificationPort port;
  final void Function() changed;
  var phase = ProjectVerificationPhase.idle;
  var mapsLoaded = 0;
  var mapsTotal = 0;
  Object? failure;
  VerificationSnapshot? _snapshot;
  String? _latestRevision;
  bool? _latestInputMatch;
  Timer? _watch;
  VerificationJob? _job;
  var _run = 0;
  var _revisionRequest = 0;
  var _visible = false;
  var _polling = false;
  var _disposed = false;

  VerificationSnapshot? get snapshot => _snapshot;
  Duration? get elapsed => _snapshot?.elapsed;
  List<VerificationProblem> get problems => _snapshot?.problems ?? const [];
  VerificationFreshness? get freshness =>
      _snapshot?.freshness(_latestRevision, inputsMatch: _latestInputMatch);

  bool get running => const {
    ProjectVerificationPhase.project,
    ProjectVerificationPhase.maps,
    ProjectVerificationPhase.dialogues,
    ProjectVerificationPhase.analysis,
  }.contains(phase);

  Future<void> start() async {
    if (running || _disposed) return;
    final run = ++_run;
    final watch = Stopwatch()..start();
    bool current() => run == _run;
    void enter(ProjectVerificationPhase next) {
      phase = next;
      changed();
    }

    failure = null;
    _snapshot = null;
    _latestRevision = null;
    _latestInputMatch = null;
    _syncWatch();
    mapsLoaded = 0;
    mapsTotal = 0;
    enter(ProjectVerificationPhase.project);
    try {
      final revision = await port.projectRevision();
      if (!current()) return;
      final project = await port.readProject();
      if (!current()) return;
      enter(ProjectVerificationPhase.maps);
      final maps = await port.readMaps(
        project.maps,
        progress: (loaded, total) {
          if (!current()) return;
          mapsLoaded = loaded;
          mapsTotal = total;
          changed();
        },
      );
      if (!current()) return;
      enter(ProjectVerificationPhase.dialogues);
      final sources = await port.readDialogueSources(project.dialogues);
      if (!current()) return;
      enter(ProjectVerificationPhase.analysis);
      final job = _job = port.analyse(
        project: project,
        maps: maps,
        sources: sources,
      );
      final analysis = await job.result;
      if (!current()) return;
      final inputRevisions = List<VerificationInputRevision>.unmodifiable([
        for (final map in maps) ?map.inputRevision,
        for (final source in sources) ?source.inputRevision,
        ...analysis.additionalInputs,
      ]);
      final inputsMatch = await _checkInputs(inputRevisions);
      if (!current()) return;
      final after = await _readRevision();
      if (!current()) return;
      _latestRevision = after;
      _latestInputMatch = inputsMatch;
      _snapshot = VerificationSnapshot(
        revision: revision,
        revisionAfterAnalysis: after,
        elapsed: watch.elapsed,
        project: project,
        analysis: analysis,
        sources: sources,
        inputRevisions: inputRevisions,
        inputsMatchedAfterAnalysis: inputsMatch,
      );
      _syncWatch();
      enter(ProjectVerificationPhase.done);
    } on Object catch (error) {
      if (!current()) return;
      failure = error;
      enter(ProjectVerificationPhase.failed);
    } finally {
      if (current()) _job = null;
    }
  }

  void cancel() {
    if (!running) return;
    _run++;
    _job?.cancel();
    _job = null;
    phase = ProjectVerificationPhase.cancelled;
    changed();
  }

  void setVisible(bool visible) {
    if (_visible == visible || _disposed) return;
    _visible = visible;
    _syncWatch();
    if (visible) unawaited(_pollRevision());
  }

  Future<void> refreshRevision({bool checkInputs = true}) async {
    final snapshot = _snapshot;
    if (_disposed || snapshot == null) return;
    final request = ++_revisionRequest;
    final inputMatch = checkInputs
        ? await _checkInputs(snapshot.inputRevisions)
        : _latestInputMatch;
    final revision = await _readRevision();
    if (_disposed ||
        request != _revisionRequest ||
        !identical(snapshot, _snapshot)) {
      return;
    }
    if (revision == _latestRevision && inputMatch == _latestInputMatch) return;
    _latestRevision = revision;
    _latestInputMatch = inputMatch;
    changed();
  }

  Future<bool?> _checkInputs(List<VerificationInputRevision> inputs) async {
    try {
      return await port.inputsMatch(inputs);
    } on Object {
      return null;
    }
  }

  Future<String?> _readRevision() async {
    try {
      return await port.projectRevision();
    } on Object {
      return null;
    }
  }

  void _syncWatch() {
    if (_visible && _snapshot != null && !_disposed) {
      _watch ??= Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_pollRevision()),
      );
    } else {
      _watch?.cancel();
      _watch = null;
    }
  }

  Future<void> _pollRevision() async {
    if (_polling) return;
    _polling = true;
    try {
      await refreshRevision();
    } finally {
      _polling = false;
    }
  }

  void dispose() {
    _disposed = true;
    _run++;
    _job?.cancel();
    _job = null;
    _syncWatch();
  }
}
