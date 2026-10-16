import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> warpWire(Map<String, dynamic> presentation) => {
  'kind': 'warp',
  'destinationMapId': 'cave',
  'warpId': 'arrival',
  'transition': 'mapDefault',
  'presentation': presentation,
};

Map<String, dynamic> imageWire({String mode = 'illustrated'}) => {
  'mode': mode,
  'illustrationElementId': 'cave-picture',
  'fadeOutMs': 300,
  'transferDelayMs': 400,
  'revealMs': 300,
  'illustrationHoldMs': 1000,
  'illustrationFadeMs': 1500,
};

void main() {
  test('warp retains the complete illustrated presentation', () {
    final wire = warpWire(imageWire());
    expect(SceneInteractiveCommand.fromJson(wire).toJson(), wire);
  });

  test('cave entrance keeps its image while exit has no image', () {
    for (final wire in [
      warpWire(imageWire(mode: 'caveEntrance')),
      warpWire({
        'mode': 'caveExit',
        'fadeOutMs': 300,
        'transferDelayMs': 400,
        'revealMs': 300,
      }),
    ]) {
      expect(SceneInteractiveCommand.fromJson(wire).toJson(), wire);
    }
  });

  test('presentation rejects unknown and malformed fields', () {
    for (final wire in [
      {...imageWire(), 'extra': true},
      {...imageWire(), 'mode': 'rubyScript'},
      {...imageWire(), 'fadeOutMs': 300.0},
      {...imageWire(), 'illustrationElementId': ' '},
      {...imageWire(), 'illustrationElementId': null},
    ]) {
      expect(() => SceneInteractiveCommand.fromJson(warpWire(wire)),
          throwsFormatException, reason: '$wire');
    }
  });

  test('presentation rejects unbounded and contradictory timelines', () {
    for (final wire in [
      {...imageWire(), 'fadeOutMs': 0},
      {...imageWire(), 'fadeOutMs': -1},
      {...imageWire(), 'transferDelayMs': 299},
      {...imageWire(), 'transferDelayMs': 10001},
      {...imageWire(), 'revealMs': 0},
      {...imageWire(), 'illustrationFadeMs': 0},
      {...imageWire(), 'illustrationHoldMs': -1},
      {...imageWire(), 'mode': 'fade'},
      {...imageWire(), 'mode': 'caveExit'},
    ]) {
      expect(() => SceneInteractiveCommand.fromJson(warpWire(wire)),
          throwsFormatException, reason: '$wire');
    }
  });

  test('presentation participates in warp identity', () {
    final commands = {
      SceneInteractiveCommand.fromJson(warpWire(imageWire())),
      SceneInteractiveCommand.fromJson(warpWire(imageWire(mode: 'caveEntrance'))),
      SceneInteractiveCommand.fromJson(warpWire({
        ...imageWire(), 'illustrationHoldMs': 1001,
      })),
    };
    expect(commands, hasLength(3));
  });

  test('no-code builder retains the complete bounded presentation', () {
    final payload = buildScenePayloadForNarrativeCommand(
      commandId: NarrativeCommandIds.warp,
      parameters: const {
        'destinationMapId': 'cave', 'warpId': 'arrival',
        'presentationMode': 'illustrated', 'illustrationElementId': 'cave-picture',
        'fadeOutMs': '300', 'transferDelayMs': '400', 'revealMs': '300',
        'illustrationHoldMs': '1000', 'illustrationFadeMs': '1500',
      },
    ) as SceneActionPayload;
    expect(payload.interactiveCommand!.toJson(), warpWire(imageWire()));
  });

  test('no-code builder rejects orphan and malformed presentation fields', () {
    for (final extra in <Map<String, String>>[
      {'illustrationElementId': 'cave-picture'},
      {'presentationMode': 'illustrated', 'illustrationElementId': 'cave-picture', 'fadeOutMs': 'abc'},
      {'presentationMode': 'caveExit', 'illustrationHoldMs': '1000'},
      {'presentationMode': 'fade', 'extra': 'ignored'},
    ]) {
      expect(() => buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.warp, parameters: {
          'destinationMapId': 'cave', 'warpId': 'arrival', ...extra,
        }), throwsFormatException);
    }
  });

  test('warp refuses undeclared command-level presentation suffixes', () {
    for (final key in ['presentationScript', 'escapePoint', 'unknown']) {
      expect(() => SceneInteractiveCommand.fromJson({...warpWire(imageWire()), key: true}), throwsFormatException);
    }
  });
  test('explicit null presentation is rejected', () {
    final wire = warpWire(imageWire())..['presentation'] = null;
    expect(() => SceneInteractiveCommand.fromJson(wire), throwsFormatException);
  });
}
