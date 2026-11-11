import 'package:avelune_studio/features/events/application/event_map_loader.dart';
import '../support/map_workspace_fixture.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_library.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_inspector.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import '../support/cinematic_adapter_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late CinematicWorkspaceController controller;
  setUp(() async {
    f = await CinematicAdapterFixture.create(
      cinematics: [CinematicAdapterFixture.asset('a')],
    );
    await f.writeManifest(
      (await f.readManifest()).copyWith(
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          customAnimationDefinitions: [
            CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Saluer',
              mode: CharacterCustomAnimationMode.single,
            ),
          ],
        ),
      ),
    );
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    maps.project = (await f.readManifest());
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    controller = CinematicWorkspaceController(
      narrative,
      f.adapter(),
      changed: () {},
    );
    await controller.open('a');
  });
  tearDown(() async {
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    await f.dispose();
  });

  testWidgets(
    'typed animation inspector edits repeat count and retains invalid input diagnostic',
    (tester) async {
      final actor = controller.addActor('Guide')!;
      final id = controller.addAnimation(
        CharacterCustomAnimationRuntimeCommand(
          actorId: actor,
          definitionId: 'wave',
        ),
      )!;
      final view = CinematicViewState()..selection.add(id);
      Future<void> mount() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 650,
              child: CinematicInspector(
                controller: controller,
                view: view,
                changed: () {},
                model: null,
                onDialogue: (_) {},
                onLocate: (_) async => null,
              ),
            ),
          ),
        ),
      );
      await mount();
      final selector = tester.widget<StudioSelect>(
        find.byWidgetPredicate(
          (w) => w is StudioSelect && w.label == 'Lecture de l’animation',
        ),
      );
      selector.onChanged!('repeatCount');
      await mount();
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Répétitions',
      );
      await tester.enterText(field, '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, contains('strictement positive'));
      await tester.enterText(field, '4');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, isNull);
      expect(
        cinematicCharacterCustomAnimationCommandOf(
          controller.active!.asset.timeline.steps.last,
        )!.playback.repeatCount,
        4,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      view.dispose();
    },
  );

  testWidgets(
    'two unpublished drafts remain visible in their selected folder',
    (tester) async {
      final before = await tester.runAsync(
        () => f.file('project.json').readAsBytes(),
      );
      maps.project = maps.project!.copyWith(
        cinematicLibraryCatalog: CinematicLibraryCatalog(
          folders: [
            CinematicLibraryFolder(
              id: 'intro',
              family: CinematicLibraryFamily.world,
              name: 'Introduction',
              sortOrder: 0,
            ),
          ],
        ),
      );
      await controller.create('Introduction sur carte', folderId: 'intro');
      final first = controller.activeId!;
      await controller.duplicate(first);
      final second = controller.activeId!;
      expect(controller.session(first)!.folderId, 'intro');
      expect(controller.session(second)!.folderId, 'intro');
      final views = CinematicViewStore()..folderId = 'intro';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 650,
              child: CinematicLibrary(
                loader: EventMapLoader(maps),
                visuals: WorkspaceTestVisuals(),
                controller: controller,
                views: views,
                changed: () {},
                onOpen: (_) {},
                onCreate: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(ValueKey('cinematic-library-$first')), findsOneWidget);
      expect(find.byKey(ValueKey('cinematic-library-$second')), findsOneWidget);
      expect(
        await tester.runAsync(() => f.file('project.json').readAsBytes()),
        before,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      views.dispose();
    },
  );


}
