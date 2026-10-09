import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> document() =>
    jsonDecode(
          jsonEncode({
            'materials': [{}],
            'textures': [{}, {}],
            'animations': [{}],
            'extras': {
              'aveluneMaterialAnimations': {
                'schemaVersion': 1,
                'clips': [
                  {
                    'name': 'Water',
                    'durationSeconds': 4,
                    'nodeAnimationIndex': 0,
                    'tracks': [
                      {
                        'materialIndex': 0,
                        'durationSeconds': 2,
                        'times': [0, 1, 2],
                        'transforms': [
                          [1, 0, 0, 1, 0, 0],
                          [1, 0, 0, 1, .5, 1],
                          [1, 0, 0, 1, 1, 2],
                        ],
                        'textureIndices': [0, 1, 0],
                        'interpolation': 'LINEAR',
                      },
                    ],
                  },
                ],
              },
            },
          }),
        )
        as Map<String, dynamic>;

Map<String, dynamic> track(Map<String, dynamic> json) =>
    json['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
        as Map<String, dynamic>;

void main() {
  test('does not reinterpret an ordinary GLB as a material animation', () {
    expect(Model3dMaterialAnimations.fromGlbJson({}).clips, isEmpty);
    expect(
      Model3dMaterialAnimations.fromGlbJson({'extras': {}}).clips,
      isEmpty,
    );
  });

  test('samples UV curves linearly and texture changes as steps', () {
    final parsed = Model3dMaterialAnimations.fromGlbJson(document());
    final clip = parsed.clips.single;
    expect(clip.nodeAnimationIndex, 0);
    final curve = clip.tracks.single;
    expect(curve.sample(.5).transform, [1, 0, 0, 1, .25, .5]);
    expect(curve.sample(.999).textureIndex, 0);
    expect(curve.sample(1).textureIndex, 1);
    expect(curve.sample(1.5).transform, [1, 0, 0, 1, .75, 1.5]);
  });

  test(
    'each track loops at its own period and once playback holds its end',
    () {
      final curve = Model3dMaterialAnimations.fromGlbJson(
        document(),
      ).clips.single.tracks.single;
      expect(curve.sample(2.5).transform, curve.sample(.5).transform);
      expect(curve.sample(8.5).transform, curve.sample(.5).transform);
      expect(curve.sample(2).transform, curve.sample(0).transform);
      expect(curve.sample(20, loop: false).transform, [1, 0, 0, 1, 1, 2]);
      expect(() => curve.sample(-1), throwsArgumentError);
      expect(() => curve.sample(double.infinity), throwsArgumentError);
    },
  );

  test(
    'step curves hold the preceding key and never blend texture indices',
    () {
      final json = document();
      track(json)['interpolation'] = 'STEP';
      final curve = Model3dMaterialAnimations.fromGlbJson(
        json,
      ).clips.single.tracks.single;
      expect(curve.sample(.9).transform, [1, 0, 0, 1, 0, 0]);
      expect(curve.sample(1).transform, [1, 0, 0, 1, .5, 1]);
      expect(curve.sample(1.9).textureIndex, 1);
    },
  );

  test('parsing owns immutable keys and ignores later input mutations', () {
    final json = document();
    final parsed = Model3dMaterialAnimations.fromGlbJson(json);
    track(json)['transforms'][0][4] = 100;
    final clip = parsed.clips.single;
    expect(clip.tracks.single.sample(0).transform[4], 0);
    expect(() => parsed.clips.clear(), throwsUnsupportedError);
    expect(
      () => clip.tracks.single.transforms[0][4] = 4,
      throwsUnsupportedError,
    );
  });

  final invalid = <String, void Function(Map<String, dynamic>)>{
    'unknown schema': (j) =>
        j['extras']['aveluneMaterialAnimations']['schemaVersion'] = 2,
    'unknown track field': (j) => track(j)['typo'] = true,
    'invalid material': (j) => track(j)['materialIndex'] = 1,
    'invalid texture': (j) => track(j)['textureIndices'] = [0, 2, 0],
    'invalid node clip': (j) =>
        j['extras']['aveluneMaterialAnimations']['clips'][0]['nodeAnimationIndex'] =
            1,
    'duplicate material target': (j) =>
        j['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'].add(
          jsonDecode(jsonEncode(track(j))),
        ),
    'zero duration': (j) => track(j)['durationSeconds'] = 0,
    'track longer than clip': (j) => track(j)['durationSeconds'] = 5,
    'missing origin': (j) => track(j)['times'] = [.5, 1, 2],
    'decreasing times': (j) => track(j)['times'] = [0, 2, 1],
    'duplicate times': (j) => track(j)['times'] = [0, 1, 1],
    'out of period key': (j) => track(j)['times'] = [0, 1, 3],
    'wrong transform width': (j) => track(j)['transforms'][0] = [1, 0],
    'wrong transform count': (j) => track(j)['transforms'].removeLast(),
    'wrong texture count': (j) => track(j)['textureIndices'] = [0],
    'nonfinite transform': (j) => track(j)['transforms'][0][0] = double.nan,
    'unsupported interpolation': (j) =>
        track(j)['interpolation'] = 'CUBICSPLINE',
    'key budget': (j) => track(j)['times'] = List.filled(65537, 0),
    'clip budget': (j) => j['extras']['aveluneMaterialAnimations']['clips'] =
        List.filled(257, {}),
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      final json = document();
      entry.value(json);
      expect(
        () => Model3dMaterialAnimations.fromGlbJson(json),
        throwsFormatException,
      );
    });
  }
}
