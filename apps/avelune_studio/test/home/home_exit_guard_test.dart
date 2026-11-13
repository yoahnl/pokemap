import 'dart:ui' show AppExitResponse;

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/studio_workspace_test_overrides.dart';

void main() {
  testWidgets('old session disposal cannot clear replacement exit guard', (
    tester,
  ) async {
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    addTearDown(session.dispose);
    final first = session.open(exampleA.directoryPath);
    port.pending.single.complete(exampleA);
    await first;
    var allowExit = false;
    var guardCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionControllerProvider.overrideWith((ref) => session),
          ...studioWorkspaceTestOverrides(),
        ],
        child: const StudioApp(),
      ),
    );
    final exitGuard = ProviderScope.containerOf(
      tester.element(find.byType(StudioApp)),
      listen: false,
    ).read(studioExitGuardProvider);
    exitGuard.register(exampleA.sessionId, () async => true);
    final replacement = session.open(exampleB.directoryPath);
    port.pending.last.complete(exampleB);
    await replacement;
    exitGuard.register(exampleB.sessionId, () async {
      guardCalls++;
      return allowExit;
    });
    exitGuard.register(exampleA.sessionId, null);
    await tester.pumpAndSettle();
    expect(await tester.binding.handleRequestAppExit(), AppExitResponse.cancel);
    expect(guardCalls, 1);
    expect(session.disposed, isFalse);
    expect(session.state.project, same(exampleB));
    expect(port.released, [exampleA]);
    allowExit = true;
    expect(await tester.binding.handleRequestAppExit(), AppExitResponse.exit);
    expect(guardCalls, 2);
    expect(session.disposed, isTrue);
    expect(port.released, [exampleA, exampleB]);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
