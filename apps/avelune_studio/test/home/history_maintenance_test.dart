import 'dart:async';

import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_history_maintenance.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('maintenance previews, cancels and applies without reopening', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = _Sessions();
    final controller = ProjectSessionController(sessions);
    await controller.open('/project');
    final maintenance = _Maintenance();
    var allow = false;
    final busy = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: ProjectSessionScreen(
          session: controller,
          recentProjects: MemoryRecentProjectsAdapter(),
          chooseDirectory: () async => '/other',
          historyMaintenance: maintenance,
          onMaintenanceBusy: busy.add,
          workspaceBuilder: (_, _) => Builder(
            builder: (context) {
              StudioHomeScope.of(context)!.allowSwitch = () async => allow;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('project-history-maintenance'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(maintenance.previews, 0);
    allow = true;
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(maintenance.previews, 1);
    expect(find.textContaining('50 opérations'), findsOneWidget);
    expect(find.textContaining('360 entrées'), findsOneWidget);
    expect(find.textContaining('annulations indépendantes'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(maintenance.applies, 0);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
    await tester.pump();
    expect(maintenance.applies, 1);
    expect(find.text('Entretien de l’historique…'), findsOneWidget);
    expect(sessions.opens, 1);
    expect(sessions.closes, 0);
    maintenance.result.complete(
      const ProjectHistoryMaintenanceResult(
        deletedObjects: 20,
        deletedBytes: 1024 * 1024,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('20 fichiers'), findsOneWidget);
    expect(sessions.opens, 1);
    expect(sessions.closes, 0);
    expect(busy.last, false);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await controller.dispose();
  });

  testWidgets('maintenance errors remain visible and release the busy guard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ProjectSessionController(_Sessions());
    await controller.open('/project');
    final maintenance = _Maintenance()..fail = true;
    final busy = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: ProjectSessionScreen(
          session: controller,
          recentProjects: MemoryRecentProjectsAdapter(),
          chooseDirectory: () async => null,
          historyMaintenance: maintenance,
          onMaintenanceBusy: busy.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('project-history-maintenance')));
    await tester.pumpAndSettle();
    expect(
      find.text('Le projet a changé. Relancez l’analyse.'),
      findsOneWidget,
    );
    expect(busy, [true, false]);
    expect(maintenance.applies, 0);
    await tester.pumpWidget(const SizedBox());
    await controller.dispose();
  });
}

final class _Maintenance implements ProjectHistoryMaintenancePort {
  var previews = 0;
  var applies = 0;
  var fail = false;
  final result = Completer<ProjectHistoryMaintenanceResult>();
  @override
  Future<ProjectHistoryMaintenancePreview> preview(
    ProjectSession session,
  ) async {
    previews++;
    if (fail) {
      throw const ProjectHistoryMaintenanceFailure(
        'Le projet a changé. Relancez l’analyse.',
      );
    }
    return const ProjectHistoryMaintenancePreview(
      revision: 'revision',
      fingerprint: 'fingerprint',
      retainedOperations: 50,
      expiredOperations: 360,
      retainedBytes: 1024 * 1024,
      hasLegacyBarrier: true,
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
    return const ProjectSession(
      sessionId: 'managed',
      name: 'Managed',
      directoryPath: '/project',
      storage: ProjectSessionStorage.workingCatalog,
    );
  }

  @override
  Future<void> close(ProjectSession session) async => closes++;
}
