import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Duration now;
  late ProjectOpeningProgress progress;
  late int notifications;

  setUp(() {
    now = Duration.zero;
    progress = ProjectOpeningProgress(clock: () => now);
    notifications = 0;
    progress.addListener(() => notifications++);
  });

  test('every phase starts pending and the whole opening at zero', () {
    for (final phase in ProjectOpeningPhase.values) {
      expect(progress[phase].status, ProjectOpeningStepStatus.pending);
      expect(progress[phase].fraction, 0);
    }
    expect(progress.fraction, 0);
    expect(progress.settled, isFalse);
  });

  test('a finished phase keeps the time it took', () {
    now = const Duration(milliseconds: 100);
    progress.start(ProjectOpeningPhase.map);
    expect(progress[ProjectOpeningPhase.map].fraction, isNull);
    now = const Duration(milliseconds: 1350);
    progress.finish(ProjectOpeningPhase.map);

    final step = progress[ProjectOpeningPhase.map];
    expect(step.status, ProjectOpeningStepStatus.done);
    expect(step.elapsed, const Duration(milliseconds: 1250));
    expect(step.fraction, 1);
    expect(progress.fraction, closeTo(1 / 6, 1e-9));
  });

  test('counted work gives the running phase a real fraction', () {
    progress
      ..start(ProjectOpeningPhase.scene)
      ..count(ProjectOpeningPhase.scene, 3, 12);

    expect(progress[ProjectOpeningPhase.scene].fraction, .25);
    expect(progress.fraction, closeTo(.25 / 6, 1e-9));

    progress.count(ProjectOpeningPhase.palette, 1, 2);
    expect(progress[ProjectOpeningPhase.palette].total, isNull);
  });

  test('advancing finishes the earlier running phases only', () {
    progress
      ..start(ProjectOpeningPhase.project)
      ..start(ProjectOpeningPhase.scene)
      ..advance(ProjectOpeningPhase.workshop);

    expect(
      progress[ProjectOpeningPhase.project].status,
      ProjectOpeningStepStatus.done,
    );
    expect(
      progress[ProjectOpeningPhase.workshop].status,
      ProjectOpeningStepStatus.running,
    );
    expect(
      progress[ProjectOpeningPhase.scene].status,
      ProjectOpeningStepStatus.running,
    );
  });

  test('a settled phase never changes again', () {
    progress
      ..start(ProjectOpeningPhase.palette)
      ..fail(ProjectOpeningPhase.palette);
    final before = notifications;

    progress
      ..finish(ProjectOpeningPhase.palette)
      ..start(ProjectOpeningPhase.palette)
      ..count(ProjectOpeningPhase.palette, 1, 1);

    expect(
      progress[ProjectOpeningPhase.palette].status,
      ProjectOpeningStepStatus.failed,
    );
    expect(notifications, before);
  });

  test('the opening settles when every phase ends or one fails', () {
    for (final phase in ProjectOpeningPhase.values.take(5)) {
      progress
        ..start(phase)
        ..finish(phase);
    }
    expect(progress.settled, isFalse);

    progress.skip(ProjectOpeningPhase.scene);
    expect(progress.settled, isTrue);
    expect(progress.fraction, 1);

    final failing = ProjectOpeningProgress(clock: () => now)
      ..start(ProjectOpeningPhase.resources)
      ..fail(ProjectOpeningPhase.resources);
    expect(failing.failed, isTrue);
    expect(failing.settled, isTrue);
  });
}
