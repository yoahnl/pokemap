import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final kind in ['playSoundEffect', 'playMusicEffect']) {
    test('$kind retains explicit natural completion policy', () {
      final json = <String, dynamic>{
        'kind': kind,
        'mediaAssetId': 'cue',
        'volume': .5,
        'waitForCompletion': true,
        if (kind == 'playMusicEffect')
          'bgmInterruption': {'fadeOutMs': 100, 'fadeInMs': 100},
      };
      final command = SceneInteractiveCommand.fromJson(json);
      expect(command.toJson()['waitForCompletion'], true);
      final id = kind == 'playSoundEffect'
          ? NarrativeCommandIds.playSoundEffect
          : NarrativeCommandIds.playMusicEffect;
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: id,
                parameters: {
                  'mediaAssetId': 'cue',
                  'volume': '.5',
                  'waitForCompletion': 'true',
                  if (kind == 'playMusicEffect') ...{
                    'fadeOutMs': '100',
                    'fadeInMs': '100',
                  },
                },
              )
              as SceneActionPayload;
      expect(payload.interactiveCommand!.toJson()['waitForCompletion'], true);
      expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    });
    test('$kind rejects a non boolean completion policy', () {
      expect(
        () => SceneInteractiveCommand.fromJson({
          'kind': kind,
          'mediaAssetId': 'cue',
          'volume': .5,
          'waitForCompletion': 'true',
          if (kind == 'playMusicEffect')
            'bgmInterruption': {'fadeOutMs': 100, 'fadeInMs': 100},
        }),
        throwsFormatException,
      );
    });
  }
}
