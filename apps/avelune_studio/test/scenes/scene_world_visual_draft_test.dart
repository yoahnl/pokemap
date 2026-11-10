import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_world_visual_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'scene atmosphere preserves explicit authored time and weather modes',
    () {
      final settings = SpatialVisualPatch.fromJson({
        'timeMode': 'fixed',
        'minuteOfDay': 1320,
        'weatherMode': 'fixed',
        'weatherKind': 'storm',
      });
      final command = SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.atmosphere,
        visualSettings: settings,
        scope: SceneVisualScope.scene,
      );
      final draft = SceneWorldVisualDraft(
        current: SceneActionPayload.interactive(command),
        changed: () {},
      );
      addTearDown(draft.dispose);
      expect(draft.visual.choice(SpatialVisualParameter.timeMode), 'fixed');
      expect(draft.visual.choice(SpatialVisualParameter.weatherMode), 'fixed');
      expect(
        (draft.payload as SceneActionPayload).interactiveCommand!.toJson(),
        command.toJson(),
      );
    },
  );

  test(
    'an existing picture operation retains its slot and explicit scene scope',
    () {
      final command = SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.erasePicture,
        slotId: 7,
        scope: SceneVisualScope.scene,
      );
      final draft = SceneWorldVisualDraft(
        current: SceneActionPayload.interactive(command),
        changed: () {},
      );
      addTearDown(draft.dispose);
      expect(draft.operation, 'erasePicture');
      expect(draft.values['scope'], 'scene');
      expect(
        (draft.payload as SceneActionPayload).interactiveCommand!.toJson(),
        command.toJson(),
      );
    },
  );

  test('a late catalogue cannot supply images after disposal', () async {
    final media = Completer<ProjectMediaCatalog>();
    var changes = 0;
    final draft = SceneWorldVisualDraft(
      current: null,
      changed: () => changes++,
      loadVisualMedia: () => media.future,
    );
    final pending = draft.reloadMedia();
    draft.dispose();
    media.complete(
      ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'image',
            label: 'Image',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'source',
          ),
        ],
      ),
    );
    await pending;
    expect(draft.images, isEmpty);
    expect(draft.payload, isNull);
    expect(changes, 0);
  });
}
