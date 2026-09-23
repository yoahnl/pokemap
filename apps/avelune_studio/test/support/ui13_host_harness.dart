import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/verification/verification_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart';
import 'ui05_narrative_fixture.dart';
import 'ui13_controllable_verification_port.dart';
import 'ui13_verification_harness.dart';
import 'ui13_widget_verification_port.dart';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 12);
}

VerificationWorkspaceController opened(WidgetTester tester) => tester
    .widget<VerificationWorkspacePage>(find.byType(VerificationWorkspacePage))
    .controller;

/// The real host with the ports the application wires, opened on the report.
Future<Ui13VerificationHarness> host(
  WidgetTester tester, {
  VerificationPort Function(VerificationPort)? wrap,
  bool launch = true,
}) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = (await tester.runAsync(Ui13VerificationHarness.create))!;
  final visuals = (await tester.runAsync(
    () => StudioMapResources.load(project.session, project.maps.project!),
  ))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(project.dispose);
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: MapWorkspaceScreen(
        controller: project.maps,
        loadVisuals: (_, _) async => visuals,
        narrativePort: Ui05NarrativePort(
          LocalNarrativeAdapter(
            session: project.session,
            mapAdapter: project.adapter,
          ),
          tester,
        ),
        scenePort: LocalSceneAdapter(
          session: project.session,
          mapAdapter: project.adapter,
        ),
        storyPort: LocalStoryAdapter(
          session: project.session,
          mapAdapter: project.adapter,
        ),
        dialoguePort: LocalDialogueAdapter(
          session: project.session,
          mapAdapter: project.adapter,
        ),
        worldPort: LocalWorldAdapter(
          session: project.session,
          mapAdapter: project.adapter,
        ),
        verificationPort: (wrap ?? (value) => value)(
          Ui13WidgetVerificationPort(project.port, tester),
        ),
        onClose: () async {},
        registerExitGuard: (_) {},
        runtimeBuilder: (_, _, _) => const SizedBox(),
      ),
    ),
  );
  await pumpIo(tester);
  await activate(
    tester,
    find.descendant(
      of: find.byType(StudioPrimaryNavigation),
      matching: find.byTooltip('Histoire'),
    ),
  );
  await activate(tester, find.text('Ouvrir la vérification').first);
  expect(find.byType(VerificationWorkspacePage), findsOneWidget);
  if (!launch) return project;
  final controller = opened(tester);
  await activate(tester, find.text('Lancer la vérification').first);
  for (var i = 0; i < 40 && controller.report == null; i++) {
    await pumpIo(tester, frames: 3);
  }
  expect(controller.report, isNotNull, reason: controller.error);
  return project;
}

/// The same report plus one diagnostic. The validators produce none for this
/// destination on this fixture; the opening and the return are the real ones.
VerificationReport withExtra(
  VerificationReport report,
  NarrativeProjectDiagnostic extra,
) => VerificationReport(
  requestId: report.requestId,
  savedRevision: report.savedRevision,
  generatedAt: report.generatedAt,
  validatorVersion: report.validatorVersion,
  inputFingerprint: report.inputFingerprint,
  freshnessKey: report.freshnessKey,
  isolateName: report.isolateName,
  project: NarrativeProjectValidationReport(
    diagnostics: [...report.diagnostics, extra],
    mapEventViews: const [],
  ),
  dependencies: report.dependencies,
  dimensions: report.dimensions,
  runtime: report.runtime,
  scope: report.scope,
  limitations: report.limitations,
  blockers: report.blockers,
  exclusions: report.exclusions,
  labels: report.labels,
  drafted: report.drafted,
);

Future<void> openSelected(WidgetTester tester) async {
  await pumpIo(tester, frames: 6);
  await activate(tester, find.text('Ouvrir dans l’éditeur'));
}

/// Keeps the real reads of the adapter and hands the analysis to the
/// controllable executor, so a widget test can hold the calculation open.
class Ui13HostAnalysisPort implements VerificationPort {
  Ui13HostAnalysisPort(this.delegate, this.executor);
  final VerificationPort delegate;
  final Ui13ControllableVerificationPort executor;

  @override
  Future<String> projectRevision() => delegate.projectRevision();

  @override
  Future<List<MapData>> loadMaps() => delegate.loadMaps();

  @override
  Future<List<VerificationDialogueSource>> readDialogueSources(
    List<ProjectDialogueEntry> entries,
  ) => delegate.readDialogueSources(entries);

  @override
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile profile,
  ) => delegate.readRuntimeEvidence(profile);

  @override
  VerificationJob analyse({
    required ProjectManifest project,
    required List<MapData> maps,
    required List<VerificationDialogueSource> sources,
  }) => executor.analyse(project: project, maps: maps, sources: sources);
}
