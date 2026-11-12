import 'package:avelune_studio/features/project_session/domain/project_session.dart';

enum ProjectOpeningStepStatus { pending, running, done, skipped, failed }

class ProjectOpeningStep {
  const ProjectOpeningStep({
    this.status = ProjectOpeningStepStatus.pending,
    this.completed = 0,
    this.total,
    this.elapsed,
  });

  final ProjectOpeningStepStatus status;
  final int completed;
  final int? total;
  final Duration? elapsed;

  bool get settled => switch (status) {
    ProjectOpeningStepStatus.done ||
    ProjectOpeningStepStatus.skipped ||
    ProjectOpeningStepStatus.failed => true,
    _ => false,
  };

  double? get fraction => switch ((status, total)) {
    (ProjectOpeningStepStatus.pending, _) => 0,
    (ProjectOpeningStepStatus.running, final total?) when total > 0 =>
      (completed / total).clamp(0.0, 1.0),
    (ProjectOpeningStepStatus.running, _) => null,
    _ => 1,
  };
}

class ProjectOpeningProgress {
  ProjectOpeningProgress({Duration Function()? clock})
    : _clock = clock ?? _stopwatch();

  static Duration Function() _stopwatch() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  final Duration Function() _clock;
  final _steps = {
    for (final phase in ProjectOpeningPhase.values)
      phase: const ProjectOpeningStep(),
  };
  final _startedAt = <ProjectOpeningPhase, Duration>{};
  final _listeners = <void Function()>{};

  ProjectOpeningStep operator [](ProjectOpeningPhase phase) => _steps[phase]!;

  bool get failed => _steps.values.any(
    (step) => step.status == ProjectOpeningStepStatus.failed,
  );

  bool get settled => failed || _steps.values.every((step) => step.settled);

  double get fraction =>
      _steps.values.fold(0.0, (sum, step) => sum + (step.fraction ?? 0)) /
      _steps.length;

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void start(ProjectOpeningPhase phase) {
    if (this[phase].status != ProjectOpeningStepStatus.pending) return;
    _startedAt[phase] = _clock();
    _set(
      phase,
      const ProjectOpeningStep(status: ProjectOpeningStepStatus.running),
    );
  }

  void advance(ProjectOpeningPhase phase) {
    for (final earlier in ProjectOpeningPhase.values.take(phase.index)) {
      if (this[earlier].status == ProjectOpeningStepStatus.running) {
        finish(earlier);
      }
    }
    start(phase);
  }

  void count(ProjectOpeningPhase phase, int completed, int total) {
    final step = this[phase];
    if (step.status != ProjectOpeningStepStatus.running) return;
    if (step.completed == completed && step.total == total) return;
    _set(
      phase,
      ProjectOpeningStep(
        status: ProjectOpeningStepStatus.running,
        completed: completed,
        total: total,
      ),
    );
  }

  void finish(ProjectOpeningPhase phase) =>
      _settle(phase, ProjectOpeningStepStatus.done);

  void skip(ProjectOpeningPhase phase) =>
      _settle(phase, ProjectOpeningStepStatus.skipped);

  void fail(ProjectOpeningPhase phase) =>
      _settle(phase, ProjectOpeningStepStatus.failed);

  void _settle(ProjectOpeningPhase phase, ProjectOpeningStepStatus status) {
    final step = this[phase];
    if (step.settled) return;
    final started = _startedAt[phase];
    _set(
      phase,
      ProjectOpeningStep(
        status: status,
        completed: step.total ?? step.completed,
        total: step.total,
        elapsed: started == null ? null : _clock() - started,
      ),
    );
  }

  void _set(ProjectOpeningPhase phase, ProjectOpeningStep step) {
    _steps[phase] = step;
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }
}
