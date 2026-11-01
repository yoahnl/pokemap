import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
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
      expect(result.payloadPaths,
          built.manifest.content.files.map((file) => file.path).toList());
      expect(result.receipt.receiptVersion, 1);
      expect(result.receipt.treeSha256, result.manifest.content.treeSha256);
      expect(result.receipt.packageSha256, hasLength(64));
      expect(
        result.receipt.pokemonRuleset,
        PokemonRulesetProfile.pokeMapBetaV1Reference,
      );
      expect(result.receipt.toJson()['pokemonRuleset'], <String, Object?>{
        'profileId': 'pokemap-beta-v1',
        'schemaVersion': 1,
      });
      expect(
        result.receipt.toJson()['gameVersion'],
        result.manifest.gameVersion.toString(),
      );
    });

    test('validates Pokemon v2 animated blob references during build and inspection', () async {
      final gif = base64Decode(
        'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
      );
      final png = _oversizedPng(width: 1, height: 1);
      String blobPath(List<int> bytes) {
        final digest = (NarrativeProjectFingerprintBuilder()
              ..startEntry(relativePath: 'artifact-content', byteLength: bytes.length)
              ..addBytes(bytes)
              ..endEntry())
            .close();
        return 'assets/.pokemap-store/${digest.substring('sha256:'.length)}.blob';
      }

      Map<String, List<int>> payload(String path, List<int>? bytes,
              {int version = 2, String field = 'frontAnimated'}) => {
        'project/project.json': _validProjectBytes(),
        'project/data/pokemon/media/oshawott.json': utf8.encode(jsonEncode({
          'schemaVersion': version,
          'speciesId': 'oshawott',
          'defaultFormId': 'base',
          'variants': {'base': {field: path}},
        })),
        if (bytes != null) 'project/$path': bytes,
      };

      final missingPath = blobPath(gif);
      final badDigestPath = 'assets/.pokemap-store/${'a' * 64}.blob';
      final cases = [
        (path: missingPath, bytes: null, code: 'pokemonAnimatedMediaMissing'),
        (path: badDigestPath, bytes: gif, code: 'pokemonAnimatedBlobDigestMismatch'),
        (path: blobPath(png), bytes: png, code: 'pokemonAnimatedMediaInvalid'),
      ];
      for (final item in cases) {
        final files = payload(item.path, item.bytes);
        _expectCode(() => _build(files), item.code);
        await _expectCodeBoth(inspector, _rawPackage(files), item.code,
            reason: item.code);
      }
      for (final mediaDirectory in ['.', '']) {
        for (final item in cases) {
          final files = payload(item.path, item.bytes);
          final project = jsonDecode(utf8.decode(_validProjectBytes())) as Map;
          (project['pokemon'] as Map)['mediaDir'] = mediaDirectory;
          files['project/project.json'] = utf8.encode(jsonEncode(project));
          files['project/oshawott.json'] =
              files.remove('project/data/pokemon/media/oshawott.json')!;
          _expectCode(() => _build(files), item.code);
          await _expectCodeBoth(inspector, _rawPackage(files), item.code,
              reason: 'mediaDir "$mediaDirectory": ${item.code}');
        }
        final disabled = jsonDecode(utf8.decode(_validProjectBytes())) as Map;
        (disabled['pokemon'] as Map)
          ..['enabled'] = false
          ..['mediaDir'] = mediaDirectory;
        final independent = {
          'project/project.json': utf8.encode(jsonEncode(disabled)),
          'project/data/custom/unrelated.json': utf8.encode(jsonEncode({
            'schemaVersion': 2,
            'speciesId': 'unrelated',
            'variants': {'base': {'frontAnimated': '../independent.gif'}},
          })),
        };
        expect(() => _build(independent), returnsNormally);
        expect(() => inspector.inspect(_rawPackage(independent)), returnsNormally);
      }
      for (final field in [
        'frontAnimated',
        'backAnimated',
        'frontShinyAnimated',
        'backShinyAnimated',
        'frontFemaleAnimated',
        'backFemaleAnimated',
        'frontShinyFemaleAnimated',
        'backShinyFemaleAnimated',
      ]) {
        final files = payload(missingPath, null, field: field);
        _expectCode(() => _build(files), 'pokemonAnimatedMediaMissing');
        _expectCode(() => inspector.inspect(_rawPackage(files)),
            'pokemonAnimatedMediaMissing');
        final escaping = payload('../outside.gif', null, field: field);
        _expectCode(() => _build(escaping), 'referenceEscapesRoot');
        await _expectCodeBoth(inspector, _rawPackage(escaping),
            'referenceEscapesRoot', reason: 'escaped media field $field');
      }

      final valid = payload(blobPath(gif), gif);
      expect(() => _build(valid), returnsNormally);
      expect(() => inspector.inspect(_rawPackage(valid)), returnsNormally);
      final legacy = payload(missingPath, null, version: 1);
      expect(() => _build(legacy), returnsNormally);
      expect(() => inspector.inspect(_rawPackage(legacy)), returnsNormally);
      final unrelated = {
        'project/project.json': _validProjectBytes(),
        'project/data/pokemon/media/options.json': utf8.encode(jsonEncode({
          'schemaVersion': 2,
          'variants': ['unrelated'],
          'configuration': {'value': true},
        })),
      };
      expect(() => _build(unrelated), returnsNormally);
      expect(() => inspector.inspect(_rawPackage(unrelated)), returnsNormally);

      final customProject = jsonDecode(utf8.decode(_validProjectBytes())) as Map;
      (customProject['pokemon'] as Map)['mediaDir'] = 'metadata/pokemon-media/';
      final custom = {
        'project/project.json': utf8.encode(jsonEncode(customProject)),
        'project/metadata/pokemon-media/oshawott.json': utf8.encode(jsonEncode({
          'schemaVersion': 2,
          'speciesId': 'oshawott',
          'defaultFormId': 'base',
          'variants': {'base': {'frontAnimated': missingPath}},
        })),
      };
      _expectCode(() => _build(custom), 'pokemonAnimatedMediaMissing');
      _expectCode(() => inspector.inspect(_rawPackage(custom)),
          'pokemonAnimatedMediaMissing');

      const decomposed = 'sprites/e\u0301.gif';
      const composed = 'sprites/é.gif';
      final nonNormalized = payload(decomposed, null);
      nonNormalized['project/$composed'] = gif;
      _expectCode(() => _build(nonNormalized), 'pokemonAnimatedPathNotNormalized');
      await _expectCodeBoth(inspector, _rawPackage(nonNormalized),
          'pokemonAnimatedPathNotNormalized', reason: 'non-NFC media reference');

      final nonNormalizedDirectory = payload(blobPath(gif), gif);
      final directoryProject = jsonDecode(utf8.decode(_validProjectBytes())) as Map;
      (directoryProject['pokemon'] as Map)['mediaDir'] = 'data/pokemon/me\u0301dia';
      nonNormalizedDirectory['project/project.json'] = utf8.encode(jsonEncode(directoryProject));
      nonNormalizedDirectory['project/data/pokemon/média/oshawott.json'] =
          nonNormalizedDirectory.remove('project/data/pokemon/media/oshawott.json')!;
      _expectCode(() => _build(nonNormalizedDirectory), 'pokemonAnimatedPathNotNormalized');
      await _expectCodeBoth(inspector, _rawPackage(nonNormalizedDirectory),
          'pokemonAnimatedPathNotNormalized', reason: 'non-NFC media directory');
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
          built.manifest.content.totalBytes,
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

    test('validates a full GIF larger than the retained media header', () {
      final gif = _gifWithCommentBlocks(4200);
      expect(gif.length, greaterThan(1024 * 1024));
      expect(const PokemonGifInspector().inspect(gif).frameCount, 1);
      final digest = sha256.convert(gif).toString();
      final paths = [
        'project/assets/pokemon/large.gif',
        'project/assets/.pokemap-store/$digest.blob',
      ];
      final built = _build({
        'project/project.json': _validProjectBytes(),
        for (final path in paths) path: gif,
      });
      final result = inspector.inspectSourceSync(
        _MemoryPackageSource(built.packageBytes),
      );
      for (final path in paths) {
        final entry = result.manifest.content.files.singleWhere(
          (item) => item.path == path,
        );
        expect(entry.sha256, digest);
        expect(entry.size, gif.length);
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
            'game-manifest.json':
                const GamePackageManifestCodec().encodeCanonicalUtf8(manifest),
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
      final manifestBytes =
          const GamePackageManifestCodec().encodeCanonicalUtf8(manifest);

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
        () => const GamePackageInspector(
          policy: GamePackageSecurityPolicy(maxArchiveBytes: 10),
        ).inspect(
          _build(<String, List<int>>{
            'project/project.json': _validProjectBytes(),
          }).packageBytes,
        ),
        'archiveTooLarge',
      );
      _expectCode(
        () => const GamePackageInspector(
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
          () => const GamePackageInspector(
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
                  'version': 'v8',
                  'maps': <Object?>[],
                  'tilesets': <Object?>[],
                  'pokemon': const ProjectPokemonConfig(
                    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
                  ).toJson(),
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

    test('enforces the selected trust channel with an injected verifier',
        () async {
      final projectBytes = _validProjectBytes();
      final unsigned = _build(<String, List<int>>{
        'project/project.json': projectBytes,
      });
      await _expectCodeBoth(
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

      await _expectCodeBoth(
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
            capabilities: const <String>{'catalog.partitioned@2'},
            supportedProjectFormats: const <String>{'v8'},
            currentProjectFormat: 'v8',
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
            capabilities: const <String>{'catalog.partitioned@2'},
            supportedProjectFormats: const <String>{'v8'},
            currentProjectFormat: 'v8',
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
      final manifestBytes =
          const GamePackageManifestCodec().encodeCanonicalUtf8(valid.manifest);
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

    test('executes hostile ZIP/content cases through both inspector backends',
        () async {
      final projectBytes = _validProjectBytes();
      final valid = _build(<String, List<int>>{
        'project/project.json': projectBytes,
      });
      final manifestBytes =
          const GamePackageManifestCodec().encodeCanonicalUtf8(valid.manifest);
      final withMap = _build(<String, List<int>>{
        'project/maps/listed.json': utf8.encode('{}'),
        'project/project.json': projectBytes,
      });
      final hostile = <({
        String id,
        List<int> bytes,
        String code,
        GamePackageInspector inspector,
      })>[
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
            path: 'project/${List<String>.filled(33, 'a').join('/')}/x.json',
          ),
          (id: 'HP-017-segment', path: 'project/${'a' * 256}.json'),
          (
            id: 'HP-017-path',
            path: 'project/${<String>[
              ...List<String>.filled(16, 'a' * 28),
              'a' * 34
            ].join('/')}/x.json',
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
                  (content['files']! as List).first as Map<String, Object?>;
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
                'pokemon': const ProjectPokemonConfig(
                        ruleset: PokemonRulesetProfile.pokeMapBetaV1)
                    .toJson(),
                'version': 'v8',
                'maps': <Object?>[],
                'tilesets': <Object?>[],
                'groups': <Object?>[
                  for (var index = 0; index < 33; index++)
                    <String, Object?>{
                      'id': 'g$index',
                      'name': 'Group $index',
                          'type': 'city',
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
        await _expectCodeBoth(
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

    test('rejects the exact normative byte and entry overflows', () async {
      await _expectCodeBoth(
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
        () => const GamePackageInspector(
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
      final manifestBytes =
          const GamePackageManifestCodec().encodeCanonicalUtf8(built.manifest);
      final exactInspector = GamePackageInspector(
        policy: GamePackageSecurityPolicy(
          maxArchiveBytes: built.packageBytes.length,
          maxManifestBytes: manifestBytes.length,
          maxPayloadEntries: built.manifest.content.fileCount,
          maxFileBytes: built.manifest.content.files
              .map((file) => file.size)
              .reduce((a, b) => a > b ? a : b),
          maxTotalPayloadBytes: built.manifest.content.totalBytes,
          maxJsonBytes: built.manifest.content.files
              .map((file) => file.size)
              .reduce((a, b) => a > b ? a : b),
          maxCatalogBytes: built.manifest.content.totalBytes,
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

    test('manifest inspection reads no payload', () {
      final audio = Uint8List(2 * 1024 * 1024)
        ..setAll(0, ascii.encode('RIFF'))
        ..setAll(8, ascii.encode('WAVE'));
      final built = _build(<String, List<int>>{
        'project/assets/theme.wav': audio,
        'project/project.json': _validProjectBytes(),
      });
      final structure = const RandomAccessZipStructureReader(
        GamePackageSecurityPolicy(),
      ).read(_MemoryPackageSource(built.packageBytes));
      const zipFooterSearchWindow = 65557;
      final footerSearchStart =
          built.packageBytes.length - zipFooterSearchWindow;
      final payloadRanges = <({int start, int end})>[
        for (final entry in structure.entries)
          if (entry.name != 'game-manifest.json' &&
              entry.dataOffset < footerSearchStart)
            (
              start: entry.dataOffset,
              end: min(entry.dataOffset + entry.size, footerSearchStart),
            ),
      ];
      expect(
        payloadRanges.fold<int>(
            0, (sum, range) => sum + range.end - range.start),
        greaterThan(1024 * 1024),
      );
      final manifestSource = _CountingPackageSource(
        built.packageBytes,
        payloadRanges,
      );
      final fullSource = _CountingPackageSource(
        built.packageBytes,
        payloadRanges,
      );

      final manifestOnly = inspector.inspectManifestSync(manifestSource);
      final full = inspector.inspectSourceSync(fullSource);

      expect(manifestSource.payloadBytesRead, 0);
      expect(fullSource.payloadBytesRead, greaterThan(0));
      expect(manifestOnly.manifest.toJson(), full.manifest.toJson());
      expect(manifestOnly.manifestSha256, full.receipt.manifestSha256);
      expect(manifestOnly.signatureStatus, full.signatureStatus);
      expect(manifestOnly.compatibility, isNull);
      expect(manifestOnly.archiveBytes, built.packageBytes.length);
      _expectCode(
        () => inspector.inspectManifestSync(
          _LengthOnlyPackageSource(inspector.policy.maxArchiveBytes + 1),
        ),
        'archiveTooLarge',
      );
      _expectCode(
        () => const GamePackageInspector(
          trustRequirement: PackageTrustRequirement.signatureRequired,
        ).inspectManifestSync(_MemoryPackageSource(built.packageBytes)),
        'signatureRequired',
      );
    });

    test(
        'known package sha is used verbatim and the result is otherwise '
        'identical', () {
      final built = _build(<String, List<int>>{
        'project/project.json': _validProjectBytes(),
      });
      final knownSha256 = 'a' * 64;
      final plainSource = _CountingPackageSource(
        built.packageBytes,
        const <({int start, int end})>[],
      );
      final knownSource = _CountingPackageSource(
        built.packageBytes,
        const <({int start, int end})>[],
      );

      final plain = inspector.inspectSourceSync(plainSource);
      final reused = inspector.inspectSourceSync(
        knownSource,
        knownPackageSha256: knownSha256,
      );

      expect(reused.receipt.packageSha256, knownSha256);
      expect(reused.manifest.toJson(), plain.manifest.toJson());
      expect(reused.payloadPaths, plain.payloadPaths);
      expect(reused.signatureStatus, plain.signatureStatus);
      expect(
        <String, Object?>{
          ...reused.receipt.toJson(),
          'packageSha256': plain.receipt.packageSha256,
        },
        plain.receipt.toJson(),
      );
      expect(
        plainSource.bytesRead - knownSource.bytesRead,
        built.packageBytes.length,
      );
      expect(
        () => inspector.inspectSourceSync(
          _MemoryPackageSource(built.packageBytes),
          knownPackageSha256: 'not-a-digest',
        ),
        throwsArgumentError,
      );
    });

    test('parallel inspection equals sequential inspection on every fixture',
        () async {
      const chunkSize = 1024 * 1024;
      final projectBytes = _validProjectBytes();
      final audio = Uint8List(2 * chunkSize + 17)
        ..setAll(0, ascii.encode('RIFF'))
        ..setAll(8, ascii.encode('WAVE'));
      final unsigned = _build(<String, List<int>>{
        'project/project.json': projectBytes,
      });
      final signed = const GamePackageBuilder().build(
        manifest: unsigned.manifest.copyWith(
          signature: const GamePackageSignature(
            algorithm: 'ed25519',
            keyId: 'publisher:key',
            value:
                'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
          ),
        ),
        payloadFiles: <String, List<int>>{'project/project.json': projectBytes},
      );
      final fixtures = <({
        String id,
        List<int> bytes,
        GamePackageInspector inspector,
      })>[
        (id: 'minimal', bytes: unsigned.packageBytes, inspector: inspector),
        (
          id: 'signed',
          bytes: signed.packageBytes,
          inspector: GamePackageInspector(
            trustRequirement: PackageTrustRequirement.signatureRequired,
            signatureVerifier: _AcceptingVerifier(),
          ),
        ),
        (
          id: 'mixed media',
          bytes: _rawPackage(<String, List<int>>{
            'legal/NOTICE.txt': <int>[
              ...List<int>.filled(chunkSize - 1, 0x61),
              ...utf8.encode('é'),
            ],
            'presentation/intro/captions.vtt': ascii.encode('WEBVTT\n\n'),
            'project/assets/theme.wav': audio,
            for (var index = 0; index < 150; index++)
              'presentation/icons/icon_$index.png':
                  _oversizedPng(width: index + 1, height: 2),
            'project/project.json': projectBytes,
          }),
          inspector: inspector,
        ),
      ];

      for (final fixture in fixtures) {
        for (final knownPackageSha256 in <String?>[null, 'b' * 64]) {
          final sequential = fixture.inspector.inspectSourceSync(
            _MemoryPackageSource(fixture.bytes),
            knownPackageSha256: knownPackageSha256,
          );
          for (final workers in <int>[0, 1, 2, 4, 7]) {
            final parallel = await fixture.inspector.inspectSourceParallel(
              _openMemorySource(fixture.bytes),
              workers: workers,
              knownPackageSha256: knownPackageSha256,
            );
            final reason = '${fixture.id} workers=$workers '
                'known=${knownPackageSha256 != null}';
            expect(
              parallel.receipt.toJson(),
              sequential.receipt.toJson(),
              reason: reason,
            );
            expect(
              parallel.manifest.toJson(),
              sequential.manifest.toJson(),
              reason: reason,
            );
            expect(parallel.payloadPaths, sequential.payloadPaths,
                reason: reason);
            expect(parallel.signatureStatus, sequential.signatureStatus,
                reason: reason);
            expect(parallel.compatibility, sequential.compatibility,
                reason: reason);
          }
        }
      }
      await expectLater(
        inspector.inspectSourceParallel(
          _openMemorySource(unsigned.packageBytes),
          knownPackageSha256: 'not-a-digest',
        ),
        throwsArgumentError,
      );
    });

    test(
        'parallel inspection reports the first failing entry in inventory '
        'order', () async {
      final slowToken = Uint8List(6 * 1024 * 1024)
        ..setAll(0, <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
        ..setAll(12, ascii.encode('IHDR'))
        ..setAll(6 * 1024 * 1024 - 64, ascii.encode('sk-ABCDEFGHIJKLMNOP'));
      ByteData.sublistView(slowToken)
        ..setUint32(16, 1)
        ..setUint32(20, 1);
      final hostile = _rawPackage(<String, List<int>>{
        'presentation/a_slow_token.png': slowToken,
        for (var index = 0; index < 200; index++)
          'presentation/icons/icon_$index.png': _oversizedPng(width: 1),
        'presentation/z_program.png': <int>[0x4d, 0x5a, 0, 0],
        'project/project.json': _validProjectBytes(),
      });

      late final GamePackageFormatException sequential;
      try {
        inspector.inspectSourceSync(_MemoryPackageSource(hostile));
        fail('The sequential inspection must reject the package.');
      } on GamePackageFormatException catch (error) {
        sequential = error;
      }
      expect(sequential.code, 'probableSecret');
      expect(sequential.path, 'presentation/a_slow_token.png');

      for (final workers in <int>[1, 4]) {
        await expectLater(
          inspector.inspectSourceParallel(
            _openMemorySource(hostile),
            workers: workers,
          ),
          throwsA(
            isA<GamePackageFormatException>()
                .having((error) => error.code, 'code', sequential.code)
                .having((error) => error.path, 'path', sequential.path)
                .having(
                    (error) => error.message, 'message', sequential.message),
          ),
          reason: 'workers=$workers',
        );
      }
    });

    test(
        'parallel inspection keeps at most one large whole-buffered entry in '
        'flight', () async {
      const largeSize = 16 * 1024 * 1024 + 1;
      final payload = <String, List<int>>{
        'project/project.json': _validProjectBytes(),
        'project/assets/pokemon/large.gif': _gifWithCommentBlocks(65537),
      };
      for (var index = 0; index < 3; index++) {
        final blob = Uint8List(largeSize)
          ..fillRange(0, largeSize, 0x61)
          ..[0] = 0x62 + index;
        payload['project/assets/.pokemap-store/'
            '${sha256.convert(blob)}.blob'] = blob;
        for (var small = 0; small < 5; small++) {
          payload['presentation/icons/icon_${index}_$small.png'] =
              _oversizedPng(width: small + 1);
        }
      }
      final bytes = _rawPackage(payload);
      final watched = <({int start, int end, String name})>[
        for (final entry in const RandomAccessZipStructureReader(
          GamePackageSecurityPolicy(),
        ).read(_MemoryPackageSource(bytes)).entries)
          if (entry.name.endsWith('.blob') || entry.name.endsWith('.gif'))
            (
              start: entry.dataOffset,
              end: entry.dataOffset + entry.size,
              name: entry.name,
            ),
      ];
      expect(watched, hasLength(4));
      final temporaryDirectory = Directory.systemTemp.createTempSync(
        'map_distribution_large_entries_',
      );
      final packageFile = File('${temporaryDirectory.path}/large.avelunegame')
        ..writeAsBytesSync(bytes, flush: true);
      final events = <String>[];
      final port = ReceivePort()..listen((event) => events.add('$event'));
      try {
        final result = await inspector.inspectSourceParallel(
          _reportingFileSource(packageFile.path, port.sendPort, watched),
          workers: 4,
          knownPackageSha256: 'c' * 64,
        );
        expect(result.payloadPaths, containsAll(watched.map((r) => r.name)));
        await _settleSourceEvents(events, expectedOpens: 5);

        var inFlight = 0;
        var maxInFlight = 0;
        for (final event in events) {
          if (event.startsWith('start:')) {
            inFlight++;
            if (inFlight > maxInFlight) maxInFlight = inFlight;
          } else if (event.startsWith('end:')) {
            inFlight--;
          }
        }
        expect(
          events.where((event) => event.startsWith('start:')).length,
          greaterThanOrEqualTo(4),
        );
        expect(maxInFlight, 1, reason: events.join(', '));
      } finally {
        port.close();
        temporaryDirectory.deleteSync(recursive: true);
      }
    });

    test('parallel inspection closes every source it opens', () async {
      final valid = _rawPackage(<String, List<int>>{
        for (var index = 0; index < 20; index++)
          'presentation/icons/icon_$index.png': _oversizedPng(width: 1),
        'project/project.json': _validProjectBytes(),
      });
      final hostile = _rawPackage(<String, List<int>>{
        for (var index = 0; index < 20; index++)
          'presentation/icons/icon_$index.png': _oversizedPng(width: 1),
        'presentation/a_program.png': <int>[0x4d, 0x5a, 0, 0],
        'project/assets/theme.wav': Uint8List(48 * 1024 * 1024)
          ..setAll(0, ascii.encode('RIFF'))
          ..setAll(8, ascii.encode('WAVE')),
        'project/project.json': _validProjectBytes(),
      });
      final temporaryDirectory = Directory.systemTemp.createTempSync(
        'map_distribution_source_lifecycle_',
      );
      try {
        for (final (id, bytes, rejected) in <(String, List<int>, bool)>[
          ('valid', valid, false),
          ('hostile', hostile, true),
        ]) {
          final packageFile = File('${temporaryDirectory.path}/$id.avelunegame')
            ..writeAsBytesSync(bytes, flush: true);
          final events = <String>[];
          final port = ReceivePort()..listen((event) => events.add('$event'));
          try {
            final inspection = inspector.inspectSourceParallel(
              _reportingFileSource(
                packageFile.path,
                port.sendPort,
                const <({int start, int end, String name})>[],
              ),
              workers: 4,
            );
            if (rejected) {
              await expectLater(
                inspection,
                throwsA(isA<GamePackageFormatException>()),
                reason: id,
              );
            } else {
              await inspection;
            }
            await _settleSourceEvents(events, expectedOpens: 6);
            expect(
              events.where((event) => event == 'open'),
              hasLength(6),
              reason: id,
            );
            expect(
              events.where((event) => event == 'close'),
              hasLength(6),
              reason: id,
            );
          } finally {
            port.close();
          }
        }
      } finally {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });
  });
}

Future<RandomAccessPackageSource> Function() _reportingFileSource(
  String path,
  SendPort events,
  List<({int start, int end, String name})> watched,
) =>
    () async {
      events.send('open');
      return _ReportingFileSource(
        File(path).openSync(),
        File(path).lengthSync(),
        events,
        watched,
      );
    };

Future<void> _settleSourceEvents(
  List<String> events, {
  required int expectedOpens,
}) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    final opens = events.where((event) => event == 'open').length;
    final closes = events.where((event) => event == 'close').length;
    if (opens >= expectedOpens && opens == closes) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

final class _ReportingFileSource implements ClosableRandomAccessPackageSource {
  _ReportingFileSource(this._handle, this.length, this._events, this._watched);

  final RandomAccessFile _handle;
  final SendPort _events;
  final List<({int start, int end, String name})> _watched;

  @override
  final int length;

  @override
  Uint8List readAtSync(int offset, int length) {
    for (final range in _watched) {
      if (offset == range.start) _events.send('start:${range.name}');
    }
    _handle.setPositionSync(offset);
    final bytes = _handle.readSync(length);
    for (final range in _watched) {
      if (offset + length == range.end) _events.send('end:${range.name}');
    }
    return bytes;
  }

  @override
  Future<void> close() async {
    _handle.closeSync();
    _events.send('close');
  }
}

Future<RandomAccessPackageSource> Function() _openMemorySource(
  List<int> bytes,
) {
  final snapshot = Uint8List.fromList(bytes);
  return () async => _MemoryPackageSource(snapshot);
}

final class _CountingPackageSource implements RandomAccessPackageSource {
  _CountingPackageSource(List<int> bytes, this.payloadRanges)
      : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;
  final List<({int start, int end})> payloadRanges;
  int bytesRead = 0;
  int payloadBytesRead = 0;

  @override
  int get length => bytes.length;

  @override
  Uint8List readAtSync(int offset, int length) {
    final end = offset + length;
    bytesRead += length;
    for (final range in payloadRanges) {
      final overlapStart = offset > range.start ? offset : range.start;
      final overlapEnd = end < range.end ? end : range.end;
      if (overlapEnd > overlapStart) {
        payloadBytesRead += overlapEnd - overlapStart;
      }
    }
    return Uint8List.sublistView(bytes, offset, end);
  }
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
  }) =>
      false;
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

  const _SparseZipEntry.virtual(this.name, this.size)
      : crc32 = 0,
        bytes = null;

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
        'version': 'v8',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
        'pokemon': const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ).toJson(),
      }),
    );

Uint8List _gifWithCommentBlocks(int count) {
  final base = base64Decode(
    'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
  );
  final tableBytes = base[10] & 0x80 == 0
      ? 0
      : 3 * (1 << ((base[10] & 7) + 1));
  final offset = 13 + tableBytes;
  final bytes = BytesBuilder(copy: false)
    ..add(base.sublist(0, offset))
    ..add([0x21, 0xfe]);
  final block = Uint8List.fromList(List.filled(255, 0x78));
  for (var i = 0; i < count; i++) {
    bytes.addByte(255);
    bytes.add(block);
  }
  bytes
    ..addByte(0)
    ..add(base.sublist(offset));
  return bytes.takeBytes();
}

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
        'projectFormat': 'v8',
        'saveFormat': 1,
        'compatibilityId': 'main',
        'requiredCapabilities': <String>['catalog.partitioned@2'],
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

Map<String, List<int>> _partitionPayload(Map<String, List<int>> payload) {
  final bytes = payload['project/project.json'];
  if (bytes == null) return payload;
  try {
    final raw = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (raw['version'] is! String) return payload;
    final publication =
        PortableCatalogPublication.encodeProject(ProjectManifest.fromJson(raw));
    return {
      ...payload,
      'project/project.json': CanonicalJson.encodeUtf8(publication.descriptor),
      for (final object in publication.storage.objects.entries)
        'project/catalog/objects/${object.key}.json': object.value,
    };
  } on Object {
    return payload;
  }
}

List<int> _rawPackage(
  Map<String, List<int>> payload, {
  void Function(Map<String, Object?> manifest)? mutateManifest,
  bool encodeUncheckedManifest = false,
}) {
  payload = _partitionPayload(payload);
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
      'projectFormat': 'v8',
      'saveFormat': 1,
      'compatibilityId': 'main',
      'requiredCapabilities': <String>['catalog.partitioned@2'],
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
    final file = compression == CompressionType.none
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
    cursor += 46 +
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
    oldCentralCursor += 46 +
        _u16(original, oldCentralCursor + 28) +
        _u16(original, oldCentralCursor + 30) +
        _u16(original, oldCentralCursor + 32);
  }
  final localOffset = _u32(original, oldCentralCursor + 42);
  final oldSize = _u32(original, localOffset + 18);
  final dataOffset = localOffset +
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
  cursor += 46 +
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
    cursor += 46 +
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

Future<void> _expectCodeBoth(
  GamePackageInspector inspector,
  List<int> bytes,
  String code, {
  required String reason,
}) async {
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
  late final GamePackageFormatException sequential;
  try {
    inspector.inspectSourceSync(_MemoryPackageSource(bytes));
  } on GamePackageFormatException catch (error) {
    sequential = error;
  }
  await expectLater(
    inspector.inspectSourceParallel(_openMemorySource(bytes), workers: 3),
    throwsA(
      isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', sequential.code)
          .having((error) => error.path, 'path', sequential.path)
          .having((error) => error.message, 'message', sequential.message),
    ),
    reason: reason,
  );
}
