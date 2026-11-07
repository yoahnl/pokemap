import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_inspector.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_preview_status.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late CinematicWorkspaceController controller;
  late CinematicViewState view;
  late ChangeNotifier notifier;
  setUp(() async {
    f = await CinematicAdapterFixture.create(
      cinematics: [CinematicAdapterFixture.asset('a')],
    );
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    notifier = ChangeNotifier();
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    controller = CinematicWorkspaceController(
      narrative,
      f.adapter(),
      changed: notifier.notifyListeners,
    );
    view = CinematicViewState();
    await controller.open('a');
  });
  tearDown(() async {
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    view.dispose();
    notifier.dispose();
    await f.dispose();
  });

  Future<void> mount(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 380,
            height: 900,
            child: ListenableBuilder(
              listenable: notifier,
              builder: (_, _) => CinematicInspector(
                controller: controller,
                view: view,
                changed: notifier.notifyListeners,
                model: null,
                onDialogue: (_) {},
                onLocate: (_) async => null,
                onAdd: (_) {},
                previewContent: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'Properties without a selected action explains how to choose one',
    (tester) async {
      await mount(tester);
      expect(
        find.byKey(const ValueKey('cinematic-no-action-guidance')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('cinematic-title-a')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Sequence lists the actions in order and opens their properties',
    (tester) async {
      view.inspectorTab = 'document';
      await mount(tester);
      expect(
        find.byKey(const ValueKey('cinematic-no-action-guidance')),
        findsNothing,
      );
      final row = find.byKey(const ValueKey('cinematic-sequence-step-a.wait'));
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pump();
      expect(view.stepId, 'a.wait');
      expect(view.inspectorTab, 'properties');
      expect(
        find.byKey(const ValueKey('cinematic-no-action-guidance')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('identical diagnostics are grouped with their targets', () {
    CinematicPreviewPlaybackDiagnostic diagnostic(
      String message, {
      String? step,
      String? actor,
      bool blocking = false,
    }) => CinematicPreviewPlaybackDiagnostic(
      code: CinematicPreviewPlaybackDiagnosticCode
          .cinematicPreviewPlaybackMoveDestinationMissing,
      severity: blocking
          ? CinematicPreviewPlaybackDiagnosticSeverity.error
          : CinematicPreviewPlaybackDiagnosticSeverity.warning,
      message: message,
      stepId: step,
      actorId: actor,
      blocking: blocking,
    );
    final groups = groupCinematicDiagnostics([
      diagnostic('Destination introuvable', step: 's1', blocking: true),
      diagnostic('Durée indicative', step: 's2'),
      diagnostic('Destination introuvable', step: 's3', blocking: true),
      diagnostic('Destination introuvable', step: 's1', blocking: true),
      diagnostic('Durée indicative', actor: 'mother'),
    ]);
    expect(groups, hasLength(2));
    expect(groups.first.message, 'Destination introuvable');
    expect(groups.first.blocking, isTrue);
    expect(groups.first.count, 3);
    expect(groups.first.stepIds, ['s1', 's3']);
    expect(groups.last.stepIds, ['s2']);
    expect(groups.last.actorIds, ['mother']);
    expect(
      cinematicDiagnosticSummary(groups),
      'Lecture possible mais incomplète : 1 problème à corriger, 1 avertissement.',
    );
  });

  testWidgets('a camera action states its scope apart from the game camera', (
    tester,
  ) async {
    final seeded = addCinematicTimelineBasicBlockStep(
      ProjectManifest(
        name: 'P',
        maps: const [],
        tilesets: const [],
        cinematics: [CinematicAdapterFixture.asset('cam')],
      ),
      cinematicId: 'cam',
      blockKind: CinematicTimelineBasicBlockKind.camera,
    );
    final camera = await tester.runAsync(
      () => CinematicAdapterFixture.create(cinematics: [seeded.cinematic]),
    );
    final mapsCam = MapWorkspaceController(camera!.session, camera.maps);
    final narrativeCam = NarrativeWorkspaceController(
      mapsCam,
      LocalNarrativeAdapter(session: camera.session, mapAdapter: camera.maps),
      () {},
      (_, _) async {},
    );
    final controllerCam = CinematicWorkspaceController(
      narrativeCam,
      camera.adapter(),
      changed: notifier.notifyListeners,
    );
    final viewCam = CinematicViewState();
    addTearDown(() async {
      controllerCam.dispose();
      narrativeCam.dispose();
      mapsCam.dispose();
      viewCam.dispose();
      await tester.runAsync(camera.dispose);
    });
    await tester.runAsync(() async {
      await mapsCam.initialize();
      await controllerCam.open('cam');
    });
    viewCam.selection.add(seeded.step.id);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 1200,
            child: CinematicInspector(
              controller: controllerCam,
              view: viewCam,
              changed: () {},
              model: null,
              onDialogue: (_) {},
              onLocate: (_) async => null,
              onAdd: (_) {},
              previewContent: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    final scope = find.byKey(const ValueKey('cinematic-camera-scope'));
    await tester.ensureVisible(scope);
    expect(scope, findsOneWidget);
    expect(
      tester.widget<Text>(scope).data,
      contains('ni la caméra enregistrée de la carte'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
