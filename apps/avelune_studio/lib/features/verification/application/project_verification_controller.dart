import 'package:map_core/map_core_domain.dart';

import '../domain/verification_port.dart';
import 'verification_problems.dart';

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
  ProjectVerificationController({
    required this.port,
    required this.loadProject,
    required this.changed,
  });

  final VerificationPort port;
  final Future<ProjectManifest?> Function() loadProject;
  final void Function() changed;
  var phase = ProjectVerificationPhase.idle;
  var mapsLoaded = 0;
  var mapsTotal = 0;
  Object? failure;
  Duration? elapsed;
  List<VerificationProblem> problems = const [];
  VerificationJob? _job;
  var _run = 0;

  bool get running => const {
    ProjectVerificationPhase.project,
    ProjectVerificationPhase.maps,
    ProjectVerificationPhase.dialogues,
    ProjectVerificationPhase.analysis,
  }.contains(phase);

  Future<void> start() async {
    if (running) return;
    final run = ++_run;
    final watch = Stopwatch()..start();
    bool current() => run == _run;
    void enter(ProjectVerificationPhase next) {
      phase = next;
      changed();
    }

    failure = null;
    mapsLoaded = 0;
    mapsTotal = 0;
    enter(ProjectVerificationPhase.project);
    try {
      final project = await loadProject();
      if (!current()) return;
      if (project == null) {
        throw const VerificationFailure('project-unavailable');
      }
      enter(ProjectVerificationPhase.maps);
      final maps = await port.readMaps(
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
      problems = verificationProblems(analysis.validation, analysis.physical);
      elapsed = watch.elapsed;
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
}
