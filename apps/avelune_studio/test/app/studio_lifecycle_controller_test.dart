import 'package:avelune_studio/app/studio_lifecycle_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/rendering/application/studio_rendering_preferences.dart';
import 'package:avelune_studio/platform/mcp/studio_mcp_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../platform/mcp/studio_mcp_service_test.dart' show FakeStudioMcpProcess;
import '../support/controlled_project_session_port.dart';

void main() {
  late ControlledProjectSessionPort port;
  late ProjectSessionController session;
  late FakeStudioMcpProcess process;
  late StudioMcpService mcp;
  late StudioRenderingPreferences preferences;
  late StudioLifecycleController lifecycle;

  setUp(() {
    port = ControlledProjectSessionPort();
    session = ProjectSessionController(port);
    process = FakeStudioMcpProcess();
    mcp = StudioMcpService(launch: () async => process);
    preferences = StudioRenderingPreferences(MemoryRenderingPreferencesStore());
    lifecycle = StudioLifecycleController(
      session: session,
      mcp: mcp,
      renderingPreferences: preferences,
    );
  });

  tearDown(() async {
    process.failShutdown = false;
    await lifecycle.close();
    mcp.dispose();
    preferences.dispose();
  });

  Future<void> start() async {
    final starting = lifecycle.start();
    await Future<void>.delayed(Duration.zero);
    process.ready();
    await starting;
  }

  test('busy creation and maintenance keep MCP and session alive', () async {
    await start();
    expect(preferences.loaded, isTrue);
    lifecycle.setCreatorVisible(true);
    expect(await lifecycle.prepareForExit(), isFalse);
    expect(await lifecycle.prepareForUpdate(), isFalse);
    lifecycle.setCreatorVisible(false);
    lifecycle.setHistoryMaintenanceBusy(true);
    expect(await lifecycle.prepareForExit(), isFalse);
    expect(process.shutdowns, 0);
    expect(session.disposed, isFalse);
    lifecycle.setHistoryMaintenanceBusy(false);
    expect(await lifecycle.prepareForExit(), isTrue);
    expect(process.shutdowns, 1);
    expect(session.disposed, isTrue);
  });

  test(
    'failed MCP shutdown refuses restart and preserves open project',
    () async {
      await start();
      final opening = session.open(exampleA.directoryPath);
      port.pending.single.complete(exampleA);
      await opening;
      process.failShutdown = true;
      expect(await lifecycle.prepareForUpdate(), isFalse);
      expect(session.disposed, isFalse);
      expect(session.state.project, same(exampleA));
      expect(port.released, isEmpty);
    },
  );

  test(
    'closing twice disposes session and releases its project once',
    () async {
      await start();
      final opening = session.open(exampleA.directoryPath);
      port.pending.single.complete(exampleA);
      await opening;
      await lifecycle.close();
      await lifecycle.close();
      expect(session.disposed, isTrue);
      expect(port.released, [exampleA]);
      expect(process.shutdowns, 1);
      expect(mcp.state, StudioMcpState.stopped);
      expect(() => session.open(exampleB.directoryPath), throwsStateError);
    },
  );
}
