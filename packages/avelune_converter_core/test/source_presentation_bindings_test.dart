import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/interpretation_profile_fixture.dart';

Map<String, Object?> _bindings() => {
      'characterSubstitutions': [
        {
          'requestedCharset': 'RequestedActor',
          'actualCharset': 'AvailableActor',
          'targetSha256': 'a' * 64,
          'reason': 'Explicit alternate presentation'
        }
      ],
      'routedDoorPatterns': [
        {
          'charset': 'SlidingPanel',
          'sha256': 'b' * 64,
          'departurePattern': 1,
          'arrivalPattern': 3
        }
      ],
      'pickupFeedbackByRegion': [
        {
          'regionId': 7,
          'windowskinPinnedAsset': {
            'relativePath': 'Graphics/Windowskins/Window.png',
            'sha256': 'c' * 64
          },
          'iconsByPocket': {
            '2': {
              'relativePath': 'Graphics/Icons/Token.png',
              'sha256': 'd' * 64
            }
          },
          'audioByItemKind': {
            'item': {'relativePath': 'Audio/ME/Found.wav', 'sha256': 'e' * 64}
          }
        }
      ],
      'healingDisplay': {
        'sheets': [
          {
            'asset': {
              'relativePath': 'Graphics/Characters/Display.png',
              'sha256': 'f' * 64
            },
            'pixelWidth': 128,
            'pixelHeight': 96,
            'tileWidth': 32,
            'tileHeight': 24
          }
        ],
        'variants': [
          for (var count = 1; count <= 6; count++)
            {
              'count': count,
              'sheetIndex': 0,
              'frames': [
                {
                  'x': count % 4,
                  'y': count ~/ 4,
                  'width': 1,
                  'height': 1,
                  'durationMs': 90
                }
              ]
            }
        ]
      }
    };

void main() {
  test('presentation mappings persist and change interpretation identity', () {
    final plain = syntheticSourceInterpretationProfile;
    final profile = SourceInterpretationProfile.fromJson(
        {...plain.toJson(), 'presentationBindings': _bindings()});
    expect(profile.toJson()['presentationBindings'], _bindings());
    expect(profile.canonicalHash, isNot(plain.canonicalHash));
    expect(
        SourceInterpretationProfile.fromJson(
                jsonDecode(jsonEncode(profile.toJson())))
            .canonicalHash,
        profile.canonicalHash);
    expect(plain.toJson(), isNot(contains('presentationBindings')));
  });

  test('presentation collections are immutable and refuse inventory overflow',
      () {
    SourceInterpretationProfile profile(int count) =>
        SourceInterpretationProfile.fromJson({
          ...syntheticSourceInterpretationProfile.toJson(),
          'presentationBindings': {
            'characterSubstitutions': [
              for (var i = 0; i < count; i++)
                {
                  'requestedCharset': 'Actor$i',
                  'actualCharset': 'Alternate$i',
                  'targetSha256': 'a' * 64,
                  'reason': 'Selected alternate'
                }
            ]
          }
        });
    final bounded = profile(128).presentationBindings!;
    expect(bounded.characterSubstitutions, hasLength(128));
    expect(
        () => bounded.characterSubstitutions.clear(), throwsUnsupportedError);
    expect(() => profile(129), throwsA(isA<ContractError>()));
    final complete = SourcePresentationBindings.fromJson(_bindings());
    expect(() => complete.pickupFeedbackByRegion.single.iconsByPocket.clear(),
        throwsUnsupportedError);
    expect(
        () => complete.healingDisplay!.variants
            .singleWhere((v) => v.count == 1)
            .frames
            .clear(),
        throwsUnsupportedError);
  });

  test('presentation mappings reject unknown and ambiguous content', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (b) => b['unknown'] = true,
      (b) => b['characterSubstitutions'][0]['actualCharset'] = '../escape',
      (b) => b['characterSubstitutions'][0]['targetSha256'] = 'not-a-hash',
      (b) => b['characterSubstitutions'].add(b['characterSubstitutions'][0]),
      (b) => b['routedDoorPatterns'][0]['departurePattern'] = 4,
      (b) => b['routedDoorPatterns'].add(b['routedDoorPatterns'][0]),
      (b) => b['pickupFeedbackByRegion'].add(b['pickupFeedbackByRegion'][0]),
      (b) => b['pickupFeedbackByRegion'][0]['windowskinPinnedAsset']
          ['relativePath'] = '/absolute.png',
      (b) => b['pickupFeedbackByRegion'][0]['audioByItemKind']['unsupported'] =
          b['pickupFeedbackByRegion'][0]['audioByItemKind']['item'],
      (b) => b['healingDisplay']['variants'][0]['sheetIndex'] = 1,
      (b) => b['healingDisplay']['variants'][0]['frames'][0]['x'] = 4,
      (b) => b['healingDisplay']['variants'][0]['frames'][0]['durationMs'] = 0,
      (b) => b['healingDisplay']['variants'][0]['count'] = 2,
      (b) => b['healingDisplay']['sheets'][0]['pixelWidth'] = 127,
    ]) {
      final bindings =
          jsonDecode(jsonEncode(_bindings())) as Map<String, dynamic>;
      mutate(bindings);
      expect(
          () => SourceInterpretationProfile.fromJson({
                ...syntheticSourceInterpretationProfile.toJson(),
                'presentationBindings': bindings
              }),
          throwsA(isA<ContractError>()));
    }
  });
}
