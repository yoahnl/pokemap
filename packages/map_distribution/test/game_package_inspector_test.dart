import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('GamePackageInspector', () {
    const inspector = GamePackageInspector();

    test('inspects a valid package and produces an integrity receipt', () {
      final built = _build(<String, List<int>>{
        'project/project.json': _validProjectBytes(),
      });

      final result = inspector.inspect(built.packageBytes);

      expect(result.manifest.gameId, 'games.example.inspector');
      expect(result.signatureStatus, PackageSignatureStatus.notPresent);
      expect(result.payloadPaths, <String>['project/project.json']);
      expect(result.receipt.receiptVersion, 1);
      expect(result.receipt.treeSha256, result.manifest.content.treeSha256);
      expect(result.receipt.packageSha256, hasLength(64));
      expect(
        result.receipt.pokemonRuleset,
        PokemonRulesetProfile.pokeMapBetaV1Reference,
      );
      expect(
        result.receipt.toJson()['gameVersion'],
        result.manifest.gameVersion.toString(),
      );
    });

    test('inspects file packages with bounded random-access payload reads', () {
      final audio = Uint8List(2 * 1024 * 1024)
        ..setAll(0, ascii.encode('RIFF'))
        ..setAll(8, ascii.encode('WAVE'));
      final built = _build(<String, List<int>>{
        'project/assets/theme.wav': audio,
        'project/project.json': _validProjectBytes(),
      });
      final temporaryDirectory = Directory.systemTemp.createTempSync(
        'map_distribution_test_',
      );
      final packageFile = File(
        '${temporaryDirectory.path}/streamed.avelunegame',
      )..writeAsBytesSync(built.packageBytes, flush: true);
      try {
        final fromFile = inspector.inspectSourceSync(
          _FilePackageSource(packageFile),
        );
        final fromMemory = inspector.inspect(built.packageBytes);

        expect(fromFile.manifest.toJson(), fromMemory.manifest.toJson());
        expect(
          fromFile.receipt.packageSha256,
          fromMemory.receipt.packageSha256,
        );
        expect(
          fromFile.receipt.payloadBytes,
          audio.length + _validProjectBytes().length,
        );

        packageFile.writeAsBytesSync(
          _duplicateFirstCentralEntry(built.packageBytes),
          flush: true,
        );
        _expectCode(
          () => inspector.inspectSourceSync(_FilePackageSource(packageFile)),
          'duplicateEntry',
        );
      } finally {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });

    test('keeps UTF-8 and secret scanner state across 1 MiB chunks', () {
      const chunkSize = 1024 * 1024;
      final splitUtf8 = <int>[
        ...List<int>.filled(chunkSize - 1, 0x61),
        ...utf8.encode('é'),
      ];
      final valid = _rawPackage(<String, List<int>>{
        'legal/NOTICE.txt': splitUtf8,
        'project/project.json': _validProjectBytes(),
      });
      expect(
        inspector
            .inspectSourceSync(_MemoryPackageSource(valid))
            .manifest
            .gameId,
        'games.example.inspector',
      );

      final splitSecret = <int>[
        ...List<int>.filled(chunkSize - 3, 0x61),
        0x20,
        ...ascii.encode('sk-ABCDEFGHIJKLMNOP'),
      ];
      final hostile = _rawPackage(<String, List<int>>{
        'legal/NOTICE.txt': splitSecret,
        'project/project.json': _validProjectBytes(),
      });
      _expectCode(
        () => inspector.inspectSourceSync(_MemoryPackageSource(hostile)),
        'probableSecret',
      );
    });

    test('streams strict WebVTT validation beyond the retained header', () {
      const chunkSize = 1024 * 1024;
      final invalidWebVtt = <int>[
        ...ascii.encode('WEBVTT\n\n'),
        ...List<int>.filled(chunkSize, 0x61),
        0xc3,
      ];
      final hostile = _rawPackage(<String, List<int>>{
        'presentation/intro/captions.vtt': invalidWebVtt,
        'project/project.json': _validProjectBytes(),
      });

      _expectCode(
        () => inspector.inspectSourceSync(_MemoryPackageSource(hostile)),
        'executableContent',
      );
    });

    test('rejects missing, duplicate, and unlisted entries before install', () {
      final manifest = _build(<String, List<int>>{
        'project/project.json': _validProjectBytes(),
      }).manifest;
      _expectCode(
        () => inspector.inspect(
          _rawArchive(<String, List<int>>{
            'project/project.json': _validProjectBytes(),
          }),
        ),
        'manifestMissing',
      );
      _expectCode(
        () => inspector.inspect(
          _rawArchive(<String, List<int>>{
            'game-manifest.json': const GamePackageManifestCodec()
                .encodeCanonicalUtf8(manifest),
            'project/project.json': _validProjectBytes(),
            'project/maps/unlisted.json': _validProjectBytes(),
          }),
        ),
        'unlistedFile',
      );

      final valid = _build(<String, List<int>>{
        'project/project.json': _validProjectBytes(),
      });
      _expectCode(
        () =>
            inspector.inspect(_duplicateFirstCentralEntry(valid.packageBytes)),
        'duplicateEntry',
      );
    });

    test('rejects paths, ZIP features, metadata, and quotas', () {
      final manifest = _build(<String, List<int>>{
        'project/project.json': _validProjectBytes(),
      }).manifest;
      final manifestBytes = const GamePackageManifestCodec()
          .encodeCanonicalUtf8(manifest);

      _expectCode(
        () => inspector.inspect(
          _rawArchive(<String, List<int>>{
            'game-manifest.json': manifestBytes,
            '../escape.json': <int>[1],
          }),
        ),
        'invalidPath',
      );
      _expectCode(
        () => inspector.inspect(
          _rawArchive(<String, List<int>>{
            'game-manifest.json': manifestBytes,
            'project/project.json': _validProjectBytes(),
          }, compression: CompressionType.deflate),
        ),
        'unsupportedZipFeature',
      );
      _expectCode(
        () =>
            const GamePackageInspector(
              policy: GamePackageSecurityPolicy(maxArchiveBytes: 10),
            ).inspect(
              _build(<String, List<int>>{
                'project/project.json': _validProjectBytes(),
              }).packageBytes,
            ),
        'archiveTooLarge',
      );
      _expectCode(
        () =>
            const GamePackageInspector(
              policy: GamePackageSecurityPolicy(maxFileBytes: 0),
            ).inspect(
              _build(<String, List<int>>{
                'project/project.json': _validProjectBytes(),
              }).packageBytes,
            ),
        'entryTooLarge',
      );
    });

    test(
      'rejects tampering, executable content, secrets, and escaping refs',
      () {
        final tampered = Uint8List.fromList(
          _build(<String, List<int>>{
            'project/project.json': _validProjectBytes(),
          }).packageBytes,
        );
        final payloadOffset = _localDataOffset(tampered, 1);
        tampered[payloadOffset] = 2;
        _expectCode(() => inspector.inspect(tampered), 'hashMismatch');

        _expectCode(
          () => inspector.inspect(
            _rawPackage(<String, List<int>>{
              'project/project.json': _validProjectBytes(),
              'project/assets/run.dart': utf8.encode('void main() {}'),
            }),
          ),
          'executableContent',
        );
        _expectCode(
          () => inspector.inspect(
            _rawPackage(<String, List<int>>{
              'project/project.json': utf8.encode(
                '{"mistralApiKey":"do-not-distribute"}',
              ),
            }),
          ),
          'probableSecret',
        );
        _expectCode(
          () => inspector.inspect(
            _rawPackage(<String, List<int>>{
              'project/project.json': utf8.encode(
                '{"assetPath":"../../outside.png"}',
              ),
            }),
          ),
          'referenceEscapesRoot',
        );
        _expectCode(
          () => inspector.inspect(
            _rawPackage(<String, List<int>>{
              'project/project.json': utf8.encode(
                '{"assetPaths":["../../outside.png"]}',
              ),
            }),
          ),
          'referenceEscapesRoot',
        );
      },
    );

    test(
      'rejects nested runtime references, URI schemes, and ambiguous JSON',
      () {
        for (final source in <String>[
          '{"assets":{"main":"../../outside.png"}}',
          '{"pokemon":{"speciesDir":"/tmp/outside"}}',
          '{"pokemon":{"dataRoot":"C:outside"}}',
          '{"pokemon":{"catalogFiles":{"moves":"smb://host/moves.json"}}}',
          '{"assetUrl":"ws://host/asset.png"}',
        ]) {
          _expectCode(
            () => inspector.inspect(
              _rawPackage(<String, List<int>>{
                'project/project.json': utf8.encode(source),
              }),
            ),
            'referenceEscapesRoot',
          );
        }
        _expectCode(
          () => inspector.inspect(
            _rawPackage(<String, List<int>>{
              'project/project.json': utf8.encode(
                '{"apiKey":"","apiKey":"secret"}',
              ),
            }),
          ),
          'executableContent',
        );
        _expectCode(
          () =>
              const GamePackageInspector(
                policy: GamePackageSecurityPolicy(maxJsonNodes: 1),
              ).inspect(
                _rawPackage(<String, List<int>>{
                  'project/project.json': utf8.encode('{"value":1}'),
                }),
              ),
          'entryTooLarge',
        );
      },
    );

    test(
      'does not treat profile payloads or fingerprints as file references',
      () {
        expect(
          () => inspector.inspect(
            _rawPackage(<String, List<int>>{
              'project/project.json': utf8.encode(
                jsonEncode(<String, Object?>{
                  'name': 'Inspector Test',
                  'version': 'v6',
                  'maps': <Object?>[],
                  'tilesets': <Object?>[],
                  'collisionProfile': <String, Object?>{
                    'visualMask': <String, Object?>{
                      'dataBase64': '/P////////////8=',
                    },
                  },
                  'assetFingerprint': 'sha256:a377c82cce126373f4f824719cc1a775',
                }),
              ),
            }),
          ),
          returnsNormally,
        );
      },
    );

    test('enforces the selected trust channel with an injected verifier', () {
      final projectBytes = _validProjectBytes();
      final unsigned = _build(<String, List<int>>{
        'project/project.json': projectBytes,
      });
      _expectCodeBoth(
        const GamePackageInspector(
          trustRequirement: PackageTrustRequirement.signatureRequired,
        ),
        unsigned.packageBytes,
        'signatureRequired',
        reason: 'HP-031',
      );

      final signedManifest = unsigned.manifest.copyWith(
        signature: const GamePackageSignature(
          algorithm: 'ed25519',
          keyId: 'publisher:key',
          value:
              'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
        ),
      );
      final signed = const GamePackageBuilder().build(
        manifest: signedManifest,
        payloadFiles: <String, List<int>>{'project/project.json': projectBytes},
      );
      final accepted = GamePackageInspector(
        trustRequirement: PackageTrustRequirement.signatureRequired,
        signatureVerifier: _AcceptingVerifier(),
      ).inspect(signed.packageBytes);
      expect(accepted.signatureStatus, PackageSignatureStatus.verified);

      _expectCodeBoth(
        GamePackageInspector(
          trustRequirement: PackageTrustRequirement.signatureRequired,
          signatureVerifier: _RejectingVerifier(),
        ),
        signed.packageBytes,
        'signatureInvalid',
        reason: 'HP-030',
      );
    });

    test('rejects trust and compatibility before scanning payload bytes', () {
      final valid = _build(<String, List<int>>{
        'project/project.json': _validProjectBytes(),
      });
      final tampered = Uint8List.fromList(valid.packageBytes);
      tampered[_localDataOffset(tampered, 1)] ^= 0xff;

      _expectCode(
        () => const GamePackageInspector(
          trustRequirement: PackageTrustRequirement.signatureRequired,
        ).inspect(tampered),
        'signatureRequired',
      );
      _expectCode(
        () => GamePackageInspector(
          hostCompatibility: GamePackageHostCompatibility(
            hubVersion: Version.parse('0.9.0'),
            runtimeApiVersion: Version.parse('1.4.0'),
            capabilities: const <String>{},
            supportedProjectFormats: const <String>{'v6'},
            currentProjectFormat: 'v6',
            supportedSaveFormats: const <int>{1},
          ),
        ).inspect(tampered),
        'hubTooOld',
      );

      try {
        GamePackageInspector(
          hostCompatibility: GamePackageHostCompatibility(
            hubVersion: Version.parse('0.9.0'),
            runtimeApiVersion: Version.parse('3.0.0'),
            capabilities: const <String>{},
            supportedProjectFormats: const <String>{'v6'},
            currentProjectFormat: 'v6',
            supportedSaveFormats: const <int>{1},
          ),
        ).inspect(tampered);
        fail('Expected compatibility rejection.');
      } on GamePackageFormatException catch (error) {
        expect(error.relatedCodes, <String>[
          'hubTooOld',
          'runtimeApiUnsupported',
        ]);
      }
    });

    test('covers hostile inventory, collision, and metadata cases', () {
      final withListedMap = _build(<String, List<int>>{
        'project/maps/listed.json': _validProjectBytes(),
        'project/project.json': _validProjectBytes(),
      });
      _expectCode(
        () => inspector.inspect(
          _rawArchive(<String, List<int>>{
            'game-manifest.json': const GamePackageManifestCodec()
                .encodeCanonicalUtf8(withListedMap.manifest),
            'project/project.json': _validProjectBytes(),
          }),
        ),
        'missingFile',
      );

      final valid = _build(<String, List<int>>{
        'project/project.json': _validProjectBytes(),
      });
      final manifestBytes = const GamePackageManifestCodec()
          .encodeCanonicalUtf8(valid.manifest);
      _expectCode(
        () => inspector.inspect(
          _rawArchive(<String, List<int>>{
            'game-manifest.json': manifestBytes,
            'presentation/Icon.png': <int>[1],
            'presentation/icon.png': <int>[1],
            'project/project.json': _validProjectBytes(),
          }),
        ),
        'pathCollision',
      );
      _expectCode(
        () =>
            inspector.inspect(_setFirstCentralMode(valid.packageBytes, 0x81ed)),
        'executableContent',
      );
      _expectCode(
        () => const GamePackageInspector(
          policy: GamePackageSecurityPolicy(maxManifestBytes: 1),
        ).inspect(valid.packageBytes),
        'manifestTooLarge',
      );
      _expectCode(
        () => const GamePackageInspector(
          policy: GamePackageSecurityPolicy(maxPayloadEntries: 0),
        ).inspect(valid.packageBytes),
        'entryCountExceeded',
      );
      _expectCode(
        () => const GamePackageInspector(
          policy: GamePackageSecurityPolicy(maxTotalPayloadBytes: 0),
        ).inspect(valid.packageBytes),
        'archiveTooLarge',
      );
    });

    test('covers hostile media, decoded dimensions, and secret patterns', () {
      final oversizedPng = Uint8List(24)
        ..setAll(0, <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
        ..setAll(12, ascii.encode('IHDR'));
      ByteData.sublistView(oversizedPng)
        ..setUint32(16, 8193)
        ..setUint32(20, 1);
      _expectCode(
        () => inspector.inspect(
          _rawPackage(<String, List<int>>{
            'presentation/icon.png': oversizedPng,
            'project/project.json': _validProjectBytes(),
          }),
        ),
        'decodedAssetQuotaExceeded',
      );
      _expectCode(
        () => inspector.inspect(
          _rawPackage(<String, List<int>>{
            'project/assets/fake.png': _validProjectBytes(),
            'project/project.json': _validProjectBytes(),
          }),
        ),
        'executableContent',
      );
      _expectCode(
        () => inspector.inspect(
          _rawPackage(<String, List<int>>{
            'project/project.json': utf8.encode(
              jsonEncode(<String, Object?>{
                'note': '-----BEGIN PRIVATE KEY-----',
              }),
            ),
          }),
        ),
        'probableSecret',
      );
      _expectCode(
        () => inspector.inspect(
          _rawPackage(<String, List<int>>{
            'project/project.json': utf8.encode(
              jsonEncode(<String, Object?>{
                'homepage': 'https://user:password@example.invalid',
              }),
            ),
          }),
        ),
        'probableSecret',
      );
      _expectCode(
        () => inspector.inspect(
          _rawPackage(<String, List<int>>{
            'project/assets/archive.png': <int>[0x50, 0x4b, 0x03, 0x04],
            'project/project.json': _validProjectBytes(),
          }),
        ),
        'executableContent',
      );
    });

    test(
      'scans manifest metadata and binary payloads for explicit secrets',
      () {
        _expectCode(
          () => inspector.inspect(
            _rawPackage(<String, List<int>>{
              'project/project.json': _validProjectBytes(),
            }, mutateManifest: (json) => json['title'] = 'sk-ABCDEFGHIJKLMNOP'),
          ),
          'probableSecret',
        );

        final png = Uint8List(1024 * 1024 + 128)
          ..setAll(0, <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
          ..setAll(12, ascii.encode('IHDR'))
          ..setAll(1024 * 1024 + 32, ascii.encode('sk-ABCDEFGHIJKLMNOP'));
        ByteData.sublistView(png)
          ..setUint32(16, 1)
          ..setUint32(20, 1);
        final hostile = _rawPackage(<String, List<int>>{
          'presentation/icon.png': png,
          'project/project.json': _validProjectBytes(),
        });
        _expectCode(() => inspector.inspect(hostile), 'probableSecret');

        final temporaryDirectory = Directory.systemTemp.createTempSync(
          'map_distribution_secret_',
        );
        final packageFile = File(
          '${temporaryDirectory.path}/secret.avelunegame',
        )..writeAsBytesSync(hostile, flush: true);
        try {
          _expectCode(
            () => inspector.inspectSourceSync(_FilePackageSource(packageFile)),
            'probableSecret',
          );
        } finally {
          temporaryDirectory.deleteSync(recursive: true);
        }
      },
    );

    test('does not parse non-ASCII compressed media as a credential URI', () {
      final ogg = <int>[
        ...ascii.encode('OggST://'),
        0x96,
        0x7d,
        0xa0,
        0x68,
        0xc7,
        0xd4,
        0x3e,
        0x27,
        0x40,
      ];

      expect(
        () => inspector.inspect(
          _rawPackage(<String, List<int>>{
            'project/assets/cry.ogg': ogg,
            'project/project.json': _validProjectBytes(),
          }),
        ),
        returnsNormally,
      );
    });

    test('distinguishes narrative secret assets from credential stores', () {
      expect(
        () => inspector.inspect(
          _rawPackage(<String, List<int>>{
            'project/assets/items/secret-key.png': _oversizedPng(width: 1),
            'project/assets/items/secret-potion.png': _oversizedPng(width: 1),
            'project/project.json': _validProjectBytes(),
          }),
        ),
        returnsNormally,
      );

      _expectCode(
        () => inspector.inspect(
          _rawPackage(<String, List<int>>{
            'project/data/secrets.json': utf8.encode('{}'),
            'project/project.json': _validProjectBytes(),
          }),
        ),
        'probableSecret',
      );
    });

    test('executes hostile ZIP/content cases through both inspector backends', () {
      final projectBytes = _validProjectBytes();
      final valid = _build(<String, List<int>>{
        'project/project.json': projectBytes,
      });
      final manifestBytes = const GamePackageManifestCodec()
          .encodeCanonicalUtf8(valid.manifest);
      final withMap = _build(<String, List<int>>{
        'project/maps/listed.json': utf8.encode('{}'),
        'project/project.json': projectBytes,
      });
      final hostile =
          <
            ({
              String id,
              List<int> bytes,
              String code,
              GamePackageInspector inspector,
            })
          >[
            (
              id: 'HP-001',
              bytes: _rawArchive(<String, List<int>>{
                'project/project.json': projectBytes,
              }),
              code: 'manifestMissing',
              inspector: inspector,
            ),
            (
              id: 'HP-002/HP-008',
              bytes: _duplicateFirstCentralEntry(valid.packageBytes),
              code: 'duplicateEntry',
              inspector: inspector,
            ),
            for (final pathCase in <({String id, String path})>[
              (id: 'HP-003-absolute', path: '/absolute.json'),
              (id: 'HP-003-drive', path: 'C:/drive.json'),
              (id: 'HP-003-UNC', path: r'\\server\share.json'),
              (id: 'HP-004-backslash', path: r'project\backslash.json'),
              (id: 'HP-004-parent', path: 'project/../escape.json'),
              (id: 'HP-004-dot', path: 'project/./dot.json'),
              (id: 'HP-004-empty', path: 'project//empty.json'),
              (id: 'HP-005-NUL', path: 'project/\u0000.json'),
              (id: 'HP-005-control', path: 'project/\u0001.json'),
              (id: 'HP-006-NFD', path: 'presentation/e\u0301.png'),
              (
                id: 'HP-017-depth',
                path:
                    'project/${List<String>.filled(33, 'a').join('/')}/x.json',
              ),
              (id: 'HP-017-segment', path: 'project/${'a' * 256}.json'),
              (
                id: 'HP-017-path',
                path:
                    'project/${<String>[...List<String>.filled(16, 'a' * 28), 'a' * 34].join('/')}/x.json',
              ),
            ])
              (
                id: pathCase.id,
                bytes: _rawArchive(<String, List<int>>{
                  'game-manifest.json': manifestBytes,
                  pathCase.path: <int>[1],
                  'project/project.json': projectBytes,
                }),
                code: 'invalidPath',
                inspector: inspector,
              ),
            (
              id: 'HP-005',
              bytes: _corruptLastCentralAndLocalName(
                _rawArchive(<String, List<int>>{
                  'game-manifest.json': manifestBytes,
                  'project/project.json': projectBytes,
                  'project/x.json': utf8.encode('{}'),
                }),
              ),
              code: 'invalidPath',
              inspector: inspector,
            ),
            (
              id: 'HP-007',
              bytes: _rawArchive(<String, List<int>>{
                'game-manifest.json': manifestBytes,
                'presentation/Icon.png': <int>[1],
                'presentation/icon.png': <int>[1],
                'project/project.json': projectBytes,
              }),
              code: 'pathCollision',
              inspector: inspector,
            ),
            for (final mode in <int>[0xa1a4, 0x21a4, 0x61a4, 0x11a4])
              (
                id: 'HP-009:${mode.toRadixString(16)}',
                bytes: _setFirstCentralMode(valid.packageBytes, mode),
                code: 'unsupportedEntryType',
                inspector: inspector,
              ),
            (
              id: 'HP-009',
              bytes: _setFirstCentralMode(valid.packageBytes, 0xa1ff),
              code: 'unsupportedEntryType',
              inspector: inspector,
            ),
            (
              id: 'HP-009-hardlink-extra',
              bytes: _setFirstCentralExtraLength(valid.packageBytes, 1),
              code: 'unsupportedEntryType',
              inspector: inspector,
            ),
            (
              id: 'HP-010',
              bytes: _setFirstCentralMode(valid.packageBytes, 0x81ed),
              code: 'executableContent',
              inspector: inspector,
            ),
            (
              id: 'HP-011-compression',
              bytes: _rawArchive(<String, List<int>>{
                'game-manifest.json': manifestBytes,
                'project/project.json': projectBytes,
              }, compression: CompressionType.deflate),
              code: 'unsupportedZipFeature',
              inspector: inspector,
            ),
            (
              id: 'HP-011-flags',
              bytes: _setFirstEntryFlags(valid.packageBytes, 0x0801),
              code: 'unsupportedZipFeature',
              inspector: inspector,
            ),
            (
              id: 'HP-011-data-descriptor',
              bytes: _setFirstEntryFlags(valid.packageBytes, 0x0808),
              code: 'unsupportedZipFeature',
              inspector: inspector,
            ),
            (
              id: 'HP-012',
              bytes: _aliasSecondLocalOffset(valid.packageBytes),
              code: 'invalidZipStructure',
              inspector: inspector,
            ),
            (
              id: 'HP-013',
              bytes: valid.packageBytes,
              code: 'entryCountExceeded',
              inspector: const GamePackageInspector(
                policy: GamePackageSecurityPolicy(maxPayloadEntries: 0),
              ),
            ),
            (
              id: 'HP-014',
              bytes: valid.packageBytes,
              code: 'entryTooLarge',
              inspector: GamePackageInspector(
                policy: GamePackageSecurityPolicy(
                  maxFileBytes: projectBytes.length - 1,
                ),
              ),
            ),
            (
              id: 'HP-015',
              bytes: valid.packageBytes,
              code: 'archiveTooLarge',
              inspector: GamePackageInspector(
                policy: GamePackageSecurityPolicy(
                  maxTotalPayloadBytes: projectBytes.length - 1,
                ),
              ),
            ),
            (
              id: 'HP-016',
              bytes: valid.packageBytes,
              code: 'manifestTooLarge',
              inspector: const GamePackageInspector(
                policy: GamePackageSecurityPolicy(maxManifestBytes: 1),
              ),
            ),
            (
              id: 'HP-018',
              bytes: _truncateLastStoredEntry(
                _rawPackage(<String, List<int>>{
                  'project/project.json': projectBytes,
                }),
              ),
              code: 'sizeMismatch',
              inspector: inspector,
            ),
            (
              id: 'HP-019',
              bytes: _rawPackage(
                <String, List<int>>{'project/project.json': projectBytes},
                mutateManifest: (json) {
                  final content = json['content']! as Map<String, Object?>;
                  final file =
                      (content['files']! as List).single
                          as Map<String, Object?>;
                  file['sha256'] = '0' * 64;
                  _recomputeTree(content);
                },
              ),
              code: 'hashMismatch',
              inspector: inspector,
            ),
            (
              id: 'HP-020',
              bytes: _rawPackage(
                <String, List<int>>{'project/project.json': projectBytes},
                mutateManifest: (json) {
                  (json['content']! as Map<String, Object?>)['treeSha256'] =
                      '0' * 64;
                },
                encodeUncheckedManifest: true,
              ),
              code: 'treeHashMismatch',
              inspector: inspector,
            ),
            (
              id: 'HP-021',
              bytes: _rawArchive(<String, List<int>>{
                'game-manifest.json': manifestBytes,
                'project/maps/unlisted.json': utf8.encode('{}'),
                'project/project.json': projectBytes,
              }),
              code: 'unlistedFile',
              inspector: inspector,
            ),
            (
              id: 'HP-022',
              bytes: _rawArchive(<String, List<int>>{
                'game-manifest.json': const GamePackageManifestCodec()
                    .encodeCanonicalUtf8(withMap.manifest),
                'project/project.json': projectBytes,
              }),
              code: 'missingFile',
              inspector: inspector,
            ),
            (
              id: 'HP-024',
              bytes: _rawPackage(<String, List<int>>{
                'project/project.json': projectBytes,
                'project/assets/run.dart': utf8.encode('void main() {}'),
              }),
              code: 'executableContent',
              inspector: inspector,
            ),
            for (final executable in <MapEntry<String, List<int>>>[
              MapEntry<String, List<int>>(
                'project/assets/run.sh',
                utf8.encode('#!/bin/sh'),
              ),
              const MapEntry<String, List<int>>(
                'project/assets/program.exe',
                <int>[0x4d, 0x5a, 0, 0],
              ),
              const MapEntry<String, List<int>>(
                'project/assets/program.bin',
                <int>[0x7f, 0x45, 0x4c, 0x46],
              ),
              const MapEntry<String, List<int>>(
                'project/assets/plugin.dll',
                <int>[0x4d, 0x5a, 0, 0],
              ),
              const MapEntry<String, List<int>>(
                'project/assets/macho.png',
                <int>[0xfe, 0xed, 0xfa, 0xcf],
              ),
            ])
              (
                id: 'HP-024/025:${executable.key}',
                bytes: _rawPackage(<String, List<int>>{
                  executable.key: executable.value,
                  'project/project.json': projectBytes,
                }),
                code: 'executableContent',
                inspector: inspector,
              ),
            (
              id: 'HP-025',
              bytes: _rawPackage(<String, List<int>>{
                'project/assets/archive.png': <int>[0x50, 0x4b, 0x03, 0x04],
                'project/project.json': projectBytes,
              }),
              code: 'executableContent',
              inspector: inspector,
            ),
            (
              id: 'HP-026',
              bytes: _rawPackage(<String, List<int>>{
                'project/project.json': utf8.encode(
                  '{"mistralApiKey":"not-for-release"}',
                ),
              }),
              code: 'probableSecret',
              inspector: inspector,
            ),
            (
              id: 'HP-027',
              bytes: _rawPackage(<String, List<int>>{
                'project/project.json': utf8.encode(
                  '{"note":"-----BEGIN PRIVATE KEY-----"}',
                ),
              }),
              code: 'probableSecret',
              inspector: inspector,
            ),
            (
              id: 'HP-027-credential-uri',
              bytes: _rawPackage(<String, List<int>>{
                'project/project.json': utf8.encode(
                  '{"note":"https://player:secret@example.invalid/data"}',
                ),
              }),
              code: 'probableSecret',
              inspector: inspector,
            ),
            (
              id: 'HP-028',
              bytes: _rawPackage(<String, List<int>>{
                'project/project.json': utf8.encode(
                  '{"pokemon":{"speciesDir":"/tmp/outside"}}',
                ),
              }),
              code: 'referenceEscapesRoot',
              inspector: inspector,
            ),
            (
              id: 'HP-029-dimension',
              bytes: _rawPackage(<String, List<int>>{
                'presentation/icon.png': _oversizedPng(),
                'project/project.json': projectBytes,
              }),
              code: 'decodedAssetQuotaExceeded',
              inspector: inspector,
            ),
            (
              id: 'HP-029-pixels',
              bytes: _rawPackage(<String, List<int>>{
                'presentation/icon.png': _oversizedPng(
                  width: 8192,
                  height: 8193,
                ),
                'project/project.json': projectBytes,
              }),
              code: 'decodedAssetQuotaExceeded',
              inspector: inspector,
            ),
            (
              id: 'HP-036',
              bytes: _rawPackage(<String, List<int>>{
                'project/project.json': utf8.encode(
                  '${List<String>.filled(129, '{"v":').join()}0'
                  '${List<String>.filled(129, '}').join()}',
                ),
              }),
              code: 'entryTooLarge',
              inspector: inspector,
            ),
            (
              id: 'HP-037',
              bytes: _rawPackage(<String, List<int>>{
                'project/project.json': utf8.encode(
                  jsonEncode(<String, Object?>{
                    'name': 'Too deep',
                    'version': 'v6',
                    'maps': <Object?>[],
                    'tilesets': <Object?>[],
                    'groups': <Object?>[
                      for (var index = 0; index < 33; index++)
                        <String, Object?>{
                          'id': 'g$index',
                          'parentGroupId': index == 0 ? null : 'g${index - 1}',
                        },
                    ],
                  }),
                ),
              }),
              code: 'projectComplexityExceeded',
              inspector: inspector,
            ),
            (
              id: 'HP-038',
              bytes: _rawPackage(<String, List<int>>{
                'project/debug/runtime_host_launch_save.json': utf8.encode(
                  '{}',
                ),
                'project/project.json': projectBytes,
              }),
              code: 'executableContent',
              inspector: inspector,
            ),
            (
              id: 'HP-039',
              bytes: _rawPackage(<String, List<int>>{
                'presentation/icon.png': utf8.encode(
                  'prefix sk-ABCDEFGHIJKLMNOP suffix',
                ),
                'project/project.json': projectBytes,
              }),
              code: 'probableSecret',
              inspector: inspector,
            ),
          ];

      for (final testCase in hostile) {
        _expectCodeBoth(
          testCase.inspector,
          testCase.bytes,
          testCase.code,
          reason: testCase.id,
        );
      }
    });

    test('never raises the normative Phase 0 security ceilings', () {
      const policy = GamePackageSecurityPolicy(
        maxArchiveBytes: GamePackageSecurityPolicy.maxArchiveBytesV1 + 1,
        maxManifestBytes: GamePackageSecurityPolicy.maxManifestBytesV1 + 1,
        maxPayloadEntries: GamePackageSecurityPolicy.maxPayloadEntriesV1 + 1,
        maxProjectCollectionEntries:
            GamePackageSecurityPolicy.maxProjectCollectionEntriesV1 + 1,
        maxProjectHierarchyEntries:
            GamePackageSecurityPolicy.maxProjectHierarchyEntriesV1 + 1,
        maxProjectHierarchyDepth:
            GamePackageSecurityPolicy.maxProjectHierarchyDepthV1 + 1,
      );

      expect(
        policy.maxArchiveBytes,
        GamePackageSecurityPolicy.maxArchiveBytesV1,
      );
      expect(
        policy.maxManifestBytes,
        GamePackageSecurityPolicy.maxManifestBytesV1,
      );
      expect(
        policy.maxPayloadEntries,
        GamePackageSecurityPolicy.maxPayloadEntriesV1,
      );
      expect(
        policy.maxProjectCollectionEntries,
        GamePackageSecurityPolicy.maxProjectCollectionEntriesV1,
      );
      expect(
        policy.maxProjectHierarchyEntries,
        GamePackageSecurityPolicy.maxProjectHierarchyEntriesV1,
      );
      expect(
        policy.maxProjectHierarchyDepth,
        GamePackageSecurityPolicy.maxProjectHierarchyDepthV1,
      );
    });

    test('rejects the exact normative byte and entry overflows', () {
      _expectCodeBoth(
        inspector,
        _eocdWithEntryCount(GamePackageSecurityPolicy.maxPayloadEntriesV1 + 2),
        'entryCountExceeded',
        reason: 'HP-013: 20,001 payload entries plus the manifest',
      );

      final oversizedProject = _sparsePackageWithVirtualProject(
        GamePackageSecurityPolicy.maxFileBytesV1 + 1,
      );
      _expectCode(
        () => inspector.inspectSourceSync(oversizedProject),
        'entryTooLarge',
      );
      _expectCode(
        () =>
            const GamePackageInspector(
              trustRequirement: PackageTrustRequirement.signatureRequired,
            ).inspectSourceSync(
              _sparsePackageWithVirtualProject(
                GamePackageSecurityPolicy.maxFileBytesV1 + 1,
              ),
            ),
        'entryTooLarge',
      );

      _expectCode(
        () => inspector.inspectSourceSync(
          _LengthOnlyPackageSource(
            GamePackageSecurityPolicy.maxArchiveBytesV1 + 1,
          ),
        ),
        'archiveTooLarge',
      );

      _expectCode(
        () => inspector.inspectSourceSync(
          _SparseStoredZipSource(<_SparseZipEntry>[
            _SparseZipEntry.virtual(
              'game-manifest.json',
              GamePackageSecurityPolicy.maxManifestBytesV1 + 1,
            ),
          ]),
        ),
        'manifestTooLarge',
      );
    });

    test('HP-032 accepts a valid package at every configured boundary', () {
      final projectBytes = _validProjectBytes();
      final exactPath = 'project/${'a' * 248}/${'b' * 250}.json';
      final exactDepth =
          'project/${List<String>.filled(30, 'd').join('/')}/leaf.json';
      expect(utf8.encode(exactPath), hasLength(512));
      expect(exactPath.split('/').last, hasLength(255));
      expect(exactDepth.split('/'), hasLength(32));
      final builtAtPathLimits = _build(<String, List<int>>{
        exactDepth: utf8.encode('{}'),
        exactPath: utf8.encode('{}'),
        'project/project.json': projectBytes,
      });
      expect(
        inspector.inspect(builtAtPathLimits.packageBytes).payloadPaths,
        containsAll(<String>[exactDepth, exactPath]),
      );

      final built = _build(<String, List<int>>{
        'project/project.json': projectBytes,
      });
      final manifestBytes = const GamePackageManifestCodec()
          .encodeCanonicalUtf8(built.manifest);
      final exactInspector = GamePackageInspector(
        policy: GamePackageSecurityPolicy(
          maxArchiveBytes: built.packageBytes.length,
          maxManifestBytes: manifestBytes.length,
          maxPayloadEntries: 1,
          maxFileBytes: projectBytes.length,
          maxTotalPayloadBytes: projectBytes.length,
          maxJsonBytes: projectBytes.length,
        ),
      );

      expect(
        exactInspector.inspect(built.packageBytes).manifest.gameId,
        built.manifest.gameId,
      );
      expect(
        exactInspector
            .inspectSourceSync(_MemoryPackageSource(built.packageBytes))
            .manifest
            .gameId,
        built.manifest.gameId,
      );
    });

    test('redacts hostile paths and messages before diagnostics escape', () {
      final error = GamePackageFormatException(
        code: 'invalidPath',
        path: 'project/my-secret-sk-ABCDEFGHIJKLMNOP.json',
        message: 'Unknown\nfield sk-ABCDEFGHIJKLMNOP',
      );

      expect(error.path, isNot(contains('sk-')));
      expect(error.message, isNot(contains('sk-')));
      expect(error.message, isNot(contains('\n')));
      expect(error.toString(), isNot(contains('sk-')));
    });
  });
}

final class _AcceptingVerifier implements GamePackageSignatureVerifier {
  @override
  bool verify({
    required String keyId,
    required List<int> preimage,
    required List<int> signature,
  }) =>
      keyId == 'publisher:key' && preimage.isNotEmpty && signature.length == 64;
}

final class _RejectingVerifier implements GamePackageSignatureVerifier {
  @override
  bool verify({
    required String keyId,
    required List<int> preimage,
    required List<int> signature,
  }) => false;
}

final class _FilePackageSource implements RandomAccessPackageSource {
  const _FilePackageSource(this.file);

  final File file;

  @override
  int get length => file.lengthSync();

  @override
  Uint8List readAtSync(int offset, int length) {
    final handle = file.openSync();
    try {
      handle.setPositionSync(offset);
      return handle.readSync(length);
    } finally {
      handle.closeSync();
    }
  }
}

final class _MemoryPackageSource implements RandomAccessPackageSource {
  _MemoryPackageSource(List<int> bytes) : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;

  @override
  int get length => bytes.length;

  @override
  Uint8List readAtSync(int offset, int length) =>
      Uint8List.sublistView(bytes, offset, offset + length);
}

final class _LengthOnlyPackageSource implements RandomAccessPackageSource {
  const _LengthOnlyPackageSource(this.length);

  @override
  final int length;

  @override
  Uint8List readAtSync(int offset, int length) {
    throw StateError('An oversized source must be rejected before it is read.');
  }
}

final class _SparseZipEntry {
  _SparseZipEntry.bytes(this.name, List<int> bytes)
    : size = bytes.length,
      crc32 = getCrc32(bytes),
      bytes = Uint8List.fromList(bytes);

  const _SparseZipEntry.virtual(this.name, this.size) : crc32 = 0, bytes = null;

  final String name;
  final int size;
  final int crc32;
  final Uint8List? bytes;
}

final class _SparseStoredZipSource implements RandomAccessPackageSource {
  _SparseStoredZipSource(List<_SparseZipEntry> inputEntries) {
    final entries = inputEntries.toList()
      ..sort(
        (left, right) => PackagePathPolicy.compareUtf8(left.name, right.name),
      );
    final central = BytesBuilder(copy: false);
    var localOffset = 0;
    for (final entry in entries) {
      final nameBytes = utf8.encode(entry.name);
      final localHeader = _storedLocalHeader(
        nameBytes: nameBytes,
        crc32: entry.crc32,
        size: entry.size,
      );
      _segments.add(_SparseSegment(localOffset, localHeader));
      final dataOffset = localOffset + localHeader.length;
      if (entry.bytes != null) {
        _segments.add(_SparseSegment(dataOffset, entry.bytes!));
      }
      central.add(
        _storedCentralHeader(
          nameBytes: nameBytes,
          crc32: entry.crc32,
          size: entry.size,
          localOffset: localOffset,
        ),
      );
      localOffset = dataOffset + entry.size;
    }
    final centralBytes = central.takeBytes();
    _segments.add(_SparseSegment(localOffset, centralBytes));
    final eocd = _storedEocd(
      entryCount: entries.length,
      centralSize: centralBytes.length,
      centralOffset: localOffset,
    );
    _segments.add(_SparseSegment(localOffset + centralBytes.length, eocd));
    length = localOffset + centralBytes.length + eocd.length;
  }

  final List<_SparseSegment> _segments = <_SparseSegment>[];

  @override
  late final int length;

  @override
  Uint8List readAtSync(int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > this.length) {
      throw RangeError.range(offset + length, 0, this.length);
    }
    final result = Uint8List(length);
    final requestedEnd = offset + length;
    for (final segment in _segments) {
      final segmentEnd = segment.offset + segment.bytes.length;
      final overlapStart = offset > segment.offset ? offset : segment.offset;
      final overlapEnd = requestedEnd < segmentEnd ? requestedEnd : segmentEnd;
      if (overlapStart >= overlapEnd) continue;
      result.setRange(
        overlapStart - offset,
        overlapEnd - offset,
        segment.bytes,
        overlapStart - segment.offset,
      );
    }
    return result;
  }
}

final class _SparseSegment {
  const _SparseSegment(this.offset, this.bytes);

  final int offset;
  final Uint8List bytes;
}

List<int> _validProjectBytes({String name = 'Inspector Test'}) => utf8.encode(
  jsonEncode(<String, Object?>{
    'name': name,
    'version': 'v6',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  }),
);

Uint8List _oversizedPng({int width = 8193, int height = 1}) {
  final bytes = Uint8List(24)
    ..setAll(0, <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    ..setAll(12, ascii.encode('IHDR'));
  ByteData.sublistView(bytes)
    ..setUint32(16, width)
    ..setUint32(20, height);
  return bytes;
}

GamePackageBuildResult _build(Map<String, List<int>> payload) {
  final content = const GamePackageInventoryBuilder().build(
    const <String, List<int>>{
      'project/project.json': <int>[0],
    },
  );
  final manifest = const GamePackageManifestCodec().decodeJson(
    <String, Object?>{
      'packageFormat': 1,
      'gameId': 'games.example.inspector',
      'gameVersion': '1.0.0',
      'title': 'Inspector',
      'author': <String, Object?>{'name': 'Example'},
      'compatibility': <String, Object?>{
        'minHubVersion': '1.0.0',
        'runtimeApi': '>=1.0.0 <2.0.0',
        'projectFormat': 'v6',
        'saveFormat': 1,
        'compatibilityId': 'main',
        'requiredCapabilities': <String>[],
      },
      'locales': <String, Object?>{
        'default': 'fr',
        'supported': <String>['fr'],
      },
      'content': content.toJson(),
    },
  );
  return const GamePackageBuilder().build(
    manifest: manifest,
    payloadFiles: payload,
  );
}

List<int> _rawPackage(
  Map<String, List<int>> payload, {
  void Function(Map<String, Object?> manifest)? mutateManifest,
  bool encodeUncheckedManifest = false,
}) {
  final content = const GamePackageInventoryBuilder().build(payload);
  final manifestJson = <String, Object?>{
    'packageFormat': 1,
    'gameId': 'games.example.inspector',
    'gameVersion': '1.0.0',
    'title': 'Inspector',
    'author': <String, Object?>{'name': 'Example'},
    'compatibility': <String, Object?>{
      'minHubVersion': '1.0.0',
      'runtimeApi': '>=1.0.0 <2.0.0',
      'projectFormat': 'v6',
      'saveFormat': 1,
      'compatibilityId': 'main',
      'requiredCapabilities': <String>[],
    },
    'locales': <String, Object?>{
      'default': 'fr',
      'supported': <String>['fr'],
    },
    'content': content.toJson(),
  };
  mutateManifest?.call(manifestJson);
  final manifestBytes = encodeUncheckedManifest
      ? CanonicalJson.encodeUtf8(manifestJson)
      : const GamePackageManifestCodec().encodeCanonicalUtf8(
          const GamePackageManifestCodec().decodeJson(manifestJson),
        );
  return _rawArchive(<String, List<int>>{
    'game-manifest.json': manifestBytes,
    ...payload,
  });
}

List<int> _rawArchive(
  Map<String, List<int>> files, {
  CompressionType compression = CompressionType.none,
}) {
  final archive = Archive();
  final entries = files.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (final entry in entries) {
    final file =
        compression == CompressionType.none
              ? ArchiveFile.noCompress(
                  entry.key,
                  entry.value.length,
                  entry.value,
                )
              : ArchiveFile(entry.key, entry.value.length, entry.value)
          ..mode = 0x81a4
          ..compression = compression;
    archive.add(file);
  }
  final bytes = Uint8List.fromList(
    ZipEncoder().encodeBytes(
      archive,
      modified: DateTime.utc(1980),
      autoClose: true,
    ),
  );
  final eocd = _findSignature(bytes, 0x06054b50, fromEnd: true);
  final count = _u16(bytes, eocd + 10);
  var cursor = _u32(bytes, eocd + 16);
  for (var index = 0; index < count; index++) {
    _setU16(bytes, cursor + 4, 0x0314);
    _setU16(bytes, cursor + 36, 0);
    _setU32(bytes, cursor + 38, 0x81a40000);
    cursor +=
        46 +
        _u16(bytes, cursor + 28) +
        _u16(bytes, cursor + 30) +
        _u16(bytes, cursor + 32);
  }
  return bytes;
}

RandomAccessPackageSource _sparsePackageWithVirtualProject(int projectSize) {
  final projectBytes = _validProjectBytes();
  final manifest = _build(<String, List<int>>{
    'project/project.json': projectBytes,
  }).manifest;
  final manifestBytes = const GamePackageManifestCodec().encodeCanonicalUtf8(
    manifest,
  );
  return _SparseStoredZipSource(<_SparseZipEntry>[
    _SparseZipEntry.bytes('game-manifest.json', manifestBytes),
    _SparseZipEntry.virtual('project/project.json', projectSize),
  ]);
}

List<int> _eocdWithEntryCount(int entryCount) =>
    _storedEocd(entryCount: entryCount, centralSize: 0, centralOffset: 0);

Uint8List _storedLocalHeader({
  required List<int> nameBytes,
  required int crc32,
  required int size,
}) {
  final bytes = Uint8List(30 + nameBytes.length);
  final data = ByteData.sublistView(bytes);
  data
    ..setUint32(0, 0x04034b50, Endian.little)
    ..setUint16(4, 20, Endian.little)
    ..setUint16(6, 0x0800, Endian.little)
    ..setUint16(8, 0, Endian.little)
    ..setUint16(10, 0, Endian.little)
    ..setUint16(12, 33, Endian.little)
    ..setUint32(14, crc32, Endian.little)
    ..setUint32(18, size, Endian.little)
    ..setUint32(22, size, Endian.little)
    ..setUint16(26, nameBytes.length, Endian.little)
    ..setUint16(28, 0, Endian.little);
  bytes.setRange(30, bytes.length, nameBytes);
  return bytes;
}

Uint8List _storedCentralHeader({
  required List<int> nameBytes,
  required int crc32,
  required int size,
  required int localOffset,
}) {
  final bytes = Uint8List(46 + nameBytes.length);
  final data = ByteData.sublistView(bytes);
  data
    ..setUint32(0, 0x02014b50, Endian.little)
    ..setUint16(4, 0x0314, Endian.little)
    ..setUint16(6, 20, Endian.little)
    ..setUint16(8, 0x0800, Endian.little)
    ..setUint16(10, 0, Endian.little)
    ..setUint16(12, 0, Endian.little)
    ..setUint16(14, 33, Endian.little)
    ..setUint32(16, crc32, Endian.little)
    ..setUint32(20, size, Endian.little)
    ..setUint32(24, size, Endian.little)
    ..setUint16(28, nameBytes.length, Endian.little)
    ..setUint16(30, 0, Endian.little)
    ..setUint16(32, 0, Endian.little)
    ..setUint16(34, 0, Endian.little)
    ..setUint16(36, 0, Endian.little)
    ..setUint32(38, 0x81a40000, Endian.little)
    ..setUint32(42, localOffset, Endian.little);
  bytes.setRange(46, bytes.length, nameBytes);
  return bytes;
}

Uint8List _storedEocd({
  required int entryCount,
  required int centralSize,
  required int centralOffset,
}) {
  final bytes = Uint8List(22);
  ByteData.sublistView(bytes)
    ..setUint32(0, 0x06054b50, Endian.little)
    ..setUint16(4, 0, Endian.little)
    ..setUint16(6, 0, Endian.little)
    ..setUint16(8, entryCount, Endian.little)
    ..setUint16(10, entryCount, Endian.little)
    ..setUint32(12, centralSize, Endian.little)
    ..setUint32(16, centralOffset, Endian.little)
    ..setUint16(20, 0, Endian.little);
  return bytes;
}

List<int> _duplicateFirstCentralEntry(List<int> source) {
  final bytes = Uint8List.fromList(source);
  final eocd = _findSignature(bytes, 0x06054b50, fromEnd: true);
  final centralOffset = _u32(bytes, eocd + 16);
  final centralSize = _u32(bytes, eocd + 12);
  final nameLength = _u16(bytes, centralOffset + 28);
  final extraLength = _u16(bytes, centralOffset + 30);
  final commentLength = _u16(bytes, centralOffset + 32);
  final recordLength = 46 + nameLength + extraLength + commentLength;
  final record = bytes.sublist(centralOffset, centralOffset + recordLength);
  final output = BytesBuilder(copy: false)
    ..add(bytes.sublist(0, centralOffset + centralSize))
    ..add(record)
    ..add(bytes.sublist(eocd));
  final result = output.takeBytes();
  final newEocd = eocd + recordLength;
  final count = _u16(result, newEocd + 10);
  _setU16(result, newEocd + 8, count + 1);
  _setU16(result, newEocd + 10, count + 1);
  _setU32(result, newEocd + 12, centralSize + recordLength);
  return result;
}

List<int> _truncateLastStoredEntry(List<int> source) {
  final original = Uint8List.fromList(source);
  final oldEocd = _findSignature(original, 0x06054b50, fromEnd: true);
  final entryCount = _u16(original, oldEocd + 10);
  final oldCentralOffset = _u32(original, oldEocd + 16);
  var oldCentralCursor = oldCentralOffset;
  for (var index = 1; index < entryCount; index++) {
    oldCentralCursor +=
        46 +
        _u16(original, oldCentralCursor + 28) +
        _u16(original, oldCentralCursor + 30) +
        _u16(original, oldCentralCursor + 32);
  }
  final localOffset = _u32(original, oldCentralCursor + 42);
  final oldSize = _u32(original, localOffset + 18);
  final dataOffset =
      localOffset +
      30 +
      _u16(original, localOffset + 26) +
      _u16(original, localOffset + 28);
  final mutable = original.toList()..removeAt(dataOffset + oldSize - 1);
  final bytes = Uint8List.fromList(mutable);
  final newSize = oldSize - 1;
  final newCentralCursor = oldCentralCursor - 1;
  final newEocd = oldEocd - 1;
  final newCrc32 = getCrc32(
    Uint8List.sublistView(bytes, dataOffset, dataOffset + newSize),
  );
  _setU32(bytes, localOffset + 14, newCrc32);
  _setU32(bytes, localOffset + 18, newSize);
  _setU32(bytes, localOffset + 22, newSize);
  _setU32(bytes, newCentralCursor + 16, newCrc32);
  _setU32(bytes, newCentralCursor + 20, newSize);
  _setU32(bytes, newCentralCursor + 24, newSize);
  _setU32(bytes, newEocd + 16, oldCentralOffset - 1);
  return bytes;
}

List<int> _setFirstCentralMode(List<int> source, int mode) {
  final bytes = Uint8List.fromList(source);
  final eocd = _findSignature(bytes, 0x06054b50, fromEnd: true);
  final centralOffset = _u32(bytes, eocd + 16);
  _setU32(bytes, centralOffset + 38, mode << 16);
  return bytes;
}

List<int> _setFirstCentralExtraLength(List<int> source, int length) {
  final bytes = Uint8List.fromList(source);
  final eocd = _findSignature(bytes, 0x06054b50, fromEnd: true);
  final centralOffset = _u32(bytes, eocd + 16);
  _setU16(bytes, centralOffset + 30, length);
  return bytes;
}

List<int> _setFirstEntryFlags(List<int> source, int flags) {
  final bytes = Uint8List.fromList(source);
  final eocd = _findSignature(bytes, 0x06054b50, fromEnd: true);
  final centralOffset = _u32(bytes, eocd + 16);
  final localOffset = _u32(bytes, centralOffset + 42);
  _setU16(bytes, centralOffset + 8, flags);
  _setU16(bytes, localOffset + 6, flags);
  return bytes;
}

List<int> _aliasSecondLocalOffset(List<int> source) {
  final bytes = Uint8List.fromList(source);
  final eocd = _findSignature(bytes, 0x06054b50, fromEnd: true);
  var cursor = _u32(bytes, eocd + 16);
  cursor +=
      46 +
      _u16(bytes, cursor + 28) +
      _u16(bytes, cursor + 30) +
      _u16(bytes, cursor + 32);
  _setU32(bytes, cursor + 42, 0);
  return bytes;
}

List<int> _corruptLastCentralAndLocalName(List<int> source) {
  final bytes = Uint8List.fromList(source);
  final eocd = _findSignature(bytes, 0x06054b50, fromEnd: true);
  final count = _u16(bytes, eocd + 10);
  var cursor = _u32(bytes, eocd + 16);
  for (var index = 0; index < count - 1; index++) {
    cursor +=
        46 +
        _u16(bytes, cursor + 28) +
        _u16(bytes, cursor + 30) +
        _u16(bytes, cursor + 32);
  }
  final localOffset = _u32(bytes, cursor + 42);
  bytes[cursor + 46] = 0xff;
  bytes[localOffset + 30] = 0xff;
  return bytes;
}

void _recomputeTree(Map<String, Object?> content) {
  final entries = (content['files']! as List)
      .map(
        (raw) => GamePackageFileEntry(
          path: (raw as Map<String, Object?>)['path']! as String,
          size: raw['size']! as int,
          sha256: raw['sha256']! as String,
          mediaType: raw['mediaType'] as String?,
        ),
      )
      .toList();
  content['treeSha256'] = ContentTreeHasher.sha256Hex(entries);
}

int _localDataOffset(List<int> bytes, int localEntryIndex) {
  var offset = 0;
  for (var index = 0; index <= localEntryIndex; index++) {
    expect(_u32(bytes, offset), 0x04034b50);
    final compressedSize = _u32(bytes, offset + 18);
    final nameLength = _u16(bytes, offset + 26);
    final extraLength = _u16(bytes, offset + 28);
    final dataOffset = offset + 30 + nameLength + extraLength;
    if (index == localEntryIndex) return dataOffset;
    offset = dataOffset + compressedSize;
  }
  throw StateError('Entry not found.');
}

int _findSignature(List<int> bytes, int signature, {bool fromEnd = false}) {
  if (fromEnd) {
    for (var offset = bytes.length - 4; offset >= 0; offset--) {
      if (_u32(bytes, offset) == signature) return offset;
    }
  } else {
    for (var offset = 0; offset <= bytes.length - 4; offset++) {
      if (_u32(bytes, offset) == signature) return offset;
    }
  }
  throw StateError('ZIP signature not found.');
}

int _u16(List<int> bytes, int offset) => ByteData.sublistView(
  Uint8List.fromList(bytes),
  offset,
  offset + 2,
).getUint16(0, Endian.little);

int _u32(List<int> bytes, int offset) => ByteData.sublistView(
  Uint8List.fromList(bytes),
  offset,
  offset + 4,
).getUint32(0, Endian.little);

void _setU16(Uint8List bytes, int offset, int value) =>
    ByteData.sublistView(bytes).setUint16(offset, value, Endian.little);

void _setU32(Uint8List bytes, int offset, int value) =>
    ByteData.sublistView(bytes).setUint32(offset, value, Endian.little);

void _expectCode(void Function() operation, String code) {
  expect(
    operation,
    throwsA(
      isA<GamePackageFormatException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    ),
  );
}

void _expectCodeBoth(
  GamePackageInspector inspector,
  List<int> bytes,
  String code, {
  required String reason,
}) {
  for (final operation in <void Function()>[
    () => inspector.inspect(bytes),
    () => inspector.inspectSourceSync(_MemoryPackageSource(bytes)),
  ]) {
    expect(
      operation,
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          code,
        ),
      ),
      reason: reason,
    );
  }
}
