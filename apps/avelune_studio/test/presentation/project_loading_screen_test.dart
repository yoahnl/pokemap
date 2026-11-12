import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/home/project_loading_screen.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  late ControlledProjectSessionPort sessions;
  late Completer<MapWorkspaceVisuals> visuals;

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> openStudio(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    sessions = ControlledProjectSessionPort();
    visuals = Completer();
    final container = ProviderContainer(
      overrides: [
        projectSessionPortProvider.overrideWithValue(sessions),
        projectDirectoryPickerProvider.overrideWithValue(
          () async => exampleA.directoryPath,
        ),
        mapWorkspacePortProvider(
          exampleA,
        ).overrideWithValue(WorkspaceMemoryPort()),
        workspaceVisualsLoaderProvider.overrideWithValue(
          (session, manifest) => visuals.future,
        ),
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
  }

  String detail(WidgetTester tester, ProjectOpeningPhase phase) => tester
      .widget<Text>(find.byKey(ValueKey('studio-opening-${phase.name}-detail')))
      .data!;

  String percent(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('studio-opening-percent')))
      .data!;

  final seconds = RegExp(r'^\d+,\d s$');

  testWidgets('the loading screen follows every phase until the map shows', (
    tester,
  ) async {
    await openStudio(tester);

    expect(find.byKey(const ValueKey('studio-opening')), findsOneWidget);
    expect(find.byKey(const ValueKey('studio-home')), findsNothing);
    expect(find.text('Ouverture du projet'), findsOneWidget);
    expect(find.text(exampleA.directoryPath), findsOneWidget);
    expect(detail(tester, ProjectOpeningPhase.project), 'En cours…');
    expect(detail(tester, ProjectOpeningPhase.scene), '0 %');
    expect(percent(tester), '0 %');

    sessions.phaseReporters.single!(ProjectOpeningPhase.workshop);
    await tester.pump();
    expect(detail(tester, ProjectOpeningPhase.project), matches(seconds));
    expect(detail(tester, ProjectOpeningPhase.workshop), 'En cours…');
    expect(percent(tester), '16 %');

    sessions.pending.single.complete(exampleA);
    await settle(tester);
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(find.byKey(const ValueKey('studio-opening')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('studio-opening-subtitle')))
          .data,
      exampleA.name,
    );
    expect(detail(tester, ProjectOpeningPhase.workshop), matches(seconds));
    expect(detail(tester, ProjectOpeningPhase.map), matches(seconds));
    expect(detail(tester, ProjectOpeningPhase.resources), 'En cours…');
    expect(percent(tester), '50 %');

    visuals.complete(WorkspaceTestVisuals());
    await settle(tester);
    for (final phase in ProjectOpeningPhase.values) {
      expect(detail(tester, phase), matches(seconds), reason: phase.name);
    }
    expect(percent(tester), '100 %');

    await tester.pump(ProjectLoadingScreen.fadeDuration);
    await tester.pump();
    expect(find.byKey(const ValueKey('studio-opening')), findsNothing);
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
  });

  testWidgets('a failed phase gives way to the builder and its error', (
    tester,
  ) async {
    await openStudio(tester);
    sessions.pending.single.complete(exampleA);
    await settle(tester);

    visuals.completeError(StateError('atlas illisible'));
    await settle(tester);
    expect(detail(tester, ProjectOpeningPhase.resources), 'Échec');

    await tester.pump(ProjectLoadingScreen.fadeDuration);
    await tester.pump();
    expect(find.byKey(const ValueKey('studio-opening')), findsNothing);
    expect(find.textContaining('atlas illisible'), findsOneWidget);
  });

  testWidgets('a refused project returns home with its problem', (
    tester,
  ) async {
    await openStudio(tester);

    sessions.pending.single.completeError(
      const ProjectOpenFailure(ProjectOpenProblem.manifestMissing),
    );
    await settle(tester);

    expect(find.byKey(const ValueKey('studio-opening')), findsNothing);
    expect(find.byKey(const ValueKey('studio-home')), findsOneWidget);
  });
}
