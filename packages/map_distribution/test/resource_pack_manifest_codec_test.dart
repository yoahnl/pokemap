import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'package:map_distribution/src/canonical_json.dart';
import 'package:map_distribution/src/game_package_format_exception.dart';
import 'package:map_distribution/src/resource_pack_manifest_codec.dart';
import 'package:map_distribution/src/resource_pack_security_policy.dart';

Map<String, Object?> _manifest() => {
      'format': 'avelune.asset-pack',
      'formatVersion': 1,
      'pack': {
        'id': 'original.workshop',
        'version': '1.0.0',
        'name': 'Atelier original',
        'description': 'Ressources originales de test',
        'universeId': 'original.workshop',
        'authors': ['Studio'],
        'provenance': 'Création originale',
      },
      'compatibility': {
        'resourceLibraryCatalogVersion': 2,
        'smartTileCatalogVersion': 7,
        'borderCatalogVersion': 10,
        'requiredCapabilities': ['images.png'],
        'tileWidth': 32,
        'tileHeight': 32,
      },
      'content': {
        'catalog': {
          'path': 'catalog.json',
          'byteLength': 2,
          'mediaType': 'application/json',
          'rawSha256': sha256.convert(utf8.encode('{}')).toString(),
        },
        'files': <Object?>[],
        'treeSha256': '0' * 64,
      },
    };

Matcher _failure(String code) => throwsA(
      isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', code),
    );

void main() {
  const codec = ResourcePackManifestCodec();

  test('encodes deterministically and accepts harmless JSON whitespace', () {
    final source = _manifest();
    final manifest = codec.decodeUtf8(utf8.encode(jsonEncode(source)));
    final encoded = codec.encodeUtf8(manifest);
    expect(codec.decodeUtf8(encoded), manifest);
    expect(codec.encodeUtf8(manifest), encoded);
    expect(utf8.decode(encoded), CanonicalJson.encode(source));
    expect(
      codec.decodeUtf8(
          utf8.encode(const JsonEncoder.withIndent('  ').convert(source))),
      manifest,
    );
  });

  test('rejects invalid UTF8 and ambiguous duplicate keys before decoding', () {
    expect(
        () => codec.decodeUtf8([0xff]), _failure('resource_pack.invalid_utf8'));
    final valid = jsonEncode(_manifest());
    final duplicate = valid.replaceFirst(
      '"formatVersion":1',
      '"formatVersion":1,"formatVersion":1',
    );
    expect(
      () => codec.decodeUtf8(utf8.encode(duplicate)),
      _failure('resource_pack.json_duplicate_key'),
    );
    expect(
      () => codec.decodeUtf8(utf8.encode('{"bad":')),
      _failure('resource_pack.invalid_json'),
    );
  });

  test('refuses unknown fields and incompatible native versions', () {
    for (final json in [
      {..._manifest(), 'maps': []},
      {
        ..._manifest(),
        'pack': {..._manifest()['pack'] as Map, 'scripts': null},
      },
      {
        ..._manifest(),
        'compatibility': {
          ..._manifest()['compatibility'] as Map,
          'smartTileCatalogVersion': 6,
        },
      },
    ]) {
      expect(() => codec.decodeUtf8(utf8.encode(jsonEncode(json))),
          _failure('resource_pack.manifest_invalid'));
    }
  });

  test('rejects escaped unpaired Unicode and unsafe numeric JSON values', () {
    final unicode = _manifest();
    (unicode['pack'] as Map)['name'] = String.fromCharCode(0xd800);
    final large = _manifest();
    (large['compatibility'] as Map)['tileWidth'] = 9007199254740992;
    for (final json in [unicode, large]) {
      expect(
        () => codec.decodeUtf8(utf8.encode(jsonEncode(json))),
        _failure('resource_pack.manifest_invalid'),
      );
    }
  });

  test('rejects reordered capability and inventory arrays without hiding it',
      () {
    final json = _manifest();
    (json['compatibility'] as Map)['requiredCapabilities'] = [
      'z.last',
      'a.first'
    ];
    expect(
      () => codec.decodeUtf8(utf8.encode(jsonEncode(json))),
      _failure('resource_pack.manifest_noncanonical_values'),
    );
    final second = _manifest();
    (second['content'] as Map)['files'] = [
      for (final hash in ['b' * 64, 'a' * 64])
        {
          'path': 'blobs/$hash.png',
          'byteLength': 1,
          'mediaType': 'image/png',
          'rawSha256': hash,
        },
    ];
    expect(
      () => codec.decodeUtf8(utf8.encode(jsonEncode(second))),
      _failure('resource_pack.manifest_noncanonical_values'),
    );
  });

  test('admits manifest byte limit exactly and rejects the next byte', () {
    final bytes = utf8.encode(jsonEncode(_manifest()));
    final bounded = ResourcePackManifestCodec(
      policy: ResourcePackSecurityPolicy(maxManifestBytes: bytes.length),
    );
    expect(bounded.decodeUtf8(bytes), isA<ResourcePackManifest>());
    expect(() => bounded.decodeUtf8([...bytes, 32]),
        _failure('resource_pack.manifest_too_large'));
  });

  test('bounds JSON nesting and nodes before native model construction', () {
    const depth = ResourcePackManifestCodec(
      policy: ResourcePackSecurityPolicy(maxJsonDepth: 3),
    );
    const nodes = ResourcePackManifestCodec(
      policy: ResourcePackSecurityPolicy(maxJsonNodes: 10),
    );
    expect(
      () => depth.decodeUtf8(utf8.encode('{"a":{"b":{"c":{"d":0}}}}')),
      _failure('resource_pack.json_complexity'),
    );
    expect(
      () => nodes.decodeUtf8(utf8.encode(jsonEncode(_manifest()))),
      _failure('resource_pack.json_complexity'),
    );
  });

  test('tree digest uses the documented domain, sorted rows and raw hashes',
      () {
    final manifest = ResourcePackManifest.fromJson(_manifest());
    final a = ResourcePackInventoryFile(
      path: 'blobs/${'a' * 64}.png',
      byteLength: 4,
      mediaType: 'image/png',
      rawSha256: 'a' * 64,
    );
    final b = ResourcePackInventoryFile(
      path: 'licenses/${'b' * 64}.txt',
      byteLength: 5,
      mediaType: 'text/plain',
      rawSha256: 'b' * 64,
    );
    final rows = [a.toJson(), manifest.content.catalog.toJson(), b.toJson()];
    final expected = sha256
        .convert(utf8.encode(
          'avelune.asset-pack.tree.v1\n${CanonicalJson.encode(rows)}\n',
        ))
        .toString();
    expect(resourcePackTreeSha256(manifest.content.catalog, [b, a]), expected);
    expect(resourcePackTreeSha256(manifest.content.catalog, [a, b]), expected);
    expect(expected, isNot(sha256.convert(utf8.encode('{}')).toString()));
  });

  test('every signed policy ceiling is immutable and may be lowered', () {
    final limits = <(int, int Function(int))>[
      (
        ResourcePackSecurityPolicy.maxArchiveBytesV1,
        (n) => ResourcePackSecurityPolicy(maxArchiveBytes: n).maxArchiveBytes
      ),
      (
        ResourcePackSecurityPolicy.maxTotalPayloadBytesV1,
        (n) => ResourcePackSecurityPolicy(maxTotalPayloadBytes: n)
            .maxTotalPayloadBytes
      ),
      (
        ResourcePackSecurityPolicy.maxZipEntriesV1,
        (n) => ResourcePackSecurityPolicy(maxZipEntries: n).maxZipEntries
      ),
      (
        ResourcePackSecurityPolicy.maxResourcesV1,
        (n) => ResourcePackSecurityPolicy(maxResources: n).maxResources
      ),
      (
        ResourcePackSecurityPolicy.maxSupportsV1,
        (n) => ResourcePackSecurityPolicy(maxSupports: n).maxSupports
      ),
      (
        ResourcePackSecurityPolicy.maxManifestBytesV1,
        (n) => ResourcePackSecurityPolicy(maxManifestBytes: n).maxManifestBytes
      ),
      (
        ResourcePackSecurityPolicy.maxCatalogBytesV1,
        (n) => ResourcePackSecurityPolicy(maxCatalogBytes: n).maxCatalogBytes
      ),
      (
        ResourcePackSecurityPolicy.maxFileBytesV1,
        (n) => ResourcePackSecurityPolicy(maxFileBytes: n).maxFileBytes
      ),
      (
        ResourcePackSecurityPolicy.maxPreviewBytesV1,
        (n) => ResourcePackSecurityPolicy(maxPreviewBytes: n).maxPreviewBytes
      ),
      (
        ResourcePackSecurityPolicy.maxPreviewFilesV1,
        (n) => ResourcePackSecurityPolicy(maxPreviewFiles: n).maxPreviewFiles
      ),
      (
        ResourcePackSecurityPolicy.maxChunkBytesV1,
        (n) => ResourcePackSecurityPolicy(maxChunkBytes: n).maxChunkBytes
      ),
      (
        ResourcePackSecurityPolicy.maxCacheBytesV1,
        (n) => ResourcePackSecurityPolicy(maxCacheBytes: n).maxCacheBytes
      ),
      (
        ResourcePackSecurityPolicy.maxJsonDepthV1,
        (n) => ResourcePackSecurityPolicy(maxJsonDepth: n).maxJsonDepth
      ),
      (
        ResourcePackSecurityPolicy.maxJsonNodesV1,
        (n) => ResourcePackSecurityPolicy(maxJsonNodes: n).maxJsonNodes
      ),
      (
        ResourcePackSecurityPolicy.maxImageDimensionV1,
        (n) =>
            ResourcePackSecurityPolicy(maxImageDimension: n).maxImageDimension
      ),
      (
        ResourcePackSecurityPolicy.maxImagePixelsV1,
        (n) => ResourcePackSecurityPolicy(maxImagePixels: n).maxImagePixels
      ),
      (
        ResourcePackSecurityPolicy.maxPublishedFilesV1,
        (n) =>
            ResourcePackSecurityPolicy(maxPublishedFiles: n).maxPublishedFiles
      ),
      (
        ResourcePackSecurityPolicy.maxPublicRowsV1,
        (n) => ResourcePackSecurityPolicy(maxPublicRows: n).maxPublicRows
      ),
      (
        ResourcePackSecurityPolicy.maxPublicResponseBytesV1,
        (n) => ResourcePackSecurityPolicy(maxPublicResponseBytes: n)
            .maxPublicResponseBytes
      ),
      (
        ResourcePackSecurityPolicy.maxSelectionPatchEntriesV1,
        (n) => ResourcePackSecurityPolicy(maxSelectionPatchEntries: n)
            .maxSelectionPatchEntries
      ),
      (
        ResourcePackSecurityPolicy.maxActiveOperationsPerProjectV1,
        (n) => ResourcePackSecurityPolicy(maxActiveOperationsPerProject: n)
            .maxActiveOperationsPerProject
      ),
      (
        ResourcePackSecurityPolicy.maxHierarchyEntriesV1,
        (n) => ResourcePackSecurityPolicy(maxHierarchyEntries: n)
            .maxHierarchyEntries
      ),
      (
        ResourcePackSecurityPolicy.maxHierarchyDepthV1,
        (n) =>
            ResourcePackSecurityPolicy(maxHierarchyDepth: n).maxHierarchyDepth
      ),
    ];
    for (final (ceiling, read) in limits) {
      expect(read(ceiling), ceiling);
      expect(read(ceiling + 1), ceiling);
      expect(read(1), 1);
      expect(() => read(0), throwsArgumentError);
    }
  });

  test('custom policies cannot raise the signed format limits', () {
    const policy = ResourcePackSecurityPolicy(
      maxArchiveBytes: 1 << 40,
      maxZipEntries: 100000,
      maxChunkBytes: 1 << 30,
      maxJsonDepth: 10000,
      maxJsonNodes: 100000000,
      maxUnreferencedAge: Duration(days: 90),
    );
    expect(policy.maxArchiveBytes, 512 * 1024 * 1024);
    expect(policy.maxZipEntries, 20000);
    expect(policy.maxChunkBytes, 1024 * 1024);
    expect(policy.maxJsonDepth, 128);
    expect(policy.maxJsonNodes, 1000000);
    expect(policy.maxUnreferencedAge, const Duration(hours: 24));
    expect(
        () => const ResourcePackSecurityPolicy(maxChunkBytes: 0).maxChunkBytes,
        throwsArgumentError);
  });
}
