import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/features/playtest/contracts/studio_playtest_controls.dart';
import 'package:avelune_studio/presentation/features/map_builder/studio_playtest_performance.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

late ControlledProjectSessionPort sessions;
late WorkspaceMemoryPort maps;
late ProviderContainer container;
late List<PlaytestLaunch> launches;
late List<String> calls;
late int runtimes;

Future<void> settle(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> transition(WidgetTester tester) async {
  await settle(tester);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> openShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  sessions = ControlledProjectSessionPort();
  maps = WorkspaceMemoryPort();
  launches = [];
  calls = [];
  runtimes = 0;
  _FakeGameState.status = const StudioPlaytestStatus();
  container = ProviderContainer(
    overrides: [
      projectSessionPortProvider.overrideWithValue(sessions),
      projectDirectoryPickerProvider.overrideWithValue(
        () async => exampleA.directoryPath,
      ),
      mapWorkspacePortProvider(exampleA).overrideWithValue(maps),
      workspaceVisualsLoaderProvider.overrideWithValue(
        (session, manifest) async => WorkspaceTestVisuals(),
      ),
      workspaceRuntimeBuilderProvider.overrideWithValue((session, port) {
        runtimes++;
        return (entry, revision, controls, close) {
          final launch = PlaytestLaunch(entry, revision, controls, close);
          launches.add(launch);
          return _FakeGame(launch, calls);
        };
      }),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: studioTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StudioRoot(),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('studio-home-import')));
  await tester.pump();
  sessions.pending.single.complete(exampleA);
  await settle(tester);
}

StudioButton button(WidgetTester tester, String key) =>
    tester.widget<StudioButton>(find.byKey(ValueKey(key)));

void publish(WidgetTester tester, StudioPlaytestStatus status) {
  _FakeGameState.status = status;
  launches.single.controls.statusChanged();
}

class PlaytestLaunch {
  PlaytestLaunch(this.entry, this.revision, this.controls, this.close);

  final ProjectMapEntry entry;
  final String revision;
  final StudioPlaytestControls controls;
  final VoidCallback close;
}

class _FakeGame extends StatefulWidget {
  const _FakeGame(this.launch, this.calls);

  final PlaytestLaunch launch;
  final List<String> calls;

  @override
  State<_FakeGame> createState() => _FakeGameState();
}

class _FakeGameState extends State<_FakeGame> {
  static var status = const StudioPlaytestStatus();

  @override
  void initState() {
    super.initState();
    widget.launch.controls.attach(
      this,
      status: () => status,
      save: () async => widget.calls.add('save'),
      resume: () async => widget.calls.add('resume'),
      newGame: () async => widget.calls.add('new'),
      togglePause: () async => widget.calls.add('pause'),
      setSpeed: (speed) => widget.calls.add('speed:${speed.multiplier}'),
      toggleDiagonal: () => widget.calls.add('diagonal'),
      requestClose: widget.launch.close,
    );
  }

  @override
  void dispose() {
    widget.launch.controls.detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: ValueKey('fake-game'));
}

class PlaytestPerformance extends StudioPlaytestPerformanceMonitor {
  PlaytestPerformance() : super(active: false);

  StudioPlaytestPerformanceSample? value;

  @override
  StudioPlaytestPerformanceSample? get sample => value;

  void publish(StudioPlaytestPerformanceSample sample) {
    value = sample;
    notifyListeners();
  }
}
