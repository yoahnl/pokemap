import 'dart:convert';
import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('GamePackageManifestCodec', () {
    const codec = GamePackageManifestCodec();

    test('round-trips a minimal manifest canonically', () {
      final manifest = codec.decodeJson(_minimalManifestJson());

      expect(manifest.packageFormat, 1);
      expect(manifest.gameId, 'games.example.minimal');
      expect(manifest.gameVersion.toString(), '1.0.0');
      expect(manifest.compatibility.runtimeApi.allows(manifest.gameVersion),
          isTrue);
      expect(
        jsonDecode(codec.encodeCanonicalJson(manifest)),
        _minimalManifestJson(),
      );
      expect(
        codec.decodeUtf8(codec.encodeCanonicalUtf8(manifest)).toJson(),
        manifest.toJson(),
      );
    });

    test('round-trips all optional declarative fields', () {
      final json = _minimalManifestJson()
        ..['description'] = 'Neutral fixture'
        ..['publisher'] = <String, Object?>{
          'name': 'Example Publisher',
          'url': 'https://example.invalid',
        }
        ..['branding'] = <String, Object?>{
          'icon': 'presentation/icon.png',
          'cover': 'presentation/cover.png',
          'hero': 'presentation/hero.png',
          'accentColor': '#6D5EFCAA',
          'titleMusic': 'project/assets/title.ogg',
          'layoutVariant': 'cinematic',
        }
        ..['signature'] = <String, Object?>{
          'algorithm': 'ed25519',
          'keyId': 'example:key-1',
          'value': base64Encode(Uint8List(64)),
        };
      final compatibility = json['compatibility']! as Map<String, Object?>;
      compatibility['requiredCapabilities'] = <String>[
        'dialogue.choices@1',
        'overworld.menu@1',
      ];
      final locales = json['locales']! as Map<String, Object?>;
      locales['supported'] = <String>['fr-FR', 'en-US'];
      locales['default'] = 'fr-FR';
      final content = json['content']! as Map<String, Object?>;
      final projectFile =
          (content['files']! as List<Object?>).single as Map<String, Object?>;
      content
        ..['fileCount'] = 5
        ..['files'] = <Object?>[
          _emptyFile('presentation/cover.png'),
          _emptyFile('presentation/hero.png'),
          _emptyFile('presentation/icon.png'),
          _emptyFile('project/assets/title.ogg'),
          projectFile,
        ];
      content['treeSha256'] = _treeHashFromJson(content['files']!);

      final manifest = codec.decodeJson(json);

      expect(manifest.publisher?.name, 'Example Publisher');
      expect(manifest.branding?.layoutVariant, 'cinematic');
      expect(manifest.signature?.algorithm, 'ed25519');
      expect(codec.decodeJson(manifest.toJson()).toJson(), manifest.toJson());
    });

    test('round-trips the versioned presentation contract', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 1,
          'branding': <String, Object?>{
            'icon': 'presentation/icon.png',
            'accentColor': '#6750A4',
            'layoutVariant': 'centered',
          },
          'intro': <String, Object?>{
            'video': 'presentation/intro/video.mp4',
            'poster': 'presentation/intro/poster.png',
            'captions': 'presentation/intro/captions.vtt',
            'durationMilliseconds': 32000,
            'width': 1920,
            'height': 1080,
            'bitrateKbps': 8000,
            'sizeBytes': 32000000,
            'videoCodec': 'h264',
            'audioCodec': 'aac',
            'reducedMotionBehavior': 'poster',
            'allowReplay': true,
          },
          'typography': <String, Object?>{
            'display': <String, Object?>{
              'font': 'presentation/fonts/display.ttf',
              'family': 'Aube Display',
              'license': 'presentation/fonts/display-license.txt',
              'fallbackFamilies': <String>['sans-serif'],
            },
            'body': <String, Object?>{
              'fallbackFamilies': <String>['sans-serif'],
            },
            'dialogue': <String, Object?>{
              'fallbackFamilies': <String>['sans-serif'],
            },
            'numbers': <String, Object?>{
              'fallbackFamilies': <String>['monospace'],
            },
          },
          'theme': _validSemanticThemeJson(),
        };
      final content = json['content']! as Map<String, Object?>;
      final projectFile =
          (content['files']! as List<Object?>).single as Map<String, Object?>;
      content
        ..['fileCount'] = 7
        ..['files'] = <Object?>[
          _emptyFile('presentation/fonts/display-license.txt'),
          _emptyFile('presentation/fonts/display.ttf'),
          _emptyFile('presentation/icon.png'),
          _emptyFile('presentation/intro/captions.vtt'),
          _emptyFile('presentation/intro/poster.png'),
          _emptyFile('presentation/intro/video.mp4'),
          projectFile,
        ];
      content['treeSha256'] = _treeHashFromJson(content['files']!);

      final manifest = codec.decodeJson(json);

      expect(manifest.presentation?.schemaVersion, 1);
      expect(manifest.branding?.icon, 'presentation/icon.png');
      expect(manifest.presentation?.intro?.videoCodec, 'h264');
      expect(
        manifest.presentation?.typography?.display.family,
        'Aube Display',
      );
      expect(
        manifest.presentation?.typography?.numbers.fallbackFamilies,
        <String>['monospace'],
      );
      expect(
        manifest.presentation?.theme?.battleHudSurface,
        '#FFFFFF',
      );
      expect(manifest.usesLegacyBranding, isFalse);
      expect(codec.decodeJson(manifest.toJson()).toJson(), json);
    });

    test('round-trips V2 project menu label overrides', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 2,
          'branding': <String, Object?>{},
          'menuLabels': <String, Object?>{
            'pauseTitle': 'Interruption',
            'pokedex': 'Carnet de voyage',
            'returnToTitle': 'Quitter la partie',
          },
        };

      final manifest = codec.decodeJson(json);

      expect(manifest.presentation?.menuLabels?.pauseTitle, 'Interruption');
      expect(manifest.presentation?.menuLabels?.pokedex, 'Carnet de voyage');
      expect(
        manifest.presentation?.menuLabels?.returnToTitle,
        'Quitter la partie',
      );
      expect(codec.decodeJson(manifest.toJson()).toJson(), json);
    });

    test('round-trips V3 project window styles', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 3,
          'branding': <String, Object?>{},
          'windows': <String, Object?>{
            'styles': <Object?>[
              <String, Object?>{
                'id': 'pause-menu',
                'fillToken': 'menuSurface',
                'borderToken': 'outline',
                'borderWidth': 2,
                'cornerRadius': 24,
                'contentPadding': 16,
                'shadowElevation': 12,
              },
              <String, Object?>{
                'id': 'dialogue',
                'fillToken': 'dialogueSurface',
                'borderToken': 'primary',
                'borderWidth': 1,
                'cornerRadius': 10,
                'contentPadding': 20,
                'shadowElevation': 4,
              },
            ],
            'defaultStyleId': 'pause-menu',
            'pauseMenuStyleId': 'pause-menu',
            'dialogueStyleId': 'dialogue',
            'pauseBackdropOpacityPermille': 850,
          },
        };

      final manifest = codec.decodeJson(json);

      expect(manifest.presentation?.windows?.styles, hasLength(2));
      expect(manifest.presentation?.windows?.pauseMenuStyleId, 'pause-menu');
      expect(manifest.presentation?.windows?.dialogueStyleId, 'dialogue');
      expect(manifest.presentation?.windows?.pauseBackdropOpacity, .85);
      expect(codec.decodeJson(manifest.toJson()).toJson(), json);
    });

    test('rejects V3 window styles with unknown semantic tokens', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 3,
          'branding': <String, Object?>{},
          'windows': <String, Object?>{
            'styles': <Object?>[
              <String, Object?>{
                'id': 'pause-menu',
                'fillToken': 'rawPink',
                'borderToken': 'outline',
                'borderWidth': 1,
                'cornerRadius': 16,
                'contentPadding': 16,
                'shadowElevation': 8,
              },
            ],
            'defaultStyleId': 'pause-menu',
            'pauseMenuStyleId': 'pause-menu',
            'dialogueStyleId': 'pause-menu',
            'pauseBackdropOpacityPermille': 700,
          },
        };

      _expectCode(
        () => codec.decodeJson(json),
        'invalidWindowStyle',
        r'$.presentation.windows.styles[0].fillToken',
      );
    });

    test('rejects windows declared before presentation schema V3', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 2,
          'branding': <String, Object?>{},
          'windows': <String, Object?>{
            'styles': <Object?>[],
            'defaultStyleId': 'default',
            'pauseMenuStyleId': 'default',
            'dialogueStyleId': 'default',
            'pauseBackdropOpacityPermille': 700,
          },
        };

      _expectCode(
        () => codec.decodeJson(json),
        'presentationVersionUnsupported',
        r'$.presentation.windows',
      );
    });

    test('round-trips V4 responsive surface layouts', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 4,
          'branding': <String, Object?>{'layoutVariant': 'cinematic'},
          'layouts': _layoutsJson(),
        };

      final manifest = codec.decodeJson(json);

      expect(manifest.presentation?.layouts?.title.expanded.slot, 'bottomLeft');
      expect(manifest.presentation?.layouts?.pauseMenu.regular.slot, 'left');
      expect(
        manifest.presentation?.layouts?.dialogue.compact.width,
        'wide',
      );
      expect(codec.decodeJson(manifest.toJson()).toJson(), json);
    });

    test('round-trips V5 combat presentation settings', () {
      final layouts = _layoutsJson()
        ..['battle'] = _responsiveLayoutJson(
          compactSlot: 'bottomCenter',
          regularSlot: 'right',
          expandedSlot: 'fullScreen',
        );
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 5,
          'branding': <String, Object?>{},
          'typography': <String, Object?>{
            for (final role in <String>[
              'display',
              'body',
              'dialogue',
              'numbers',
              'combat',
            ])
              role: <String, Object?>{
                if (role == 'combat') ...<String, Object?>{
                  'font': 'presentation/fonts/battle.ttf',
                  'family': 'Battle Mono',
                  'license': 'presentation/fonts/battle-license.txt',
                },
                'fallbackFamilies': <Object?>['sans-serif'],
              },
          },
          'windows': <String, Object?>{
            'styles': <Object?>[
              <String, Object?>{
                'id': 'default',
                'fillToken': 'surface',
                'borderToken': 'outline',
                'borderWidth': 1,
                'cornerRadius': 16,
                'contentPadding': 16,
                'shadowElevation': 8,
              },
              <String, Object?>{
                'id': 'battle',
                'fillToken': 'battleHudSurface',
                'borderToken': 'primary',
                'borderWidth': 2,
                'cornerRadius': 12,
                'contentPadding': 12,
                'shadowElevation': 4,
              },
            ],
            'defaultStyleId': 'default',
            'pauseMenuStyleId': 'default',
            'dialogueStyleId': 'default',
            'battleStyleId': 'battle',
            'pauseBackdropOpacityPermille': 700,
          },
          'layouts': layouts,
        };
      final content = json['content']! as Map<String, Object?>;
      final projectFile =
          (content['files']! as List<Object?>).single as Map<String, Object?>;
      content
        ..['fileCount'] = 3
        ..['files'] = <Object?>[
          _emptyFile('presentation/fonts/battle-license.txt'),
          _emptyFile('presentation/fonts/battle.ttf'),
          projectFile,
        ];
      content['treeSha256'] = _treeHashFromJson(content['files']!);

      final manifest = codec.decodeJson(json);

      expect(manifest.presentation?.windows?.battleStyleId, 'battle');
      expect(manifest.presentation?.layouts?.battle?.regular.slot, 'right');
      expect(manifest.presentation?.typography?.combat?.family, 'Battle Mono');
      expect(codec.decodeJson(manifest.toJson()).toJson(), json);
    });

    test('rejects V5 combat fields declared in schema V4', () {
      final cases = <({String path, Map<String, Object?> presentation})>[
        (
          path: r'$.presentation.windows.battleStyleId',
          presentation: <String, Object?>{
            'schemaVersion': 4,
            'branding': <String, Object?>{},
            'windows': <String, Object?>{
              'styles': <Object?>[],
              'defaultStyleId': 'default',
              'pauseMenuStyleId': 'default',
              'dialogueStyleId': 'default',
              'battleStyleId': 'default',
              'pauseBackdropOpacityPermille': 700,
            },
          },
        ),
        (
          path: r'$.presentation.layouts.battle',
          presentation: <String, Object?>{
            'schemaVersion': 4,
            'branding': <String, Object?>{},
            'layouts': <String, Object?>{
              ..._layoutsJson(),
              'battle': _responsiveLayoutJson(
                compactSlot: 'bottomCenter',
                regularSlot: 'right',
                expandedSlot: 'fullScreen',
              ),
            },
          },
        ),
        (
          path: r'$.presentation.typography.combat',
          presentation: <String, Object?>{
            'schemaVersion': 4,
            'branding': <String, Object?>{},
            'typography': <String, Object?>{
              'combat': <String, Object?>{
                'fallbackFamilies': <Object?>['sans-serif'],
              },
            },
          },
        ),
      ];

      for (final entry in cases) {
        final json = _minimalManifestJson()
          ..['presentation'] = entry.presentation;
        _expectCode(
          () => codec.decodeJson(json),
          'presentationVersionUnsupported',
          entry.path,
        );
      }
    });

    test('rejects layouts declared before presentation schema V4', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 3,
          'branding': <String, Object?>{},
          'layouts': _layoutsJson(),
        };

      _expectCode(
        () => codec.decodeJson(json),
        'presentationVersionUnsupported',
        r'$.presentation.layouts',
      );
    });

    test('rejects invalid packaged menu labels', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 2,
          'branding': <String, Object?>{},
          'menuLabels': <String, Object?>{'pokedex': '   '},
        };

      _expectCode(
        () => codec.decodeJson(json),
        'invalidMenuLabel',
        r'$.presentation.menuLabels.pokedex',
      );
    });

    test('rejects packaged semantic themes with inaccessible contrast', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 1,
          'branding': <String, Object?>{},
          'theme': <String, Object?>{
            ..._validSemanticThemeJson(),
            'primary': '#EEEEEE',
            'onPrimary': '#FFFFFF',
          },
        };

      _expectCode(
        () => codec.decodeJson(json),
        'invalidSemanticTheme',
        r'$.presentation.theme',
      );
    });

    test('rejects unsafe or unsupported packaged intro video metadata', () {
      final json = _minimalManifestJson()
        ..['presentation'] = <String, Object?>{
          'schemaVersion': 1,
          'branding': <String, Object?>{},
          'intro': <String, Object?>{
            'video': 'project/assets/intro.mp4',
            'poster': 'presentation/intro/poster.png',
            'durationMilliseconds': 32000,
            'width': 1920,
            'height': 1080,
            'bitrateKbps': 8000,
            'sizeBytes': 32000000,
            'videoCodec': 'h264',
            'audioCodec': 'aac',
            'reducedMotionBehavior': 'poster',
            'allowReplay': true,
          },
        };

      _expectCode(
        () => codec.decodeJson(json),
        'invalidIntroVideoReference',
        r'$.presentation.intro.video',
      );
    });

    test('keeps legacy branding manifests readable through the effective API',
        () {
      final json = _minimalManifestJson()
        ..['branding'] = <String, Object?>{
          'accentColor': '#123456',
          'layoutVariant': 'standard',
        };

      final manifest = codec.decodeJson(json);

      expect(manifest.presentation, isNull);
      expect(manifest.usesLegacyBranding, isTrue);
      expect(manifest.branding?.accentColor, '#123456');
      expect(manifest.toJson(), contains('branding'));
    });

    test('signature preimage omits only the root signature', () {
      final json = _minimalManifestJson()
        ..['signature'] = <String, Object?>{
          'algorithm': 'ed25519',
          'keyId': 'example:key-1',
          'value': base64Encode(Uint8List(64)),
        };
      final manifest = codec.decodeJson(json);

      final preimage = jsonDecode(
        utf8.decode(codec.signaturePreimageUtf8(manifest)),
      ) as Map<String, Object?>;

      expect(preimage, isNot(contains('signature')));
      expect(preimage['gameId'], manifest.gameId);
      expect(codec.encodeCanonicalJson(manifest), contains('"signature"'));
    });

    test('decodeUtf8 requires canonical JSON bytes', () {
      final canonical = codec.encodeCanonicalUtf8(
        codec.decodeJson(_minimalManifestJson()),
      );
      final pretty = const JsonEncoder.withIndent('  ').convert(
        _minimalManifestJson(),
      );
      final duplicate = utf8.decode(canonical).replaceFirst(
          '"packageFormat":1',
          ''
              '"packageFormat":1,"packageFormat":1');

      expect(codec.decodeUtf8(canonical).gameId, 'games.example.minimal');
      _expectCode(
        () => codec.decodeUtf8(utf8.encode(pretty)),
        'nonCanonicalManifest',
        r'$',
      );
      _expectCode(
        () => codec.decodeUtf8(utf8.encode(duplicate)),
        'nonCanonicalManifest',
        r'$',
      );
    });

    test('encode and signature preimage revalidate public model values', () {
      final valid = codec.decodeJson(_minimalManifestJson());
      final invalid = GamePackageManifest(
        packageFormat: 2,
        gameId: valid.gameId,
        gameVersion: valid.gameVersion,
        title: valid.title,
        author: valid.author,
        compatibility: valid.compatibility,
        locales: valid.locales,
        content: valid.content,
      );

      _expectCode(
        () => codec.encodeCanonicalJson(invalid),
        'packageFormatUnsupported',
        r'$.packageFormat',
      );
      _expectCode(
        () => codec.signaturePreimageUtf8(invalid),
        'packageFormatUnsupported',
        r'$.packageFormat',
      );
    });

    test('rejects unknown fields at every object level', () {
      final root = _minimalManifestJson()..['executableEntryPoint'] = 'main';
      _expectCode(() => codec.decodeJson(root), 'unknownField', r'$');

      final nested = _minimalManifestJson();
      (nested['compatibility']! as Map<String, Object?>)['future'] = true;
      _expectCode(
        () => codec.decodeJson(nested),
        'unknownField',
        r'$.compatibility',
      );
    });

    test('rejects missing fields and invalid value types', () {
      final missing = _minimalManifestJson()..remove('gameId');
      _expectCode(() => codec.decodeJson(missing), 'missingField', r'$.gameId');

      final wrongType = _minimalManifestJson()..['packageFormat'] = '1';
      _expectCode(
        () => codec.decodeJson(wrongType),
        'invalidType',
        r'$.packageFormat',
      );
    });

    test('rejects invalid identity, versions and project format', () {
      for (final id in <String>[
        'Complete Adventure',
        'games.example',
        'Games.example.game',
        'a.${'b' * 125}.c',
      ]) {
        final json = _minimalManifestJson()..['gameId'] = id;
        _expectCode(() => codec.decodeJson(json), 'invalidGameId', r'$.gameId');
      }

      for (final version in <String>['v1.0.0', '1.0.0-01', '1.0']) {
        final json = _minimalManifestJson()..['gameVersion'] = version;
        _expectCode(
          () => codec.decodeJson(json),
          'invalidSemVer',
          r'$.gameVersion',
        );
      }

      final futureProject = _minimalManifestJson();
      (futureProject['compatibility']!
          as Map<String, Object?>)['projectFormat'] = 'v3';
      expect(
        codec.decodeJson(futureProject).compatibility.projectFormat,
        'v3',
      );

      final invalidProject = _minimalManifestJson();
      (invalidProject['compatibility']!
          as Map<String, Object?>)['projectFormat'] = '3';
      _expectCode(
        () => codec.decodeJson(invalidProject),
        'invalidProjectFormat',
        r'$.compatibility.projectFormat',
      );

      final unsafeSaveFormat = _minimalManifestJson();
      (unsafeSaveFormat['compatibility']!
              as Map<String, Object?>)['saveFormat'] =
          CanonicalJson.maxSafeInteger + 1;
      _expectCode(
        () => codec.decodeJson(unsafeSaveFormat),
        'invalidSaveFormat',
        r'$.compatibility.saveFormat',
      );
    });

    test('rejects invalid capabilities and locale configuration', () {
      final duplicate = _minimalManifestJson();
      (duplicate['compatibility']!
          as Map<String, Object?>)['requiredCapabilities'] = <String>[
        'dialogue.choices@1',
        'dialogue.choices@1',
      ];
      _expectCode(
        () => codec.decodeJson(duplicate),
        'duplicateCapability',
        r'$.compatibility.requiredCapabilities',
      );

      final malformed = _minimalManifestJson();
      (malformed['compatibility']!
          as Map<String, Object?>)['requiredCapabilities'] = <String>[
        'dialogue.choices@0',
      ];
      _expectCode(
        () => codec.decodeJson(malformed),
        'invalidCapability',
        r'$.compatibility.requiredCapabilities[0]',
      );

      final locale = _minimalManifestJson();
      (locale['locales']! as Map<String, Object?>)
        ..['default'] = 'en'
        ..['supported'] = <String>['fr'];
      _expectCode(
        () => codec.decodeJson(locale),
        'defaultLocaleNotSupported',
        r'$.locales.default',
      );
    });

    test('allows only credential-free HTTP(S) party metadata URLs', () {
      final valid = _minimalManifestJson();
      (valid['author']! as Map<String, Object?>)['url'] =
          'https://example.invalid/studio';
      expect(
        codec.decodeJson(valid).author.url.toString(),
        'https://example.invalid/studio',
      );

      for (final source in <String>[
        'file:///tmp/studio',
        'mailto:studio@example.invalid',
        'http:opaque',
        'https://user:password@example.invalid',
      ]) {
        final invalid = _minimalManifestJson();
        (invalid['author']! as Map<String, Object?>)['url'] = source;
        _expectCode(
          () => codec.decodeJson(invalid),
          'invalidUri',
          r'$.author.url',
        );
      }
    });

    test('uses code-point string lengths and strict shared path policy', () {
      final astralTitle = _minimalManifestJson()..['title'] = '😀' * 100;
      expect(codec.decodeJson(astralTitle).title.runes.length, 100);

      for (final path in <String>[
        'project/./project.json',
        'project/maps/e\u0301.json',
        'project/AUX.json',
        'project/maps/trailing. ',
        'project/${'a' * 256}.json',
        'project/${List<String>.filled(32, 'd').join('/')}/project.json',
      ]) {
        final json = _minimalManifestJson();
        final content = json['content']! as Map<String, Object?>;
        final file =
            (content['files']! as List<Object?>).single as Map<String, Object?>;
        file['path'] = path;
        _expectCode(
          () => codec.decodeJson(json),
          'invalidPackagePath',
          r'$.content.files[0].path',
        );
      }
    });

    test('rejects normalized case collisions and wrong branding roots', () {
      final collision = _minimalManifestJson();
      final content = collision['content']! as Map<String, Object?>;
      final projectFile =
          (content['files']! as List<Object?>).single as Map<String, Object?>;
      content
        ..['fileCount'] = 3
        ..['totalBytes'] = 24
        ..['files'] = <Object?>[
          _emptyFile('presentation/Icon.png'),
          _emptyFile('presentation/icon.png'),
          projectFile,
        ];
      content['treeSha256'] = _treeHashFromJson(content['files']!);
      _expectCode(
        () => codec.decodeJson(collision),
        'pathCollision',
        r'$.content.files[1].path',
      );

      final branding = _minimalManifestJson()
        ..['branding'] = <String, Object?>{
          'icon': 'project/project.json',
        };
      _expectCode(
        () => codec.decodeJson(branding),
        'invalidBrandingReference',
        r'$.branding.icon',
      );
    });

    test('uses Unicode caseless matching for collision keys', () {
      expect(
        PackagePathPolicy.collisionKey('project/straße.json'),
        PackagePathPolicy.collisionKey('project/STRASSE.json'),
      );
      expect(
        PackagePathPolicy.collisionKey('project/Σ.json'),
        PackagePathPolicy.collisionKey('project/ς.json'),
      );
      expect(
        PackagePathPolicy.collisionKey('project/ᾀ.json'),
        PackagePathPolicy.collisionKey('project/ἀι.json'),
      );
      expect(
        PackagePathPolicy.collisionKey('project/ﬓ.json'),
        PackagePathPolicy.collisionKey('project/մն.json'),
      );
      expect(
        PackagePathPolicy.collisionKey('project/İ.json'),
        PackagePathPolicy.collisionKey('project/i\u0307.json'),
      );
    });

    test('rejects invalid signatures and malformed UTF-8 JSON', () {
      final signature = _minimalManifestJson()
        ..['signature'] = <String, Object?>{
          'algorithm': 'rsa',
          'keyId': 'key',
          'value': 'not-base64',
        };
      _expectCode(
        () => codec.decodeJson(signature),
        'unsupportedSignatureAlgorithm',
        r'$.signature.algorithm',
      );

      final nonCanonicalBase64 = _minimalManifestJson()
        ..['signature'] = <String, Object?>{
          'algorithm': 'ed25519',
          'keyId': 'example:key-1',
          'value': '${base64Encode(Uint8List(63))}====',
        };
      _expectCode(
        () => codec.decodeJson(nonCanonicalBase64),
        'invalidSignature',
        r'$.signature.value',
      );

      expect(
        () => codec.decodeUtf8(<int>[0xff]),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'invalidUtf8'),
        ),
      );
    });
  });
}

Map<String, Object?> _layoutsJson() => <String, Object?>{
      'title': _responsiveLayoutJson(
        compactSlot: 'bottomCenter',
        regularSlot: 'center',
        expandedSlot: 'bottomLeft',
        expandedWidth: 'narrow',
      ),
      'pauseMenu': _responsiveLayoutJson(
        compactSlot: 'fullScreen',
        regularSlot: 'left',
        expandedSlot: 'leftPane',
      ),
      'dialogue': _responsiveLayoutJson(
        compactSlot: 'bottomCenter',
        regularSlot: 'bottomCenter',
        expandedSlot: 'topCenter',
        compactWidth: 'wide',
      ),
    };

Map<String, Object?> _responsiveLayoutJson({
  required String compactSlot,
  required String regularSlot,
  required String expandedSlot,
  String compactWidth = 'comfortable',
  String expandedWidth = 'comfortable',
}) =>
    <String, Object?>{
      'compact': _layoutVariantJson(
        breakpoint: 'compact',
        slot: compactSlot,
        width: compactWidth,
      ),
      'regular': _layoutVariantJson(
        breakpoint: 'regular',
        slot: regularSlot,
      ),
      'expanded': _layoutVariantJson(
        breakpoint: 'expanded',
        slot: expandedSlot,
        width: expandedWidth,
      ),
    };

Map<String, Object?> _layoutVariantJson({
  required String breakpoint,
  required String slot,
  String width = 'comfortable',
}) =>
    <String, Object?>{
      'breakpoint': breakpoint,
      'slot': slot,
      'width': width,
      'spacing': 'normal',
      'screenMargin': 'compact',
      'visibleSecondaryElements': <Object?>[],
    };

void _expectCode(
  void Function() operation,
  String code,
  String path,
) {
  expect(
    operation,
    throwsA(
      isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', code)
          .having((error) => error.path, 'path', path),
    ),
  );
}

Map<String, Object?> _minimalManifestJson() => <String, Object?>{
      'packageFormat': 1,
      'gameId': 'games.example.minimal',
      'gameVersion': '1.0.0',
      'title': 'Minimal Adventure',
      'author': <String, Object?>{'name': 'Example Studio'},
      'compatibility': <String, Object?>{
        'minHubVersion': '1.0.0',
        'runtimeApi': '>=1.0.0 <2.0.0',
        'projectFormat': 'v2',
        'saveFormat': 1,
        'compatibilityId': 'main',
        'requiredCapabilities': <String>[],
      },
      'locales': <String, Object?>{
        'default': 'fr',
        'supported': <String>['fr'],
      },
      'content': <String, Object?>{
        'fileCount': 1,
        'totalBytes': 24,
        'treeSha256':
            'e21fddff269f718118bf1bda81c75726b57a9a34a9fd74497b53517069862a3b',
        'files': <Object?>[
          <String, Object?>{
            'path': 'project/project.json',
            'size': 24,
            'sha256':
                '1bcbf797acc5b8dc08dcba7f4da52a7d7b09f97cc5ec1905b8093d6f0faa097a',
            'mediaType': 'application/json',
          },
        ],
      },
    };

Map<String, Object?> _validSemanticThemeJson() => <String, Object?>{
      'primary': '#003A44',
      'onPrimary': '#FFFFFF',
      'background': '#F4F7FB',
      'surface': '#FFFFFF',
      'surfaceElevated': '#EAF0F8',
      'textPrimary': '#101827',
      'textSecondary': '#526176',
      'outline': '#65758B',
      'success': '#16794B',
      'warning': '#8A5100',
      'danger': '#B4233C',
      'titleSurface': '#D9F4F6',
      'dialogueSurface': '#FFFFFF',
      'menuSurface': '#EAF0F8',
      'overworldHudSurface': '#FFFFFF',
      'battleHudSurface': '#FFFFFF',
    };

Map<String, Object?> _emptyFile(String path) => <String, Object?>{
      'path': path,
      'size': 0,
      'sha256':
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    };

String _treeHashFromJson(Object files) => ContentTreeHasher.sha256Hex(
      (files as List<Object?>).map((value) {
        final json = value! as Map<String, Object?>;
        return GamePackageFileEntry(
          path: json['path']! as String,
          size: json['size']! as int,
          sha256: json['sha256']! as String,
          mediaType: json['mediaType'] as String?,
        );
      }),
    );
