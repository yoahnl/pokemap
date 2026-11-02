import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final frame = <String, dynamic>{
    'source': {'x': 0, 'y': 0, 'width': 32, 'height': 56},
    'durationMs': 100,
  };
  final system = <String, dynamic>{
    'state': 'surf_idle',
    'direction': 'south',
    'sourceAssetId': 'surf-source',
    'frames': [frame],
  };
  final custom = <String, dynamic>{
    'definitionId': 'floating',
    'sourceAssetId': 'surf-source',
    'frames': [frame],
    'loop': true,
  };

  test('legacy system and custom clip JSON remain byte-identical', () {
    expect(
      jsonEncode(CharacterAnimation.fromJson(system).toJson()),
      jsonEncode(system),
    );
    expect(
      jsonEncode(CharacterCustomAnimationClip.fromJson(custom).toJson()),
      jsonEncode(custom),
    );
    expect(
      CharacterAnimation.fromJson({
        ...system,
        'presentationReferenceHeightPx': null,
      }).toJson(),
      system,
    );
    expect(
      CharacterCustomAnimationClip.fromJson({
        ...custom,
        'presentationReferenceHeightPx': null,
      }).toJson(),
      custom,
    );
  });

  for (final row in [('system', system), ('custom', custom)]) {
    Map<String, dynamic> roundTrip(Map<String, dynamic> json) =>
        row.$1 == 'system'
        ? CharacterAnimation.fromJson(json).toJson()
        : CharacterCustomAnimationClip.fromJson(json).toJson();

    test('${row.$1} clip retains an explicit canvas reference', () {
      final json = {...row.$2, 'presentationReferenceHeightPx': 32};
      expect(roundTrip(json), json);
    });

    for (final value in <Object>[0, -1, 8193, 32.5, '32', true, 57]) {
      test('${row.$1} codec rejects invalid reference $value', () {
        expect(
          () => roundTrip({...row.$2, 'presentationReferenceHeightPx': value}),
          throwsFormatException,
        );
      });
    }

    test('${row.$1} codec requires dedicated source and frames', () {
      for (final source in [null, '', '   ']) {
        expect(
          () => roundTrip({
            ...row.$2,
            'sourceAssetId': source,
            'presentationReferenceHeightPx': 32,
          }),
          throwsA(anything),
        );
      }
      expect(
        () => roundTrip({
          ...row.$2,
          'frames': <Object>[],
          'presentationReferenceHeightPx': 32,
        }),
        throwsFormatException,
      );
    });

    test('${row.$1} reference fits every frame', () {
      final short = <String, dynamic>{
        'source': {'x': 0, 'y': 0, 'width': 32, 'height': 31},
        'durationMs': 100,
      };
      expect(
        () => roundTrip({
          ...row.$2,
          'frames': [frame, short],
          'presentationReferenceHeightPx': 32,
        }),
        throwsFormatException,
      );
    });

    test('${row.$1} codec accepts bounded inclusive references', () {
      for (final height in [1, 56, 8192]) {
        final fitting = {
          'source': {'x': 0, 'y': 0, 'width': 32, 'height': height},
          'durationMs': 100,
        };
        final json = {
          ...row.$2,
          'frames': [fitting],
          'presentationReferenceHeightPx': height,
        };
        expect(roundTrip(json), json);
      }
    });
  }

  test('capability is required only for clips with an explicit reference', () {
    final project = ProjectManifest(
      name: 'Canvas',
      maps: [],
      tilesets: [],
      characters: [
        ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'sheet'),
      ],
    );
    expect(
      CharacterAnimationCanvasCapabilities.requiresCapability(project),
      isFalse,
    );
    expect(
      CharacterAnimationCanvasCapabilities.capabilityId,
      'character.animation-canvas@1',
    );
    for (final customClip in [false, true]) {
      final character = project.characters.single.copyWith(
        animations: customClip
            ? []
            : [
                CharacterAnimation.fromJson({
                  ...system,
                  'presentationReferenceHeightPx': 32,
                }),
              ],
        customAnimations: customClip
            ? [
                CharacterCustomAnimationClip.fromJson({
                  ...custom,
                  'presentationReferenceHeightPx': 32,
                }),
              ]
            : [],
      );
      expect(
        CharacterAnimationCanvasCapabilities.requiresCapability(
          project.copyWith(characters: [character]),
        ),
        isTrue,
      );
    }
  });

  test(
    'project validator rejects invalid directly constructed canvas clips',
    () {
      for (final reference in [0, 8193, 57]) {
        final project = ProjectManifest(
          name: 'Canvas',
          maps: [],
          tilesets: [
            ProjectTilesetEntry(
              id: 'sheet',
              name: 'Sheet',
              relativePath: 'sheet.png',
            ),
          ],
          characters: [
            ProjectCharacterEntry(
              id: 'hero',
              name: 'Hero',
              tilesetId: 'sheet',
              animations: [
                CharacterAnimation(
                  state: CharacterAnimationState.surf,
                  direction: EntityFacing.south,
                  sourceAssetId: 'surf-source',
                  presentationReferenceHeightPx: reference,
                  frames: [CharacterAnimationFrame.fromJson(frame)],
                ),
              ],
            ),
          ],
        );
        expect(
          () => ProjectValidator.validate(project),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'character_studio.animation.canvas_reference_invalid',
            ),
          ),
        );
      }
    },
  );
}
