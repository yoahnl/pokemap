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
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_tabs.dart';
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
    'targeted discard recovers a rejected inspector field and its validation diagnostics',
    (tester) async {
      await mount(tester);
      final before = controller.active!.asset;
      final beforeDisk = await tester.runAsync(
        f.file('project.json').readAsBytes,
      );
      await tester.enterText(input('Nom de la cinématique'), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final inputs = controller.inputsFor('a');
      final field = inputs.field('cinematic-title-a', before.title);
      expect(inputs.error, isNotNull);
      expect(inputs.inspectorError, isNotNull);
      expect(controller.flushEdits!(), isFalse);

      expect(
        controller.discardInputs(
          controller.prepareInputDiscard('a')!,
          confirmed: true,
        ),
        isTrue,
      );
      await tester.pump();

      expect(inputs.field('cinematic-title-a', before.title), same(field));
      expect(
        tester
            .widget<TextField>(input('Nom de la cinématique'))
            .controller!
            .text,
        before.title,
      );
      expect(inputs.error, isNull);
      expect(inputs.inspectorError, isNull);
      expect(controller.error, isNull);
      expect(controller.flushEdits!(), isTrue);
      expect(await tester.runAsync(controller.saveAll), isTrue);
      expect(controller.active!.asset, same(before));
      expect(
        await tester.runAsync(f.file('project.json').readAsBytes),
        beforeDisk,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final duringConfirmation in [false, true]) {
    testWidgets(
      'targeted discard preserves an identical independent inspector error ${duringConfirmation ? 'during confirmation' : 'before confirmation'}',
      (tester) async {
        await mount(tester);
        await tester.enterText(input('Nom de la cinématique'), '');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        final inputs = controller.inputsFor('a');
        final field = inputs.field('cinematic-title-a', 'Départ');
        final fieldError = inputs.error;
        final preparation = controller.prepareInputDiscard('a')!;
        expect(controller.rename(''), isFalse);
        expect(controller.error, fieldError);
        inputs.error = inputs.inspectorError = controller.error;
        if (duringConfirmation) {
          expect(
            controller.discardInputs(preparation, confirmed: true),
            isFalse,
          );
          expect(field.text, '');
          expect(inputs.error, fieldError);
          expect(controller.error, fieldError);
        }

        expect(
          controller.discardInputs(
            controller.prepareInputDiscard('a')!,
            confirmed: true,
          ),
          isTrue,
        );
        await tester.pump();

        expect(field.text, 'Départ');
        expect(field.problem, isNull);
        expect(inputs.error, fieldError);
        expect(inputs.inspectorError, fieldError);
        expect(controller.error, fieldError);
        expect(controller.flushEdits!(), isFalse);
        expect(await tester.runAsync(controller.saveAll), isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final submit in [false, true]) {
    testWidgets(
      'inspector delegates accepted and rejected commits on ${submit ? 'submission' : 'focus loss'} to its input owner',
      (tester) async {
        await mount(tester);
        final inputs = controller.inputsFor('a');
        final field = inputs.field('cinematic-title-a', 'Départ');
        final beforeDisk = await tester.runAsync(
          f.file('project.json').readAsBytes,
        );

        await tester.enterText(input('Nom de la cinématique'), 'Titre accepté');
        if (submit) {
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          tester
              .widget<TextField>(input('Nom de la cinématique'))
              .focusNode!
              .unfocus();
        }
        await tester.pump();

        expect(controller.active!.asset.title, 'Titre accepté');
        expect(inputs.field('cinematic-title-a', 'Titre accepté'), same(field));
        expect(field.pending, isFalse);
        expect(field.problem, isNull);
        expect(inputs.validating, isFalse);
        expect(controller.flushEdits!(), isTrue);
        final accepted = controller.active!.asset;

        await tester.enterText(input('Nom de la cinématique'), '');
        if (submit) {
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          tester
              .widget<TextField>(input('Nom de la cinématique'))
              .focusNode!
              .unfocus();
        }
        await tester.pump();

        expect(controller.active!.asset, same(accepted));
        expect(field.text, '');
        expect(field.pending, isFalse);
        expect(field.problem, isNotNull);
        expect(inputs.inspectorError, isNotNull);
        expect(inputs.validating, isFalse);
        expect(controller.flushEdits!(), isFalse);
        expect(
          controller.discardInputs(
            controller.prepareInputDiscard('a')!,
            confirmed: true,
          ),
          isTrue,
        );
        await tester.pump();

        expect(inputs.field('cinematic-title-a', 'Titre accepté'), same(field));
        expect(field.text, 'Titre accepté');
        expect(inputs.inspectorError, isNull);
        expect(inputs.error, isNull);
        expect(controller.error, isNull);
        expect(controller.flushEdits!(), isTrue);
        expect(controller.active!.asset, same(accepted));
        expect(
          await tester.runAsync(f.file('project.json').readAsBytes),
          beforeDisk,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

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
      expect(
        tester.widget<TextField>(input('Durée (ms)')).controller!.text,
        '-2',
      );
      final rejected = controller.active!.asset;
      final beforeDisk = await tester.runAsync(
        f.file('project.json').readAsBytes,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.flushEdits!(), isFalse);
      expect(await tester.runAsync(controller.saveAll), isFalse);
      expect(controller.active!.asset, rejected);
      expect(view.error, contains('strictement positive'));
      expect(
        await tester.runAsync(f.file('project.json').readAsBytes),
        beforeDisk,
      );
      await mount(tester);
      expect(
        tester.widget<TextField>(input('Durée (ms)')).controller!.text,
        '-2',
      );
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
    'uncommitted focused text remains owned and blocks publication after the inspector is removed',
    (tester) async {
      final id = controller.addBasic(
        CinematicTimelineBasicBlockKind.wait,
        durationMs: 500,
      )!;
      view.selection.add(id);
      await mount(tester);
      final before = controller.active!.asset;
      final beforeDisk = await tester.runAsync(
        f.file('project.json').readAsBytes,
      );
      await tester.enterText(input('Durée (ms)'), 'texte encore focalisé');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.flushEdits!(), isFalse);
      expect(await tester.runAsync(controller.saveAll), isFalse);
      expect(controller.active!.asset, before);
      expect(
        await tester.runAsync(f.file('project.json').readAsBytes),
        beforeDisk,
      );
      await mount(tester);
      expect(
        tester.widget<TextField>(input('Durée (ms)')).controller!.text,
        'texte encore focalisé',
      );
      await tester.enterText(input('Durée (ms)'), '900');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(controller.flushEdits!(), isTrue);
      expect(controller.active!.asset.timeline.steps.last.durationMs, 900);
      expect(await tester.runAsync(controller.save), isTrue);
      final reopened = await tester.runAsync(() => f.adapter().load('a'));
      expect(reopened!.asset.timeline.steps.last.durationMs, 900);
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

  testWidgets('tab transition commits focused title before showing actors', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(input('Nom de la cinématique'), 'Départ renommé');
    await tester.tap(find.text('Acteurs').first);
    await tester.pump();
    expect(controller.active!.asset.title, 'Départ renommé');
    expect(view.inspectorTab, 'actors');
    expect(find.text('Ajouter un acteur'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'tab transition preserves a rejected focused title across actors and properties',
    (tester) async {
      await mount(tester);
      final before = controller.active!.asset;
      final disk = await tester.runAsync(f.file('project.json').readAsBytes);
      await tester.enterText(input('Nom de la cinématique'), '');
      await tester.tap(find.text('Acteurs').first);
      await tester.pump();
      final inputs = controller.inputsFor('a');
      final field = inputs.field('cinematic-title-a', before.title);
      expect(view.inspectorTab, 'actors');
      expect(find.text('Ajouter un acteur'), findsOneWidget);
      expect(field.text, '');
      expect(field.problem, isNotNull);
      expect(inputs.error, isNotNull);
      expect(await tester.runAsync(controller.saveAll), isFalse);
      expect(controller.active!.asset, same(before));
      expect(await tester.runAsync(f.file('project.json').readAsBytes), disk);

      await tester.tap(find.text('Propriétés').first);
      await tester.pump();

      expect(inputs.field('cinematic-title-a', before.title), same(field));
      expect(
        tester
            .widget<TextField>(input('Nom de la cinématique'))
            .controller!
            .text,
        '',
      );
      expect(inputs.error, isNotNull);
      expect(controller.active!.asset, same(before));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'retired inspector preview resolves tabs and content without changing rejected input',
    (tester) async {
      await mount(tester);
      final before = controller.active!.asset;
      final disk = await tester.runAsync(f.file('project.json').readAsBytes);
      await tester.enterText(input('Nom de la cinématique'), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final inputs = controller.inputsFor('a');
      final field = inputs.field('cinematic-title-a', before.title);
      final revision = inputs.revision;
      final error = inputs.error, diagnostic = controller.error;
      expect(error, isNotNull);
      view.inspectorTab = 'preview';
      notifier.notifyListeners();

      await tester.pump();

      final tabs = tester.widget<StudioTabs<String>>(
        find.byType(StudioTabs<String>),
      );
      expect(tabs.selected, 'properties');
      expect(tabs.items.containsKey(tabs.selected), isTrue);
      expect(
        tester
            .widget<TextField>(input('Nom de la cinématique'))
            .controller!
            .text,
        '',
      );
      expect(inputs.field('cinematic-title-a', before.title), same(field));
      expect(inputs.revision, revision);
      expect(inputs.error, error);
      expect(controller.error, diagnostic);
      expect(controller.active!.asset, same(before));
      expect(await tester.runAsync(controller.saveAll), isFalse);
      expect(await tester.runAsync(f.file('project.json').readAsBytes), disk);
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
