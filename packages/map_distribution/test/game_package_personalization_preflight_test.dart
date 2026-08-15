import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('GamePackagePersonalizationPreflight', () {
    const preflight = GamePackagePersonalizationPreflight();

    test('certifies hashes, codecs, licenses, and referenced assets', () {
      final inspection = _validInspection();

      final receipt = preflight.certify(inspection);

      expect(receipt.gameId, 'games.example.personalized');
      expect(receipt.treeSha256, inspection.manifest.content.treeSha256);
      expect(receipt.packageSha256, inspection.receipt.packageSha256);
      expect(receipt.presentationSha256, hasLength(64));
      expect(
        receipt.configuredCategories,
        <GamePackagePersonalizationCategory>[
          GamePackagePersonalizationCategory.branding,
          GamePackagePersonalizationCategory.intro,
          GamePackagePersonalizationCategory.typography,
          GamePackagePersonalizationCategory.theme,
        ],
      );
      expect(receipt.videoCodec, 'h264');
      expect(receipt.audioCodec, 'aac');
      expect(
        receipt.assetSha256.keys,
        containsAll(<String>[
          'presentation/icon.png',
          'project/assets/title.ogg',
          'presentation/intro/video.mp4',
          'presentation/intro/poster.png',
          'presentation/intro/captions.vtt',
          'presentation/fonts/display.ttf',
          'presentation/fonts/display-license.txt',
        ]),
      );
      expect(receipt.toJson()['receiptVersion'], 1);
    });

    test('certifies every responsive intro and title-motion variant', () {
      final built = const GamePackageBuilder().build(
        manifest: _manifestV2(content: _emptyContent),
        payloadFiles: _validPayloadV2(),
      );

      final receipt = preflight.certify(
        const GamePackageInspector().inspect(built.packageBytes),
      );

      expect(
        receipt.assetSha256.keys,
        containsAll(<String>[
          'presentation/intro/landscape/video.mp4',
          'presentation/intro/portrait/video.mp4',
          'presentation/title/prompt/landscape/video.mp4',
          'presentation/title/prompt/portrait/video.mp4',
          'presentation/title/menu/landscape/video.mp4',
          'presentation/title/menu/portrait/video.mp4',
        ]),
      );
      expect(receipt.videoCodec, 'h264');
      expect(receipt.audioCodec, 'aac');
    });

    test('certifies a window-only profile and binds style changes to its hash',
        () {
      final first = const GamePackageBuilder().build(
        manifest: _windowOnlyManifest(cornerRadius: 16),
        payloadFiles: _windowOnlyPayload(),
      );
      final second = const GamePackageBuilder().build(
        manifest: _windowOnlyManifest(cornerRadius: 24),
        payloadFiles: _windowOnlyPayload(),
      );

      final firstReceipt = preflight.certify(
        const GamePackageInspector().inspect(first.packageBytes),
      );
      final secondReceipt = preflight.certify(
        const GamePackageInspector().inspect(second.packageBytes),
      );

      expect(
        firstReceipt.configuredCategories,
        <GamePackagePersonalizationCategory>[
          GamePackagePersonalizationCategory.windows,
        ],
      );
      expect(
        firstReceipt.presentationSha256,
        isNot(secondReceipt.presentationSha256),
      );
    });

    test('rejects an embedded font without its redistribution license', () {
      final valid = _validInspection();
      final manifest = _manifest(
        content: valid.manifest.content,
        displayFont: const GamePackageFontRole(
          font: 'presentation/fonts/display.ttf',
          family: 'Golden Display',
          fallbackFamilies: <String>['sans-serif'],
        ),
      );

      expect(
        () => preflight.certify(_withManifest(valid, manifest)),
        throwsA(
          isA<GamePackageFormatException>()
              .having(
                (error) => error.code,
                'code',
                'presentationLicenseMissing',
              )
              .having(
                (error) => error.path,
                'path',
                r'$.presentation.typography.display.license',
              ),
        ),
      );
    });

    test('rejects a playback contract outside the supported codec matrix', () {
      final valid = _validInspection();
      final manifest = _manifest(
        content: valid.manifest.content,
        videoCodec: 'hevc',
      );

      expect(
        () => preflight.certify(_withManifest(valid, manifest)),
        throwsA(
          isA<GamePackageFormatException>().having(
            (error) => error.code,
            'code',
            'presentationMediaUnsupported',
          ),
        ),
      );
    });

    test('rejects a receipt whose inspected tree hash no longer matches', () {
      final valid = _validInspection();
      final badReceipt = GamePackageInspectionReceipt(
        receiptVersion: valid.receipt.receiptVersion,
        securityPolicyVersion: valid.receipt.securityPolicyVersion,
        gameId: valid.receipt.gameId,
        gameVersion: valid.receipt.gameVersion,
        treeSha256: 'f' * 64,
        manifestSha256: valid.receipt.manifestSha256,
        packageSha256: valid.receipt.packageSha256,
        archiveBytes: valid.receipt.archiveBytes,
        payloadBytes: valid.receipt.payloadBytes,
        fileCount: valid.receipt.fileCount,
        signatureStatus: valid.receipt.signatureStatus,
        pokemonRuleset: valid.receipt.pokemonRuleset,
      );

      expect(
        () => preflight.certify(
          GamePackageInspectionResult(
            manifest: valid.manifest,
            payloadPaths: valid.payloadPaths,
            signatureStatus: valid.signatureStatus,
            compatibility: valid.compatibility,
            receipt: badReceipt,
          ),
        ),
        throwsA(
          isA<GamePackageFormatException>().having(
            (error) => error.code,
            'code',
            'presentationHashMismatch',
          ),
        ),
      );
    });

    test('package builder rejects a missing font license before export', () {
      expect(
        () => const GamePackageBuilder().build(
          manifest: _manifest(
            content: _emptyContent,
            displayFont: const GamePackageFontRole(
              font: 'presentation/fonts/display.ttf',
              family: 'Golden Display',
              fallbackFamilies: <String>['sans-serif'],
            ),
          ),
          payloadFiles: _validPayload(),
        ),
        throwsA(
          isA<GamePackageFormatException>().having(
            (error) => error.code,
            'code',
            'incompleteTypographyRole',
          ),
        ),
      );
    });

    test('package builder rejects an unsupported intro codec before export',
        () {
      expect(
        () => const GamePackageBuilder().build(
          manifest: _manifest(
            content: _emptyContent,
            videoCodec: 'hevc',
          ),
          payloadFiles: _validPayload(),
        ),
        throwsA(
          isA<GamePackageFormatException>().having(
            (error) => error.code,
            'code',
            'invalidIntroVideoMetadata',
          ),
        ),
      );
    });
  });
}

GamePackageInspectionResult _validInspection() {
  final built = const GamePackageBuilder().build(
    manifest: _manifest(content: _emptyContent),
    payloadFiles: _validPayload(),
  );
  return const GamePackageInspector().inspect(built.packageBytes);
}

Map<String, List<int>> _validPayload() => <String, List<int>>{
      'project/project.json': utf8.encode(
        jsonEncode(<String, Object?>{
          'name': 'Personalization Golden',
          'version': 'v6',
          'maps': <Object?>[],
          'tilesets': <Object?>[],
          'pokemon': const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          ).toJson(),
        }),
      ),
      'presentation/icon.png': _onePixelPngHeader(),
      'project/assets/title.ogg': ascii.encode('OggS golden-title'),
      'presentation/intro/video.mp4': <int>[
        0,
        0,
        0,
        24,
        ...ascii.encode('ftypisom'),
        0,
        0,
        0,
        0,
        ...ascii.encode('isomavc1mp4a'),
      ],
      'presentation/intro/poster.png': _onePixelPngHeader(),
      'presentation/intro/captions.vtt':
          utf8.encode('WEBVTT\n\n00:00.000 --> 00:01.000\nAube\n'),
      'presentation/fonts/display.ttf': <int>[0, 1, 0, 0, 0, 0, 0, 0],
      'presentation/fonts/display-license.txt':
          utf8.encode('Redistribution permitted.'),
    };

Map<String, List<int>> _windowOnlyPayload() => <String, List<int>>{
      'project/project.json': utf8.encode(
        jsonEncode(<String, Object?>{
          'name': 'Window-only fixture',
          'version': 'v6',
          'maps': <Object?>[],
          'tilesets': <Object?>[],
          'pokemon': const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          ).toJson(),
        }),
      ),
    };

GamePackageManifest _windowOnlyManifest({required int cornerRadius}) =>
    GamePackageManifest(
      packageFormat: 1,
      gameId: 'games.example.windows',
      gameVersion: Version(1, 0, 0),
      title: 'Window-only fixture',
      author: const GamePackageParty(name: 'PokeMap'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version(1, 0, 0),
        runtimeApiExpression: '>=1.0.0 <2.0.0',
        projectFormat: 'v6',
        saveFormat: 1,
        compatibilityId: 'main',
        requiredCapabilities: const <String>[],
      ),
      locales: GamePackageLocales(
        defaultLocale: 'fr',
        supported: const <String>['fr'],
      ),
      presentation: GamePackagePresentation(
        schemaVersion: 3,
        windows: GamePackagePresentationWindows(
          styles: <GamePackageWindowStyle>[
            GamePackageWindowStyle(
              id: 'window',
              fillToken: 'menuSurface',
              borderToken: 'outline',
              borderWidth: 1,
              cornerRadius: cornerRadius,
              contentPadding: 16,
              shadowElevation: 8,
            ),
          ],
          defaultStyleId: 'window',
          pauseMenuStyleId: 'window',
          dialogueStyleId: 'window',
          pauseBackdropOpacity: .7,
        ),
      ),
      content: _emptyContent,
    );

Map<String, List<int>> _validPayloadV2() {
  final payload = _validPayload()
    ..remove('presentation/intro/video.mp4')
    ..remove('presentation/intro/poster.png')
    ..remove('presentation/intro/captions.vtt');
  for (final root in <String>[
    'presentation/intro/landscape',
    'presentation/intro/portrait',
    'presentation/title/prompt/landscape',
    'presentation/title/prompt/portrait',
    'presentation/title/menu/landscape',
    'presentation/title/menu/portrait',
  ]) {
    payload['$root/video.mp4'] = <int>[
      0,
      0,
      0,
      24,
      ...ascii.encode('ftypisom'),
      0,
      0,
      0,
      0,
      ...ascii.encode('isomavc1mp4a'),
    ];
    payload['$root/poster.png'] = _onePixelPngHeader();
  }
  return payload;
}

GamePackageInspectionResult _withManifest(
  GamePackageInspectionResult inspection,
  GamePackageManifest manifest,
) =>
    GamePackageInspectionResult(
      manifest: manifest,
      payloadPaths: inspection.payloadPaths,
      signatureStatus: inspection.signatureStatus,
      compatibility: inspection.compatibility,
      receipt: inspection.receipt,
    );

GamePackageManifest _manifest({
  required GamePackageContent content,
  String videoCodec = 'h264',
  GamePackageFontRole displayFont = const GamePackageFontRole(
    font: 'presentation/fonts/display.ttf',
    family: 'Golden Display',
    license: 'presentation/fonts/display-license.txt',
    fallbackFamilies: <String>['sans-serif'],
  ),
}) =>
    GamePackageManifest(
      packageFormat: 1,
      gameId: 'games.example.personalized',
      gameVersion: Version(1, 0, 0),
      title: 'Personalization Golden',
      author: const GamePackageParty(name: 'PokeMap'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version(1, 0, 0),
        runtimeApiExpression: '>=1.0.0 <2.0.0',
        projectFormat: 'v6',
        saveFormat: 1,
        compatibilityId: 'main',
        requiredCapabilities: const <String>[],
      ),
      locales: GamePackageLocales(
        defaultLocale: 'fr',
        supported: const <String>['fr', 'en'],
      ),
      presentation: GamePackagePresentation(
        branding: const GamePackageBranding(
          icon: 'presentation/icon.png',
          titleMusic: 'project/assets/title.ogg',
          accentColor: '#003A44',
          layoutVariant: 'cinematic',
        ),
        intro: GamePackageIntroVideo(
          video: 'presentation/intro/video.mp4',
          poster: 'presentation/intro/poster.png',
          captions: 'presentation/intro/captions.vtt',
          durationMilliseconds: 1000,
          width: 640,
          height: 360,
          bitrateKbps: 1000,
          sizeBytes: 32,
          videoCodec: videoCodec,
          audioCodec: 'aac',
          reducedMotionBehavior: 'poster',
          allowReplay: true,
        ),
        typography: GamePackageTypography(display: displayFont),
        theme: _theme,
      ),
      content: content,
    );

GamePackageManifest _manifestV2({required GamePackageContent content}) {
  GamePackageVideoVariant variant(String root, {required bool withAudio}) =>
      GamePackageVideoVariant(
        video: '$root/video.mp4',
        poster: '$root/poster.png',
        durationMilliseconds: 1000,
        width: root.endsWith('portrait') ? 360 : 640,
        height: root.endsWith('portrait') ? 640 : 360,
        bitrateKbps: 1000,
        sizeBytes: 32,
        videoCodec: 'h264',
        audioCodec: withAudio ? 'aac' : 'none',
      );

  return GamePackageManifest(
    packageFormat: 1,
    gameId: 'games.example.personalized',
    gameVersion: Version(2, 0, 0),
    title: 'Personalization Responsive',
    author: const GamePackageParty(name: 'PokeMap'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version(1, 0, 0),
      runtimeApiExpression: '>=1.0.0 <2.0.0',
      projectFormat: 'v6',
      saveFormat: 1,
      compatibilityId: 'main',
      requiredCapabilities: const <String>[],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr',
      supported: const <String>['fr'],
    ),
    presentation: GamePackagePresentation(
      schemaVersion: 2,
      intro: GamePackageIntroVideo(
        media: GamePackageResponsiveVideo(
          landscape: variant(
            'presentation/intro/landscape',
            withAudio: true,
          ),
          portrait: variant(
            'presentation/intro/portrait',
            withAudio: true,
          ),
        ),
        reducedMotionBehavior: 'poster',
        allowReplay: true,
      ),
      titleMotion: GamePackageTitleMotion(
        promptLoop: GamePackageResponsiveVideo(
          landscape: variant(
            'presentation/title/prompt/landscape',
            withAudio: false,
          ),
          portrait: variant(
            'presentation/title/prompt/portrait',
            withAudio: false,
          ),
        ),
        menuLoop: GamePackageResponsiveVideo(
          landscape: variant(
            'presentation/title/menu/landscape',
            withAudio: false,
          ),
          portrait: variant(
            'presentation/title/menu/portrait',
            withAudio: false,
          ),
        ),
      ),
      typography: const GamePackageTypography(display: _defaultDisplayFont),
      theme: _theme,
    ),
    content: content,
  );
}

const _defaultDisplayFont = GamePackageFontRole(
  font: 'presentation/fonts/display.ttf',
  family: 'Golden Display',
  license: 'presentation/fonts/display-license.txt',
  fallbackFamilies: <String>['sans-serif'],
);

final _emptyContent = GamePackageContent(
  fileCount: 0,
  totalBytes: 0,
  treeSha256:
      '0000000000000000000000000000000000000000000000000000000000000000',
  files: <GamePackageFileEntry>[],
);

const _theme = GamePackageSemanticTheme(
  primary: '#003A44',
  onPrimary: '#FFFFFF',
  background: '#F4F7FB',
  surface: '#FFFFFF',
  surfaceElevated: '#EAF0F8',
  textPrimary: '#101827',
  textSecondary: '#526176',
  outline: '#65758B',
  success: '#16794B',
  warning: '#8A5100',
  danger: '#B4233C',
  titleSurface: '#D9F4F6',
  dialogueSurface: '#FFFFFF',
  menuSurface: '#EAF0F8',
  overworldHudSurface: '#FFFFFF',
  battleHudSurface: '#FFFFFF',
);

List<int> _onePixelPngHeader() {
  final bytes = Uint8List(24)
    ..setAll(
      0,
      <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
    )
    ..setAll(12, ascii.encode('IHDR'));
  ByteData.sublistView(bytes)
    ..setUint32(16, 1)
    ..setUint32(20, 1);
  return bytes;
}
