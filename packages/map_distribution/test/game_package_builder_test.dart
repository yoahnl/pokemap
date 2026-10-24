import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';

void main() {
  test('publishes partitioned project and preserves its exact reexport', () {
    final first = GamePackageBuilder().build(
        manifest: _draftManifest(),
        payloadFiles: {'project/project.json': _validProjectBytes()});
    expect(first.manifest.compatibility.requiredCapabilities,
        contains('catalog.partitioned@2'));
    final archive = ZipDecoder().decodeBytes(first.packageBytes);
    final payload = <String, List<int>>{
      for (final file in archive.files)
        if (file.name != 'game-manifest.json')
          file.name: file.content as List<int>
    };
    final descriptor = jsonDecode(utf8.decode(payload['project/project.json']!))
        as Map<String, dynamic>;
    expect(descriptor['kind'], 'project');
    final project = PortableCatalogPublication.decodeProjectSync(descriptor,
        readObject: (ref) =>
            payload['project/${PortableCatalogPublication.objectPath(ref)}']!);
    expect(
        project.toJson(),
        ProjectManifest.fromJson(jsonDecode(utf8.decode(_validProjectBytes()))
                as Map<String, dynamic>)
            .toJson());
    final second = GamePackageBuilder()
        .build(manifest: first.manifest, payloadFiles: payload);
    expect(second.packageBytes, first.packageBytes);
  });

  test('rejects missing orphaned changed and unsupported publication objects',
      () {
    final built = GamePackageBuilder().build(
        manifest: _draftManifest(),
        payloadFiles: {'project/project.json': _validProjectBytes()});
    final archive = ZipDecoder().decodeBytes(built.packageBytes);
    final payload = <String, List<int>>{
      for (final file in archive.files)
        if (file.name != 'game-manifest.json')
          file.name: file.content as List<int>
    };
    final object = payload.keys
        .firstWhere((path) => path.startsWith('project/catalog/objects/'));
    final invalid = <Map<String, List<int>>>[
      {...payload}..remove(object),
      {...payload, object: utf8.encode('{}')},
      {
        ...payload,
        'project/catalog/objects/${sha256.convert(utf8.encode('{}'))}.json':
            utf8.encode('{}')
      },
      for (final change in [
        {'version': 1},
        {'format': 'other'},
        {'kind': 'resourcePack'}
      ])
        {
          ...payload,
          'project/project.json': utf8.encode(jsonEncode({
            ...jsonDecode(utf8.decode(payload['project/project.json']!)) as Map,
            ...change,
          }))
        },
    ];
    for (final candidate in invalid) {
      expect(
          () => GamePackageBuilder()
              .build(manifest: built.manifest, payloadFiles: candidate),
          throwsA(isA<GamePackageFormatException>()
              .having((e) => e.code, 'code', 'invalidProject')));
    }
  });

  test('requires partition capability even without host compatibility', () {
    final built = GamePackageBuilder().build(
        manifest: _draftManifest(),
        payloadFiles: {'project/project.json': _validProjectBytes()});
    final archive = ZipDecoder().decodeBytes(built.packageBytes);
    final json = built.manifest.toJson();
    (json['compatibility'] as Map)['requiredCapabilities'] = [];
    final bytes = DeterministicZipEncoder.encode([
      for (final file in archive.files)
        MapEntry(
            file.name,
            file.name == 'game-manifest.json'
                ? CanonicalJson.encodeUtf8(json)
                : file.content as List<int>),
    ]);
    expect(
        () => GamePackageInspector().inspect(bytes),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'missingCatalogCapability')));
  });

  test(
      'global project quotas count every object and never rewrite a signed capability',
      () {
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(_validProjectBytes())) as Map<String, dynamic>);
    final budget =
        CatalogBudgetCalculator().measureProjectJson(project.toJson());
    final physicalBytes = budget.totals['catalogBytes']!;
    final values = budget.totals['jsonNodes']!;
    final exact = GamePackageSecurityPolicy(
        maxCatalogBytes: physicalBytes, maxCatalogJsonValues: values);
    final built = GamePackageBuilder(securityPolicy: exact).build(
        manifest: _draftManifest(),
        payloadFiles: {'project/project.json': _validProjectBytes()});
    expect(
        GamePackageInspector(policy: exact)
            .inspect(built.packageBytes)
            .manifest
            .content
            .totalBytes,
        physicalBytes);
    for (final policy in [
      GamePackageSecurityPolicy(maxCatalogBytes: physicalBytes - 1),
      GamePackageSecurityPolicy(maxCatalogJsonValues: values - 1)
    ]) {
      expect(
          () => GamePackageBuilder(securityPolicy: policy).build(
              manifest: _draftManifest(),
              payloadFiles: {'project/project.json': _validProjectBytes()}),
          throwsA(isA<GamePackageFormatException>()));
      expect(
          () =>
              GamePackageInspector(policy: policy).inspect(built.packageBytes),
          throwsA(isA<GamePackageFormatException>()));
    }
    final signed = _draftManifest().copyWith(
        signature: const GamePackageSignature(
            algorithm: 'ed25519',
            keyId: 'publisher:key',
            value:
                'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=='));
    expect(
        () => GamePackageBuilder().build(
            manifest: signed,
            payloadFiles: {'project/project.json': _validProjectBytes()}),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'staleSignature')));
  });

  test('preserves signed capability order during an unchanged v2 reexport', () {
    final built = GamePackageBuilder().build(
        manifest: _draftManifest(),
        payloadFiles: {'project/project.json': _validProjectBytes()});
    final archive = ZipDecoder().decodeBytes(built.packageBytes);
    final payload = {
      for (final file in archive.files)
        if (file.name != 'game-manifest.json')
          file.name: file.content as List<int>
    };
    final old = built.manifest.compatibility;
    final compatibility = GamePackageCompatibility(
        minHubVersion: old.minHubVersion,
        runtimeApiExpression: old.runtimeApiExpression,
        projectFormat: old.projectFormat,
        saveFormat: old.saveFormat,
        compatibilityId: old.compatibilityId,
        requiredCapabilities: ['map@1', 'catalog.partitioned@2']);
    final signed = built.manifest.copyWith(
        compatibility: compatibility,
        signature: const GamePackageSignature(
            algorithm: 'ed25519',
            keyId: 'publisher:key',
            value:
                'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=='));
    final reexport =
        GamePackageBuilder().build(manifest: signed, payloadFiles: payload);
    expect(reexport.manifest.compatibility.toJson(),
        signed.compatibility.toJson());
    expect(reexport.manifest.signature!.toJson(), signed.signature!.toJson());
  });

  test('refuses duplicate native project keys before publication normalization',
      () {
    final source = utf8.decode(_validProjectBytes()).replaceFirst(
        '"name":"Builder Test"', '"name":"Builder Test","name":"Other"');
    expect(
        () => GamePackageBuilder().build(
            manifest: _draftManifest(),
            payloadFiles: {'project/project.json': utf8.encode(source)}),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'invalidProject')));
  });

  group('GamePackageBuilder', () {
    const builder = GamePackageBuilder();

    test('exposes compact immutable package bytes', () {
      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: <String, List<int>>{
          'project/project.json': _validProjectBytes(),
        },
      );

      expect(built.packageBytes, isA<Uint8List>());
      expect(() => built.packageBytes[0] = 0, throwsUnsupportedError);
      expect(
        () => (built.packageBytes as Uint8List).buffer.asUint8List()[0] = 0,
        throwsUnsupportedError,
      );
      expect(
          sha256.convert(built.packageBytes).toString(), built.packageSha256);
    });

    test('defensively copies bytes passed to the public result constructor',
        () {
      final source = Uint8List.fromList(<int>[1, 2, 3]);
      final result = GamePackageBuildResult(
        manifest: _draftManifest(),
        packageBytes: source,
      );

      source[0] = 9;
      expect(result.packageBytes, <int>[1, 2, 3]);
      expect(result.packageBytes, isA<Uint8List>());
      expect(result.packageSha256, sha256.convert(<int>[1, 2, 3]).toString());
      expect(() => result.packageBytes[0] = 9, throwsUnsupportedError);
    });

    test('rejects non-byte values in the public result constructor', () {
      for (final invalidByte in <int>[-1, 256]) {
        expect(
          () => GamePackageBuildResult(
            manifest: _draftManifest(),
            packageBytes: <int>[1, invalidByte],
          ),
          throwsArgumentError,
        );
      }
    });

    test('builds a deterministic STORE-only data package', () {
      final firstPayload = <String, List<int>>{
        ..._frozenPublicationPayload(),
        'presentation/icon.png': _onePixelPngHeader(),
      };
      final secondPayload = <String, List<int>>{
        for (final entry in firstPayload.entries.toList().reversed)
          entry.key: entry.value,
      };

      final first = builder.build(
        manifest: _draftManifest(),
        payloadFiles: firstPayload,
      );
      final second = builder.build(
        manifest: _draftManifest(),
        payloadFiles: secondPayload,
      );

      expect(first.packageBytes, second.packageBytes);
      expect(
        sha256.convert(first.packageBytes).toString(),
        'de5f6febef0a8189f64f538f8c3c69c9c4c669367a9051dd49f1bdbec8a0491e',
      );
      expect(
        first.packageSha256,
        'de5f6febef0a8189f64f538f8c3c69c9c4c669367a9051dd49f1bdbec8a0491e',
      );
      expect(first.archiveBytes, first.packageBytes.length);
      expect(first.manifest.content.fileCount, firstPayload.length);
      expect(
        first.manifest.content.treeSha256,
        second.manifest.content.treeSha256,
      );

      final archive = ZipDecoder().decodeBytes(first.packageBytes);
      for (final entry in firstPayload.entries) {
        expect(archive.findFile(entry.key)?.content, entry.value);
      }
      expect(
        archive.files.map((file) => file.name),
        <String>[
          'game-manifest.json',
          ...(firstPayload.keys.toList()..sort()),
        ],
      );
      expect(
        archive.files.every(
          (file) => file.compression == CompressionType.none,
        ),
        isTrue,
      );
      final manifestFile = archive.findFile('game-manifest.json')!;
      final decoded = const GamePackageManifestCodec().decodeUtf8(
        manifestFile.content as List<int>,
      );
      expect(decoded.toJson(), first.manifest.toJson());
    });

    test(
        'supports more than twenty thousand files within the classic ZIP quota',
        () {
      final payload = <String, List<int>>{
        'project/project.json': _validProjectBytes(),
        for (var index = 0; index < 20001; index++)
          'project/data/catalog/'
              '${index.toString().padLeft(5, '0')}.json': utf8.encode('{}'),
      };

      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: payload,
      );

      expect(
          built.manifest.content.fileCount,
          20002 +
              PortableCatalogPublication.encodeProject(ProjectManifest.fromJson(
                      jsonDecode(utf8.decode(_validProjectBytes()))
                          as Map<String, dynamic>))
                  .storage
                  .objects
                  .length);
      expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .content
            .fileCount,
        built.manifest.content.fileCount,
      );
    });

    test('exports the versioned Pokemon ruleset in the project payload', () {
      final projectBytes = utf8.encode(
        jsonEncode(
          const ProjectManifest(
            name: 'Ruleset package',
            maps: <ProjectMapEntry>[],
            tilesets: <ProjectTilesetEntry>[],
          ).toJson(),
        ),
      );

      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: <String, List<int>>{
          'project/project.json': projectBytes,
        },
      );
      final archive = ZipDecoder().decodeBytes(built.packageBytes);
      final packagedProject = jsonDecode(
        utf8.decode(
          archive.findFile('project/project.json')!.content as List<int>,
        ),
      ) as Map<String, dynamic>;

      expect(
        PortableCatalogPublication.decodeProjectSync(packagedProject,
            readObject: (ref) => archive
                .findFile(
                    'project/${PortableCatalogPublication.objectPath(ref)}')!
                .content as List<int>).pokemon.ruleset.toJson(),
        PokemonRulesetProfile.pokeMapBetaV1.toJson(),
      );
    });

    test('accepts an MP4 in the canonical PokeMap asset store', () {
      const digest =
          '0079d95b54750e42a7b369b8610cd7d87ad4e09edc1c239c8079dc3235a8e5b2';
      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: <String, List<int>>{
          'project/project.json': _validProjectBytes(),
          'project/assets/.pokemap-store/$digest.blob': <int>[
            0,
            0,
            0,
            24,
            ...utf8.encode('ftypisom'),
            0,
            0,
            0,
            0,
            ...utf8.encode('isomavc1mp4a'),
          ],
        },
      );

      expect(
        built.manifest.content.files.map((entry) => entry.path),
        contains('project/assets/.pokemap-store/$digest.blob'),
      );
    });

    test('accepts a text license in the canonical PokeMap asset store', () {
      const digest =
          'a8f8775886afcb9aa653505c31f339a5c8950d1c9124819310f873683702e37f';
      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: <String, List<int>>{
          'project/project.json': _validProjectBytes(),
          'project/assets/.pokemap-store/$digest.blob': utf8.encode(
            'SIL Open Font License 1.1\n',
          ),
        },
      );

      expect(
        built.manifest.content.files.map((entry) => entry.path),
        contains('project/assets/.pokemap-store/$digest.blob'),
      );
    });

    test('accepts only the canonical Presentation publication receipt JSON',
        () {
      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: <String, List<int>>{
          'project/project.json': _validProjectBytes(),
          'presentation/cinematics/publication.json': utf8.encode(
            jsonEncode(<String, Object?>{
              'canPublish': true,
              'totalPayloadBytes': 0,
              'media': <Object?>[
                <String, Object?>{
                  'provenance': <String, Object?>{
                    'sourceUrl': 'https://assets.example.test/opening',
                  },
                  'license': <String, Object?>{
                    'url': 'https://licenses.example.test/opening',
                  },
                },
              ],
            }),
          ),
        },
      );

      expect(
        built.manifest.content.files.map((entry) => entry.path),
        contains('presentation/cinematics/publication.json'),
      );
      expect(
        () => builder.build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
            'presentation/cinematics/authoring.json': utf8.encode('{}'),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'executableContent'),
        ),
      );
      expect(
        () => builder.build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
            'presentation/cinematics/publication.json': utf8.encode(
              jsonEncode(<String, Object?>{
                'license': <String, Object?>{'url': 'file:///tmp/license'},
              }),
            ),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'referenceEscapesRoot'),
        ),
      );
    });

    test('does not allow a stale signature to cover changed content', () {
      final unsigned = builder.build(
        manifest: _draftManifest(),
        payloadFiles: <String, List<int>>{
          'project/project.json': _validProjectBytes(),
        },
      );
      final signed = unsigned.manifest.copyWith(
        signature: const GamePackageSignature(
          algorithm: 'ed25519',
          keyId: 'publisher:key',
          value:
              'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
        ),
      );

      expect(
        () => builder.build(
          manifest: signed,
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(name: 'Changed'),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'staleSignature'),
        ),
      );
      expect(
        () => const GamePackageBuilder(
          securityPolicy: GamePackageSecurityPolicy(maxFileBytes: 1),
        ).build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'entryTooLarge'),
        ),
      );
    });

    test('snapshots mutable inputs and applies data-only policy at build time',
        () {
      final projectBytes = _validProjectBytes();
      final iconBytes = _onePixelPngHeader();
      final payload = <String, List<int>>{
        'project/project.json': projectBytes,
        'presentation/icon.png': iconBytes,
      };

      final built = builder.build(
        manifest: _draftManifest(),
        payloadFiles: payload,
        mediaTypeForPath: (path) {
          if (path == 'presentation/icon.png') {
            projectBytes[0] = 0;
          }
          return path.endsWith('.json') ? 'application/json' : 'image/png';
        },
      );

      expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .gameId,
        'games.example.builder',
      );
      expect(
        () => builder.build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
            'project/assets/code.dart': utf8.encode('void main() {}'),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'executableContent'),
        ),
      );
    });

    test('rejects authoring artifacts and validates projection closure', () {
      expect(
        () => builder.build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
            'project/data/catalog.json': utf8.encode('{"items":[]}'),
            'project/data/pokemon/media/creature.png': _onePixelPngHeader(),
          },
        ),
        returnsNormally,
      );
      for (final excludedPath in <String>[
        'project/.dart_tool/cache.json',
        'project/fixtures/debug.json',
        'project/runtime_host_launch_save.json',
        'project/seeds.json',
        'project/editor-state.json',
        'project/editor_state.json',
        'project/save.json',
        'project/diagnostic.json',
      ]) {
        expect(
          () => builder.build(
            manifest: _draftManifest(),
            payloadFiles: <String, List<int>>{
              'project/project.json': _validProjectBytes(),
              excludedPath: utf8.encode('{}'),
            },
          ),
          throwsA(
            isA<GamePackageFormatException>()
                .having((error) => error.code, 'code', 'executableContent'),
          ),
          reason: excludedPath,
        );
      }

      final projectWithMissingMap = utf8.encode(
        jsonEncode(<String, Object?>{
          'name': 'Missing Map',
          'version': 'v8',
          'maps': <Object?>[
            <String, Object?>{
              'id': 'map.start',
              'name': 'Start',
              'relativePath': 'maps/start.json',
            },
          ],
          'tilesets': <Object?>[],
          'pokemon': const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          ).toJson(),
        }),
      );
      expect(
        () => builder.build(
          manifest: _draftManifest(),
          payloadFiles: <String, List<int>>{
            'project/project.json': projectWithMissingMap,
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'missingFile'),
        ),
      );

      expect(
        () => builder.build(
          manifest: _draftManifest(projectFormat: 'v5'),
          payloadFiles: <String, List<int>>{
            'project/project.json': _validProjectBytes(),
          },
        ),
        throwsA(
          isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'projectFormatMismatch'),
        ),
      );
    });
  });
}

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

Map<String, List<int>> _frozenPublicationPayload() {
  final encoded = File(
    'test/fixtures/compatibility/avelune_studio_0_3_31_331/'
    'overworld.avelunegame.base64',
  ).readAsStringSync().replaceAll(RegExp(r'\s'), '');
  final archive = ZipDecoder().decodeBytes(base64Decode(encoded));
  return {
    for (final file in archive.files)
      if (file.name != 'game-manifest.json') file.name: file.content,
  };
}

List<int> _validProjectBytes({
  String name = 'Builder Test',
  String version = 'v8',
}) =>
    utf8.encode(
      jsonEncode(<String, Object?>{
        'name': name,
        'version': version,
        'maps': <Object?>[],
        'tilesets': <Object?>[],
        'pokemon': const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ).toJson(),
      }),
    );

GamePackageManifest _draftManifest({String projectFormat = 'v8'}) {
  final valid = const GamePackageManifestCodec().decodeJson(
    <String, Object?>{
      'packageFormat': 1,
      'gameId': 'games.example.builder',
      'gameVersion': '1.0.0',
      'title': 'Builder',
      'author': <String, Object?>{'name': 'Example'},
      'compatibility': <String, Object?>{
        'minHubVersion': '1.0.0',
        'runtimeApi': '>=1.0.0 <2.0.0',
        'projectFormat': projectFormat,
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
          },
        ],
      },
    },
  );
  return valid.copyWith(clearSignature: true);
}
