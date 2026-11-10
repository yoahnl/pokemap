import 'dart:async';

import 'package:avelune_studio/features/project_session/application/project_history_maintenance_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_history_maintenance.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maintenance previews, cancels and applies without reopening', () async {
    final sessions = _Sessions();
    final session = ProjectSessionController(sessions);
    await session.open('/project');
    final port = _Maintenance();
    var allow = false;
    final busy = <bool>[];
    final controller = ProjectHistoryMaintenanceController(
      session: session,
      port: port,
      allowSwitch: () async => allow,
      onBusyChanged: busy.add,
    );
    addTearDown(controller.dispose);
    addTearDown(session.dispose);
    await controller.run(confirm: (_) async => true);
    expect(port.previews, 0);
    allow = true;
    ProjectHistoryMaintenancePreview? observed;
    await controller.run(
      confirm: (preview) async {
        observed = preview;
        return false;
      },
    );
    expect(observed, isNotNull);
    expect(observed!.retainedOperations, 50);
    expect(observed!.expiredOperations, 360);
    expect(observed!.hasLegacyBarrier, isTrue);
    expect(controller.failed, isFalse);
    expect(port.previews, 1);
    expect(port.applies, 0);
    final applying = controller.run(confirm: (_) async => true);
    await Future<void>.delayed(Duration.zero);
    expect(port.applies, 1);
    expect(controller.busy, isTrue);
    expect(controller.applying, isTrue);
    expect(sessions.opens, 1);
    expect(sessions.closes, 0);
    port.result.complete(
      const ProjectHistoryMaintenanceResult(
        deletedObjects: 20,
        deletedBytes: 1024 * 1024,
      ),
    );
    await applying;
    expect(controller.message, contains('20 fichiers'));
    expect(controller.busy, isFalse);
    expect(controller.applying, isFalse);
    expect(sessions.opens, 1);
    expect(sessions.closes, 0);
    expect(busy, [true, false, true, false]);
  });

  test(
    'maintenance errors preserve diagnostic and release the busy guard',
    () async {
      final session = ProjectSessionController(_Sessions());
      await session.open('/project');
      final port = _Maintenance()..fail = true;
      final busy = <bool>[];
      final controller = ProjectHistoryMaintenanceController(
        session: session,
        port: port,
        onBusyChanged: busy.add,
      );
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      await controller.run(confirm: (_) async => true);
      expect(controller.message, 'Le projet a changé. Relancez l’analyse.');
      expect(controller.failed, isTrue);
      expect(busy, [true, false]);
      expect(port.applies, 0);
    },
  );

  test(
    'a changed session after preview prevents confirmation and deletion',
    () async {
      final sessions = _Sessions();
      final session = ProjectSessionController(sessions);
      await session.open('/project');
      final port = _Maintenance()..previewGate = Completer<void>();
      var confirmations = 0;
      final controller = ProjectHistoryMaintenanceController(
        session: session,
        port: port,
      );
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      final pending = controller.run(
        confirm: (_) async {
          confirmations++;
          return true;
        },
      );
      await Future<void>.delayed(Duration.zero);
      await session.open('/replacement');
      port.previewGate!.complete();
      await pending;
      expect(confirmations, 0);
      expect(port.applies, 0);
      expect(controller.busy, isFalse);
      expect(session.state.project!.directoryPath, '/replacement');
    },
  );

  test(
    'a blocked preview cannot apply even when its caller approves',
    () async {
      final session = ProjectSessionController(_Sessions());
      await session.open('/project');
      final port = _Maintenance()..blocked = true;
      final controller = ProjectHistoryMaintenanceController(
        session: session,
        port: port,
      );
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      await controller.run(confirm: (_) async => true);
      expect(port.applies, 0);
      expect(controller.busy, isFalse);
    },
  );
}

final class _Maintenance implements ProjectHistoryMaintenancePort {
  var previews = 0;
  var applies = 0;
  var fail = false;
  var blocked = false;
  Completer<void>? previewGate;
  final result = Completer<ProjectHistoryMaintenanceResult>();

  @override
  Future<ProjectHistoryMaintenancePreview> preview(
    ProjectSession session,
  ) async {
    previews++;
    await previewGate?.future;
    if (fail) {
      throw const ProjectHistoryMaintenanceFailure(
        'Le projet a changé. Relancez l’analyse.',
      );
    }
    return ProjectHistoryMaintenancePreview(
      revision: 'revision',
      fingerprint: 'fingerprint',
      retainedOperations: 50,
      expiredOperations: 360,
      retainedBytes: 1024 * 1024,
      hasLegacyBarrier: true,
      blocked: blocked,
    );
  }

  @override
  Future<ProjectHistoryMaintenanceResult> apply(
    ProjectSession session,
    ProjectHistoryMaintenancePreview preview,
  ) {
    applies++;
    return result.future;
  }
}

final class _Sessions implements ProjectSessionPort {
  var opens = 0;
  var closes = 0;

  @override
  Future<ProjectSession> open(String directoryPath) async {
    opens++;
    return ProjectSession(
      sessionId: 'managed-$opens',
      name: 'Managed',
      directoryPath: directoryPath,
      storage: ProjectSessionStorage.workingCatalog,
    );
  }

  @override
  Future<void> close(ProjectSession session) async => closes++;
}
