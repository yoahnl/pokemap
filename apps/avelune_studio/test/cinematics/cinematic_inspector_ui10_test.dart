import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_inspector.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
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
            width: 340,
            height: 600,
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
                previewContent: const Text('Diagnostic aperçu fixture'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Finder input(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );

  testWidgets(
    'focused duration commits canonical value and invalid duration is rejected',
    (tester) async {
      final id = controller.addBasic(
        CinematicTimelineBasicBlockKind.wait,
        durationMs: 500,
      )!;
      view.selection.add(id);
      await mount(tester);
      await tester.enterText(input('Durée (ms)'), '1750');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(controller.active!.asset.timeline.steps.last.durationMs, 1750);
      await tester.enterText(input('Durée (ms)'), '-2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(controller.active!.asset.timeline.steps.last.durationMs, 1750);
      expect(view.error, contains('strictement positive'));
      await tester.enterText(input('Durée (ms)'), '1750');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, isNull);
      expect(
        await tester.runAsync(controller.save),
        true,
        reason: controller.error,
      );
      final saved = await tester.runAsync(() => f.adapter().load('a'));
      expect(saved!.asset.timeline.steps.last.durationMs, 1750);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'invalid command number and title remain blocked until corrected',
    (tester) async {
      final id = controller.addCommand(
        CinematicTimelineStepKind.shake,
        durationMs: 600,
      )!;
      view.selection.add(id);
      await mount(tester);
      await tester.enterText(input('Intensité (0 à 1)'), '2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, contains('Valeur invalide'));
      await tester.enterText(input('Intensité (0 à 1)'), '0.5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, isNull);
      view.selection.clear();
      notifier.notifyListeners();
      await tester.pump();
      await tester.enterText(input('Nom de la cinématique'), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, isNotNull);
      expect(controller.active!.asset.title, 'Départ');
      await tester.enterText(input('Nom de la cinématique'), 'Départ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, isNull);
      expect(
        await tester.runAsync(controller.save),
        true,
        reason: controller.error,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'tab transition retains focused title then shows preview diagnostics',
    (tester) async {
      await mount(tester);
      await tester.enterText(input('Nom de la cinématique'), 'Départ renommé');
      await tester.tap(find.text('Aperçu').first);
      await tester.pump();
      expect(controller.active!.asset.title, 'Départ renommé');
      expect(find.text('Diagnostic aperçu fixture'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'camera target and zoom update canonical focus while actor choices preserve identity',
    (tester) async {
      final actor = controller.addActor('Guide')!;
      controller.bindActor(
        CinematicActorBinding(
          actorId: actor,
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      );
      final id = controller.addBasic(
        CinematicTimelineBasicBlockKind.camera,
        durationMs: 700,
        cameraMode: CinematicTimelineCameraMode.focus,
        cameraFocusBinding: CinematicTimelineCameraFocusBinding(
          target: CinematicCameraTargetBinding.sceneCenter(),
          zoomPreset: CinematicCameraZoomPreset.medium,
        ),
      )!;
      view.selection.add(id);
      await mount(tester);
      final select = tester.widget<StudioSelect>(
        find.byWidgetPredicate(
          (w) => w is StudioSelect && w.label == 'Cible caméra',
        ),
      );
      select.onChanged!('actor:$actor');
      await tester.pump();
      final zoom = tester.widget<StudioSelect>(
        find.byWidgetPredicate(
          (w) => w is StudioSelect && w.label == 'Cadrage',
        ),
      );
      zoom.onChanged!('close');
      await tester.pump();
      final focus = cinematicTimelineCameraFocusBindingOf(
        controller.active!.asset.timeline.steps.last,
      )!;
      expect(focus.target.actorId, actor);
      expect(focus.zoomPreset, CinematicCameraZoomPreset.close);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'guided initial placement is nonblocking and map entity role remains explicitly unbound',
    (tester) async {
      final actor = controller.addActor('Guide')!;
      controller.setStagePoint(
        CinematicStagePoint(id: 'start', label: 'Départ', x: 2, y: 3),
      );
      view.actorId = actor;
      view.inspectorTab = 'actors';
      await mount(tester);
      StudioSelect selector(String label) => tester.widget<StudioSelect>(
        find.byWidgetPredicate((w) => w is StudioSelect && w.label == label),
      );
      selector('Position initiale').onChanged!('stagePoint');
      await tester.pump();
      expect(view.error, isNull);
      expect(view.initialPlacementChoice, 'stagePoint');
      selector('Repère initial').onChanged!('start');
      await tester.pump();
      expect(view.initialPlacementChoice, isNull);
      expect(
        controller
            .active!
            .asset
            .stageContext!
            .initialPlacements
            .single
            .stagePointId,
        'start',
      );
      selector('Rôle dans le jeu').onChanged!('mapEntity');
      await tester.pump();
      final binding =
          controller.active!.asset.stageContext!.actorBindings.single;
      expect(binding.kind, CinematicActorBindingKind.mapEntity);
      expect(binding.mapEntityId, isNull);
      expect(selector('Personnage exact').onChanged, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
