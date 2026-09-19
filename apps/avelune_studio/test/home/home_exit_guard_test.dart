import 'dart:ui' show AppExitResponse;

import 'package:avelune_studio/app/di/home_providers.dart';
import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';

void main() {
  testWidgets('old workspace disposal cannot clear replacement exit guard', (
    tester,
  ) async {
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    addTearDown(session.dispose);
    final first = session.open(exampleA.directoryPath);
    port.pending.single.complete(exampleA);
    await first;
    final lifecycle = <String>[];
    var allowExit = false;
    var guardCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionControllerProvider.overrideWith((ref) => session),
          projectDirectoryPickerProvider.overrideWithValue(() async => null),
          recentProjectsPortProvider.overrideWith(
            (ref) => MemoryRecentProjectsAdapter(),
          ),
        ],
        child: StudioApp(
          workspaceBuilder: (project, close, register) => _GuardWorkspace(
            name: project.sessionId,
            lifecycle: lifecycle,
            register: register,
            guard: () async {
              guardCalls++;
              return allowExit;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final replacement = session.open(exampleB.directoryPath);
    port.pending.last.complete(exampleB);
    await replacement;
    await tester.pumpAndSettle();
    expect(lifecycle, [
      'register:${exampleA.sessionId}',
      'register:${exampleB.sessionId}',
      'dispose:${exampleA.sessionId}',
    ]);
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

class _GuardWorkspace extends StatefulWidget {
  const _GuardWorkspace({
    required this.name,
    required this.lifecycle,
    required this.register,
    required this.guard,
  });

  final String name;
  final List<String> lifecycle;
  final void Function(Future<bool> Function()?) register;
  final Future<bool> Function() guard;

  @override
  State<_GuardWorkspace> createState() => _GuardWorkspaceState();
}

class _GuardWorkspaceState extends State<_GuardWorkspace> {
  @override
  void initState() {
    super.initState();
    widget.lifecycle.add('register:${widget.name}');
    widget.register(widget.guard);
  }

  @override
  void dispose() {
    widget.lifecycle.add('dispose:${widget.name}');
    widget.register(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
