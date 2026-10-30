import 'dart:ui' show AppExitResponse;

import 'package:avelune_studio/app/di/home_providers.dart';
import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/di/studio_mcp_providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/updates/studio_update_host.dart';
import 'package:avelune_studio/platform/mcp/studio_mcp_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/controlled_project_session_port.dart';
import 'studio_mcp_service_test.dart' show FakeStudioMcpProcess;

void main() {
  testWidgets(
    'home starts once and preserves its process through cancelled exit',
    (tester) async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final process = FakeStudioMcpProcess();
      var launches = 0;
      var allowExit = false;
      final service = StudioMcpService(
        launch: () async {
          launches++;
          return process;
        },
      );
      addTearDown(service.dispose);
      addTearDown(session.dispose);
      Widget app() => ProviderScope(
        overrides: [
          studioMcpServiceProvider.overrideWithValue(service),
          projectSessionControllerProvider.overrideWithValue(session),
          projectDirectoryPickerProvider.overrideWithValue(() async => null),
          recentProjectsPortProvider.overrideWith(
            (ref) => MemoryRecentProjectsAdapter(),
          ),
        ],
        child: StudioApp(
          workspaceBuilder: (project, close, register) {
            register(() async => allowExit);
            return const SizedBox();
          },
        ),
      );
      await tester.pumpWidget(app());
      expect(find.byTooltip('Connexion aux assistants'), findsOneWidget);
      expect(service.state, StudioMcpState.starting);
      process.ready();
      await tester.pump();
      expect(service.state, StudioMcpState.ready);
      expect(process.commands.single['roots'], isEmpty);
      await tester.pumpWidget(app());
      expect(launches, 1);
      final opening = session.open(exampleA.directoryPath);
      port.pending.single.complete(exampleA);
      await opening;
      await tester.pumpAndSettle();
      expect(process.commands.last['roots'], [exampleA.directoryPath]);
      expect(
        await tester.binding.handleRequestAppExit(),
        AppExitResponse.cancel,
      );
      expect(service.state, StudioMcpState.ready);
      expect(process.shutdowns, 0);
      allowExit = true;
      expect(
        await tester.runAsync(tester.binding.handleRequestAppExit),
        AppExitResponse.exit,
      );
      expect(process.shutdowns, 1);
      expect(service.state, StudioMcpState.stopped);
      expect(session.disposed, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'update preparation preserves the session when installation is aborted',
    (tester) async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final process = FakeStudioMcpProcess();
      final resumed = FakeStudioMcpProcess();
      var launches = 0;
      final service = StudioMcpService(
        launch: () async => launches++ == 0 ? process : resumed,
      );
      addTearDown(service.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studioMcpServiceProvider.overrideWithValue(service),
            projectSessionControllerProvider.overrideWithValue(session),
            projectDirectoryPickerProvider.overrideWithValue(() async => null),
            recentProjectsPortProvider.overrideWith(
              (ref) => MemoryRecentProjectsAdapter(),
            ),
          ],
          child: const StudioApp(),
        ),
      );
      process.ready();
      await tester.pump();
      final update = tester.widget<StudioUpdateHost>(
        find.byType(StudioUpdateHost),
      );
      expect(await tester.runAsync(update.onRestartRequested), isTrue);
      expect(process.shutdowns, 1);
      expect(session.disposed, isFalse);
      expect(service.state, StudioMcpState.stopped);
      await tester.runAsync(() async {
        final restarting = update.onRestartAborted!();
        await Future<void>.delayed(Duration.zero);
        resumed.ready();
        await restarting;
      });
      expect(launches, 2);
      expect(service.state, StudioMcpState.ready);
      expect(session.disposed, isFalse);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
