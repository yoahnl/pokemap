@Timeout(Duration(minutes: 3))
library;

import 'package:avelune_studio/features/cinematics/application/cinematic_library_filter.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_selection_rules.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_timeline_rules.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_workspace_owner_fixture.dart';

void main() {
  late CinematicWorkspaceOwnerFixture owner;
  late CinematicWorkspaceController controller;
  setUp(() async {
    owner = await CinematicWorkspaceOwnerFixture.create();
    controller = owner.controller;
    await owner.open();
  });
  tearDown(() => owner.dispose());

  CinematicAsset asset() => controller.active!.asset;
  List<String> order() => [for (final s in asset().timeline.steps) s.id];

  test(
    'a modifier click toggles steps so several can be deleted together',
    () async {
      final selection = <String>{'walk'};
      toggleCinematicStepSelection(selection, 'fade');
      toggleCinematicStepSelection(selection, 'ending');
      toggleCinematicStepSelection(selection, 'ending');
      expect(selection, {'walk', 'fade'});

      expect(controller.deleteSteps(selection), isTrue);
      expect(order(), ['opening', 'face', 'camera', 'ending']);
      expect(await controller.save(), isTrue, reason: controller.error);
      expect([for (final s in (await owner.reread()).timeline.steps) s.id], [
        'opening',
        'face',
        'camera',
        'ending',
      ]);
    },
  );

  test('a plain click replaces the selection and seeks to the step', () {
    controller.preparePreview();
    final selection = <String>{'walk', 'fade'};
    selectOnlyCinematicStep(selection, controller.transport, 'camera');
    expect(selection, {'camera'});
    final camera = controller.transport.plan!.timelineItems.singleWhere(
      (item) => item.stepId == 'camera',
    );
    expect(camera.startMs, greaterThan(0));
    expect(controller.transport.timeMs, camera.startMs);
  });

  test(
    'reconcile drops deleted steps and falls back to the first actor',
    () {
      final selection = <String>{'walk', 'fade'};
      expect(controller.deleteSteps({'fade'}), isTrue);
      expect(reconcileCinematicSelection(asset(), selection, 'chief'), 'chief');
      expect(selection, {'walk'});
      expect(reconcileCinematicSelection(asset(), selection, 'ghost'), 'hero');
      expect(reconcileCinematicSelection(asset(), selection, null), 'hero');
      final empty = asset().copyWith(requiredActors: const []);
      expect(reconcileCinematicSelection(empty, selection, 'hero'), isNull);
    },
  );

  test('paste lands after the anchor step or at the end without one', () {
    expect(cinematicPasteIndex(asset(), 'walk'), 2);
    expect(cinematicPasteIndex(asset(), null), 6);
    expect(cinematicPasteIndex(asset(), 'missing'), 6);

    final clipboard = controller.copySteps({'opening'})!;
    expect(
      controller.pasteSteps(clipboard, cinematicPasteIndex(asset(), 'walk')),
      isTrue,
      reason: controller.error,
    );
    expect(order().take(2), ['opening', 'walk']);
    expect(asset().timeline.steps[2].kind, CinematicTimelineStepKind.wait);
    expect(order()[2], isNot('opening'));
    expect(order().sublist(3), ['face', 'camera', 'fade', 'ending']);
  });

  test('the library root folder creates cinematics outside any folder', () async {
    expect(cinematicLibraryFolderOrRoot(''), isNull);
    expect(cinematicLibraryFolderOrRoot('dossier'), 'dossier');
    expect(
      await controller.create(
        'Nouvelle scène',
        folderId: cinematicLibraryFolderOrRoot(''),
      ),
      isTrue,
    );
    expect(controller.session(controller.activeId!)?.folderId, isNull);
  });
}
