import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('scene music selection filters assets and clears incompatible operation fields', () {
    final project = ProjectManifest(
      name: 'Musique',
      maps: [],
      tilesets: [],
      cinematicMediaAssets: [
        CinematicMediaAsset(
          id: 'theme',
          label: 'Thème musical',
          kind: CinematicMediaAssetKind.music,
          relativePath: 'audio/theme.ogg',
        ),
        CinematicMediaAsset(
          id: 'sound',
          label: 'Son à exclure',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'audio/sound.ogg',
        ),
      ],
    );
    final draft = SceneActionDraft(
      project: project,
      changed: () {},
      current: SceneActionPayload.interactive(
        SceneInteractiveCommand.sceneMusic(
          operation: SceneMusicOperation.play,
          mediaAssetId: 'theme',
          volume: .8,
        ),
      ),
    );
    addTearDown(draft.dispose);
    Map<String, String> options(String id) => draft.options(
      draft.command!.parameters.singleWhere((field) => field.id == id).kind,
    );
    Map<String, dynamic> command() =>
        (draft.buildPayload() as SceneActionPayload).interactiveCommand!
            .toJson();
    expect(options('operation').keys, [
      'play',
      'restore',
      'fadeOut',
      'stop',
      'memorize',
      'restoreMemorized',
    ]);
    expect(options('mediaAssetId'), {'theme': 'Thème musical'});
    expect(command(), {
      'kind': 'sceneMusic',
      'operation': 'play',
      'mediaAssetId': 'theme',
      'volume': .8,
    });
    draft.changeParameter('channel', 'ambience');
    draft.changeParameter('scope', 'map');
    expect(command(), {
      'kind': 'sceneMusic',
      'operation': 'play',
      'channel': 'ambience',
      'scope': 'map',
      'mediaAssetId': 'theme',
      'volume': .8,
    });
    draft.changeParameter('channel', 'music');
    draft.changeParameter('scope', 'scene');
    draft.changeParameter('operation', 'restore');
    expect(draft.values['mediaAssetId'], isNull);
    expect(command(), {'kind': 'sceneMusic', 'operation': 'restore'});
    draft.changeParameter('operation', 'fadeOut');
    draft.changeParameter('durationMs', '60001');
    expect(draft.valid, isFalse);
    draft.changeParameter('durationMs', '0');
    expect(command(), {
      'kind': 'sceneMusic',
      'operation': 'fadeOut',
      'durationMs': 0,
    });
    draft.changeParameter('operation', 'memorize');
    draft.changeParameter('channel', 'both');
    expect(command(), {
      'kind': 'sceneMusic',
      'operation': 'memorize',
      'channel': 'both',
      'scope': 'scene',
    });
    draft.changeParameter('operation', 'stop');
    expect(draft.values['channel'], 'music');
    expect(options('channel'), isNot(contains('both')));
  });
}
