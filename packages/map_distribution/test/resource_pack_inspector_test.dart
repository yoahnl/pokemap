import 'dart:typed_data';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'support/glb_fixture.dart';

import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:map_distribution/src/random_access_zip_structure_reader.dart';
import 'package:test/test.dart';

final class _Source implements RandomAccessPackageSource {
  _Source(this.bytes, {this.maximumRead = 1024 * 1024});

  final Uint8List bytes;
  final int maximumRead;
  int largestRead = 0;

  @override
  int get length => bytes.length;

  @override
  Uint8List readAtSync(int offset, int length) {
    if (length > maximumRead) {
      throw StateError('Read exceeds the allowed I/O window: $length');
    }
    if (length > largestRead) largestRead = length;
    return Uint8List.sublistView(bytes, offset, offset + length);
  }
}

void _packName(String name) {
  if (name == 'manifest.json' || name == 'catalog.json') return;
  if (RegExp(r'^blobs/[a-f0-9]{64}\.png$').hasMatch(name)) return;
  throw GamePackageFormatException(
    code: 'resource_pack.path_invalid',
    path: name,
    message: 'Invalid test pack path.',
  );
}

Uint8List _archive(int entries) => DeterministicZipEncoder.encode([
      for (var index = 0; index < entries - 2; index++)
        MapEntry('blobs/${index.toRadixString(16).padLeft(64, '0')}.png', [1]),
      MapEntry('catalog.json', [123, 125]),
      MapEntry('manifest.json', [123, 125]),
    ]);

void main() {
  group('resource pack inspection', () {
    test(
        'accepts a minimal native catalog and independently verifies the archive',
        () {
      final bytes = _fixture();
      final result =
          const ResourcePackInspector().inspectSourceSync(_Source(bytes));
      expect(result.archiveBytes, bytes.length);
      expect(result.archiveRawSha256, sha256.convert(bytes).toString());
      expect(result.catalog.tilesets, isEmpty);
      expect(result.resourceCount, 0);
    });
    test('validates original PNG and UTF8 licence split across tiny chunks',
        () {
      final bytes = _fixture(png: true);
      final source = _Source(bytes, maximumRead: 7);
      final result = const ResourcePackInspector(
              policy: ResourcePackSecurityPolicy(maxChunkBytes: 7))
          .inspectSourceSync(source);
      expect(result.resourceCount, 1);
      expect(result.catalog.provenance.single.sourceUrl,
          'https://example.invalid/attribution');
      expect(source.largestRead, lessThanOrEqualTo(7));
    });
    test(
        'verifies snapshot fingerprints from decoded pixels and native frame metadata',
        () {
      expect(
          const ResourcePackInspector()
              .inspectSourceSync(_Source(_fixture(borderSnapshot: true)))
              .supportCount,
          1);
      for (final defect in ['snapshot_fingerprint', 'snapshot_rect']) {
        expect(
            () => const ResourcePackInspector().inspectSourceSync(
                _Source(_fixture(borderSnapshot: true, defect: defect))),
            _packFailure('snapshot_invalid'));
      }
    });
    test(
        'validates native semantics and accepts the mixed dimension library profile',
        () {
      for (final defect in ['negative_margin', 'invalid_frame']) {
        expect(
            () => const ResourcePackInspector().inspectSourceSync(
                _Source(_fixture(png: true, defect: defect))),
            _packFailure('native_invalid'));
      }
      expect(
          const ResourcePackInspector()
              .inspectSourceSync(_Source(_fixture(png: true, glb: true)))
              .resourceCount,
          2);
    });
    test('rejects unknown, omitted and overdeclared capabilities', () {
      for (final capabilities in [
        ['unknown.feature'],
        ['images.png'],
        <String>[]
      ]) {
        expect(
            () => const ResourcePackInspector().inspectSourceSync(
                _Source(_fixture(png: true, capabilities: capabilities))),
            _packFailure('capability_mismatch'));
      }
    });
    test('checks exact inventory, tree, entry digests and ZIP CRC', () {
      for (final defect in ['missing', 'extra', 'tree', 'hash', 'crc']) {
        expect(
            () => const ResourcePackInspector().inspectSourceSync(
                _Source(_fixture(png: true, defect: defect))),
            throwsA(isA<GamePackageFormatException>()),
            reason: defect);
      }
    });
    test(
        'refuses duplicate JSON keys, unknown sections and invalid native references',
        () {
      for (final defect in [
        'duplicate_json',
        'unknown_section',
        'missing_reference',
        'invalid_utf8',
        'unsafe_number',
        'world_designation',
        'structured_reference'
      ]) {
        expect(
            () => const ResourcePackInspector().inspectSourceSync(
                _Source(_fixture(png: true, defect: defect))),
            throwsA(isA<GamePackageFormatException>()),
            reason: defect);
      }
    });
    test('validates every orphan dependency and provenance licence', () {
      for (final defect in [
        'orphan',
        'unknown_license',
        'invalid_license',
        'truncated_license',
        'unlisted_license'
      ]) {
        expect(
            () => const ResourcePackInspector(
                    policy: ResourcePackSecurityPolicy(maxChunkBytes: 1))
                .inspectSourceSync(
                    _Source(_fixture(png: true, defect: defect))),
            throwsA(isA<GamePackageFormatException>()),
            reason: defect);
      }
    });
    test(
        'reinspects GLB and rejects announced inspection mismatches and external URIs',
        () {
      for (final defect in [
        'model_inspection',
        'external_buffer',
        'external_texture'
      ]) {
        expect(
            () => const ResourcePackInspector().inspectSourceSync(
                _Source(_fixture(glb: true, defect: defect))),
            throwsA(isA<GamePackageFormatException>()),
            reason: defect);
      }
      expect(
          const ResourcePackInspector()
              .inspectSourceSync(_Source(_fixture(glb: true)))
              .modelInspections,
          hasLength(1));
    });
    test(
        'enforces archive, manifest, catalog, payload and individual byte boundaries',
        () {
      final bytes = _fixture(png: true);
      final result =
          const ResourcePackInspector().inspectSourceSync(_Source(bytes));
      final largest = result.manifest.content.files
          .map((f) => f.byteLength)
          .reduce((a, b) => a > b ? a : b);
      final limits = <(int, ResourcePackSecurityPolicy Function(int))>[
        (bytes.length, (n) => ResourcePackSecurityPolicy(maxArchiveBytes: n)),
        (
          result.manifestBytes,
          (n) => ResourcePackSecurityPolicy(maxManifestBytes: n)
        ),
        (
          result.manifest.content.catalog.byteLength,
          (n) => ResourcePackSecurityPolicy(maxCatalogBytes: n)
        ),
        (
          result.payloadBytes,
          (n) => ResourcePackSecurityPolicy(maxTotalPayloadBytes: n)
        ),
        (largest, (n) => ResourcePackSecurityPolicy(maxFileBytes: n)),
        (
          result.fileCount + 1,
          (n) => ResourcePackSecurityPolicy(maxZipEntries: n)
        ),
      ];
      for (final (limit, policy) in limits) {
        expect(
            ResourcePackInspector(policy: policy(limit))
                .inspectSourceSync(_Source(bytes)),
            isA<ResourcePackInspection>());
        expect(
            () => ResourcePackInspector(policy: policy(limit - 1))
                .inspectSourceSync(_Source(bytes)),
            throwsA(isA<GamePackageFormatException>()));
      }
    });
    test(
        'enforces preview count, preview bytes, image dimensions and decoded pixels',
        () {
      final bytes = _fixture(previews: 2);
      final result =
          const ResourcePackInspector().inspectSourceSync(_Source(bytes));
      final previewSize = result.manifest.content.files
          .map((f) => f.byteLength)
          .reduce((a, b) => a > b ? a : b);
      expect(
          ResourcePackInspector(
                  policy: ResourcePackSecurityPolicy(
                      maxPreviewBytes: previewSize,
                      maxPreviewFiles: 2,
                      maxImageDimension: 2,
                      maxImagePixels: 4))
              .inspectSourceSync(_Source(bytes)),
          isA<ResourcePackInspection>());
      for (final policy in [
        ResourcePackSecurityPolicy(maxPreviewBytes: previewSize - 1),
        const ResourcePackSecurityPolicy(maxPreviewFiles: 1),
        const ResourcePackSecurityPolicy(maxImageDimension: 1),
        const ResourcePackSecurityPolicy(maxImagePixels: 3)
      ]) {
        expect(
            () => ResourcePackInspector(policy: policy)
                .inspectSourceSync(_Source(bytes)),
            throwsA(isA<GamePackageFormatException>()));
      }
    });
    test(
        'counts definitions and support nodes independently at their boundaries',
        () {
      final bytes = _fixture(png: true, resources: 2, supports: 2);
      expect(
          const ResourcePackInspector(
                  policy: ResourcePackSecurityPolicy(
                      maxResources: 2, maxSupports: 2))
              .inspectSourceSync(_Source(bytes))
              .supportCount,
          2);
      for (final policy in [
        const ResourcePackSecurityPolicy(maxResources: 1),
        const ResourcePackSecurityPolicy(maxSupports: 1)
      ]) {
        expect(
            () => ResourcePackInspector(policy: policy)
                .inspectSourceSync(_Source(bytes)),
            throwsA(isA<GamePackageFormatException>()));
      }
    });
  });

  group('native media closure', () {
    test(
        'rejects a truncated PNG with a valid complete IHDR and authentic ZIP hashes',
        () {
      final bytes = _replaceMedia(
          _fixture(png: true), 'image', (bytes) => bytes.sublist(0, 33));
      expect(
          () => const ResourcePackInspector().inspectSourceSync(_Source(bytes)),
          _packFailure('image_invalid'));
    });
    test(
        'rejects PNG corruption and animated PNG instead of decoding unbounded frame collections',
        () {
      final corrupt = _replaceMedia(_fixture(png: true), 'image', (bytes) {
        final copy = Uint8List.fromList(bytes);
        copy[45] ^= 1;
        return copy;
      });
      expect(
          () =>
              const ResourcePackInspector().inspectSourceSync(_Source(corrupt)),
          _packFailure('image_invalid'));
      final missingEnd = _replaceMedia(_fixture(png: true), 'image',
          (bytes) => bytes.sublist(0, bytes.length - 12));
      expect(
          () => const ResourcePackInspector()
              .inspectSourceSync(_Source(missingEnd)),
          _packFailure('image_invalid'));
      final animation = img.Image(width: 2, height: 2)
        ..addFrame(img.Image(width: 2, height: 2));
      final animated = _replaceMedia(
          _fixture(png: true), 'image', (_) => img.encodePng(animation));
      expect(
          () => const ResourcePackInspector()
              .inspectSourceSync(_Source(animated)),
          _packFailure('image_invalid'));
    });
    for (final kind in [
      'element',
      'palette',
      'character_tileset',
      'character_source',
      'character_custom',
      'smart_atlas',
      'smart_frame',
      'image_collection'
    ]) {
      test(
          '$kind resolves native media bounds and rejects the next cell or pixel',
          () {
        final valid = _visualFixture(kind);
        expect(const ResourcePackInspector().inspectSourceSync(_Source(valid)),
            isA<ResourcePackInspection>());
        final invalid = _visualFixture(kind, outside: true);
        expect(
            () => const ResourcePackInspector()
                .inspectSourceSync(_Source(invalid)),
            throwsA(isA<GamePackageFormatException>()));
      });
    }
    test(
        'validates element frame overrides and atlas margins without materializing cells',
        () {
      final fixture = _editFixture(_visualFixture('element'), (catalog) {
        final tilesets = catalog['tilesets'] as List;
        final other = Map<String, dynamic>.from(tilesets.first as Map)
          ..['id'] = 'other';
        tilesets.add(other);
        (((catalog['elements'] as List).first as Map)['frames'] as List)
            .first['tilesetId'] = 'other';
      });
      expect(const ResourcePackInspector().inspectSourceSync(_Source(fixture)),
          isA<ResourcePackInspection>());
      final invalid = _editFixture(fixture, (catalog) {
        (((catalog['elements'] as List).first as Map)['frames'] as List)
            .first['source']['x'] = 1;
      });
      expect(
          () =>
              const ResourcePackInspector().inspectSourceSync(_Source(invalid)),
          _packFailure('frame_out_of_bounds'));
    });
    test('atlas margins and gutters preserve complete-cell bounds', () {
      final media = _replaceMedia(_visualFixture('element'), 'image',
          (_) => img.encodePng(img.Image(width: 7, height: 4)));
      final valid = _editFixture(media, (catalog) {
        final source =
            ((catalog['tilesets'] as List).first as Map)['source'] as Map;
        source['pixelWidth'] = 7;
        source['pixelHeight'] = 4;
        source['marginX'] = 1;
        source['marginY'] = 1;
        source['spacingX'] = 1;
        (((catalog['elements'] as List).first as Map)['frames'] as List)
            .first['source']['x'] = 1;
      });
      expect(const ResourcePackInspector().inspectSourceSync(_Source(valid)),
          isA<ResourcePackInspection>());
      final over = _editFixture(valid, (catalog) {
        (((catalog['elements'] as List).first as Map)['frames'] as List)
            .first['source']['x'] = 2;
      });
      expect(
          () => const ResourcePackInspector().inspectSourceSync(_Source(over)),
          _packFailure('frame_out_of_bounds'));
    });
    test(
        'a collection tileset is portable on its own but raster frame combinations are refused',
        () {
      final collection = _visualFixture('image_collection');
      for (final kind in ['element', 'palette', 'smart_atlas']) {
        final combined = _editFixture(_visualFixture(kind), (catalog) {
          final parsed = ZipDecoder()
              .decodeBytes(collection)
              .files
              .firstWhere((f) => f.name == 'catalog.json');
          final other = jsonDecode(utf8.decode(parsed.readBytes()!)) as Map;
          ((catalog['tilesets'] as List).first as Map)['source'] =
              ((other['tilesets'] as List).first as Map)['source'];
        });
        expect(
            () => const ResourcePackInspector()
                .inspectSourceSync(_Source(combined)),
            _packFailure('media_mismatch'));
      }
    });
    test(
        'reinspects a valid GLB at the 8 MiB JSON chunk ceiling and rejects ceiling plus one before parsing',
        () {
      final padded = _replaceMedia(_fixture(glb: true), 'image',
          (bytes) => _padGlbJson(bytes, 8 * 1024 * 1024));
      expect(const ResourcePackInspector().inspectSourceSync(_Source(padded)),
          isA<ResourcePackInspection>());
      final over = _replaceMedia(_fixture(glb: true), 'image', (bytes) {
        final copy = _padGlbJson(bytes, 8 * 1024 * 1024 + 4);
        ByteData.sublistView(copy)
            .setUint32(12, 8 * 1024 * 1024 + 1, Endian.little);
        return copy;
      });
      expect(
          () => const ResourcePackInspector().inspectSourceSync(_Source(over)),
          throwsA(isA<GamePackageFormatException>().having((e) => e.message,
              'message', contains('JSON chunk exceeds its native bounds'))));
    });
    test(
        'PNG scanline over-inflation is refused for pack images and embedded textures',
        () {
      final bomb = _pngWithInflatedBytes(8 * 1024 * 1024);
      final pngPack = _replaceMedia(_fixture(png: true), 'image', (_) => bomb);
      expect(
          () =>
              const ResourcePackInspector().inspectSourceSync(_Source(pngPack)),
          _packFailure('image_invalid'));
      final glb = _textureGlb2(texturePng: bomb);
      final modelPack = _replaceMedia(_fixture(glb: true), 'image', (_) => glb,
          updateModel: true);
      expect(
          () => const ResourcePackInspector()
              .inspectSourceSync(_Source(modelPack)),
          _packFailure('model_invalid'));
    });
    test(
        'embedded APNG is refused by packs while the default game inspection profile stays compatible',
        () {
      final glb = _textureGlb2(animated: true);
      expect(
          const GlbModel3dInspector().inspect(glb), isA<Model3dInspection>());
      expect(
          () => const GlbModel3dInspector(requireStaticTextures: true)
              .inspect(glb),
          throwsFormatException);
      final bytes = _replaceMedia(_fixture(glb: true), 'image', (_) => glb,
          updateModel: true);
      expect(
          () => const ResourcePackInspector().inspectSourceSync(_Source(bytes)),
          _packFailure('model_invalid'));
    });
    test(
        'character fallback frame sizes match the runtime grid rather than individual atlas cells',
        () {
      final valid = _visualFixture('character_tileset');
      final resized = _replaceMedia(
          valid, 'image', (_) => img.encodePng(img.Image(width: 4, height: 4)));
      final four = _editFixture(resized, (catalog) {
        final source =
            ((catalog['tilesets'] as List).first as Map)['source'] as Map;
        source['pixelWidth'] = 4;
        source['pixelHeight'] = 4;
        final character = (catalog['characters'] as List).first as Map;
        character['frameWidth'] = 2;
        character['frameHeight'] = 2;
      });
      expect(const ResourcePackInspector().inspectSourceSync(_Source(four)),
          isA<ResourcePackInspection>());
      final tooSmall = _replaceMedia(
          four, 'image', (_) => img.encodePng(img.Image(width: 2, height: 2)));
      final two = _editFixture(tooSmall, (catalog) {
        final source =
            ((catalog['tilesets'] as List).first as Map)['source'] as Map;
        source['pixelWidth'] = 2;
        source['pixelHeight'] = 2;
      });
      expect(
          () => const ResourcePackInspector().inspectSourceSync(_Source(two)),
          _packFailure('frame_out_of_bounds'));
    });
    test(
        'GLB embedded texture dimensions and pixels obey lowered native ceilings',
        () {
      final glb = _textureGlb2();
      final bytes = _replaceMedia(_fixture(glb: true), 'image', (_) => glb,
          updateModel: true);
      expect(
          const ResourcePackInspector(
                  policy: ResourcePackSecurityPolicy(
                      maxImageDimension: 2, maxImagePixels: 4))
              .inspectSourceSync(_Source(bytes)),
          isA<ResourcePackInspection>());
      for (final policy in [
        const ResourcePackSecurityPolicy(maxImageDimension: 1),
        const ResourcePackSecurityPolicy(maxImagePixels: 3)
      ]) {
        expect(
            () => ResourcePackInspector(policy: policy)
                .inspectSourceSync(_Source(bytes)),
            _packFailure('model_invalid'));
      }
    });
  });
  group('untrusted pack boundaries', () {
    test('checks signed byte ceilings on sparse archives before media I/O', () {
      for (final (kind, limit, code) in <(String, int, String)>[
        ('file', ResourcePackSecurityPolicy.maxFileBytesV1, 'file_too_large'),
        (
          'payload',
          ResourcePackSecurityPolicy.maxTotalPayloadBytesV1,
          'payload_too_large'
        ),
        (
          'catalog',
          ResourcePackSecurityPolicy.maxCatalogBytesV1,
          'catalog_too_large'
        ),
        (
          'manifest',
          ResourcePackSecurityPolicy.maxManifestBytesV1,
          'manifest_too_large'
        ),
        (
          'preview',
          ResourcePackSecurityPolicy.maxPreviewBytesV1,
          'preview_limit'
        ),
        ('glb', 128 * 1024 * 1024, 'model_too_large'),
      ]) {
        final atLimit = _virtualFixture(kind, limit);
        expect(() => const ResourcePackInspector().inspectSourceSync(atLimit),
            throwsA(isA<_PayloadReached>()),
            reason: kind);
        final overLimit = _virtualFixture(kind, limit + 1);
        expect(() => const ResourcePackInspector().inspectSourceSync(overLimit),
            _packFailure(code),
            reason: kind);
        expect(overLimit.payloadReads, 0);
      }
    });
    test('rejects oversized virtual archives before any source read', () {
      final source =
          _LengthSource(ResourcePackSecurityPolicy.maxArchiveBytesV1 + 1);
      expect(() => const ResourcePackInspector().inspectSourceSync(source),
          _packFailure('archive_too_large'));
      expect(source.reads, 0);
      final boundary =
          _LengthSource(ResourcePackSecurityPolicy.maxArchiveBytesV1);
      expect(() => const ResourcePackInspector().inspectSourceSync(boundary),
          _packFailure('invalidZipStructure'));
      expect(boundary.reads, 1);
    });
    test('checks catalog JSON depth and node boundaries before native parsing',
        () {
      final bytes = _fixture(png: true);
      final source = _Source(bytes);
      final entries = RandomAccessZipStructureReader(
              const GamePackageSecurityPolicy(),
              entryNameValidator: (_) {})
          .read(source)
          .entries;
      final json = [
        for (final e in entries.where((e) => e.name.endsWith('.json')))
          jsonDecode(utf8.decode(source.readAtSync(e.dataOffset, e.size)))
      ];
      final nodes = json.map(_nodes).reduce((a, b) => a > b ? a : b);
      final depth = json.map(_depth).reduce((a, b) => a > b ? a : b);
      expect(
          ResourcePackInspector(
                  policy: ResourcePackSecurityPolicy(
                      maxJsonNodes: nodes, maxJsonDepth: depth))
              .inspectSourceSync(_Source(bytes)),
          isA<ResourcePackInspection>());
      for (final policy in [
        ResourcePackSecurityPolicy(maxJsonNodes: nodes - 1),
        ResourcePackSecurityPolicy(maxJsonDepth: depth - 1)
      ]) {
        expect(
            () => ResourcePackInspector(policy: policy)
                .inspectSourceSync(_Source(bytes)),
            _packFailure('json_complexity'));
      }
    });
    test('preserves native hierarchy count and depth limits', () {
      final bytes = _fixture(supports: 2, chainedSupports: true);
      expect(
          const ResourcePackInspector(
                  policy: ResourcePackSecurityPolicy(
                      maxHierarchyEntries: 2, maxHierarchyDepth: 2))
              .inspectSourceSync(_Source(bytes)),
          isA<ResourcePackInspection>());
      for (final policy in [
        const ResourcePackSecurityPolicy(maxHierarchyEntries: 1),
        const ResourcePackSecurityPolicy(maxHierarchyDepth: 1)
      ]) {
        expect(
            () => ResourcePackInspector(policy: policy)
                .inspectSourceSync(_Source(bytes)),
            _packFailure('hierarchy_limit'));
      }
    });
    test('rejects compression, encryption, ZIP64, symlinks and extra fields',
        () {
      for (final defect in [
        'compressed',
        'encrypted',
        'zip64',
        'symlink',
        'extra',
        'local_mismatch'
      ]) {
        final bytes = _fixture();
        final view = ByteData.sublistView(bytes);
        final central = view.getUint32(bytes.length - 22 + 16, Endian.little);
        switch (defect) {
          case 'compressed':
            view.setUint16(central + 10, 8, Endian.little);
          case 'encrypted':
            view.setUint16(central + 8, 0x0801, Endian.little);
          case 'zip64':
            view.setUint16(bytes.length - 22 + 10, 0xffff, Endian.little);
          case 'symlink':
            view.setUint32(central + 38, 0xa1ff0000, Endian.little);
          case 'extra':
            view.setUint16(central + 30, 1, Endian.little);
          case 'local_mismatch':
            view.setUint32(14, 1, Endian.little);
        }
        expect(
            () =>
                const ResourcePackInspector().inspectSourceSync(_Source(bytes)),
            throwsA(isA<GamePackageFormatException>()),
            reason: defect);
      }
    });
    test(
        'rejects traversal, machine paths, forbidden sections and colliding names',
        () {
      for (final names in [
        ['../manifest.json'],
        ['/manifest.json'],
        ['project/project.json'],
        ['blobs/../catalog.json'],
        ['manifest.json', 'manifest.json'],
        ['manifest.json', 'MANIFEST.json'],
        ['catalog.json', 'catalog.json'],
      ]) {
        final bytes = DeterministicZipEncoder.encode(
            [for (final name in names) MapEntry(name, utf8.encode('{}'))]);
        expect(
            () =>
                const ResourcePackInspector().inspectSourceSync(_Source(bytes)),
            throwsA(isA<GamePackageFormatException>()),
            reason: '$names');
      }
    });
    test('reports declared provenance only when every definition is covered',
        () {
      expect(
          const ResourcePackInspector()
              .inspectSourceSync(_Source(_fixture(png: true)))
              .provenanceStatus,
          ResourcePackProvenanceStatus.declared);
      expect(
          const ResourcePackInspector()
              .inspectSourceSync(_Source(_fixture(png: true, resources: 2)))
              .provenanceStatus,
          ResourcePackProvenanceStatus.unqualified);
    });
  });
  group('asset pack ZIP profile', () {
    test('accepts exactly the configured total and rejects the next entry', () {
      const reader = RandomAccessZipStructureReader(
        GamePackageSecurityPolicy(),
        entryNameValidator: _packName,
        maxTotalEntries: 4,
      );
      expect(reader.read(_Source(_archive(4))).entries, hasLength(4));
      expect(
        () => reader.read(_Source(_archive(5))),
        throwsA(isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'entryCountExceeded',
        )),
      );
    });

    test('keeps central directory reads inside the configured I/O window', () {
      const reader = RandomAccessZipStructureReader(
        GamePackageSecurityPolicy(),
        entryNameValidator: _packName,
        maxTotalEntries: 20000,
        readChunkBytes: 16384,
      );
      final source = _Source(_archive(12000), maximumRead: 16384);
      expect(reader.read(source).entries, hasLength(12000));
      expect(source.largestRead, lessThanOrEqualTo(16384));
    });

    test('preserves game path defaults independently of the new pack profile',
        () {
      const reader =
          RandomAccessZipStructureReader(GamePackageSecurityPolicy());
      final game = DeterministicZipEncoder.encode([
        MapEntry('game-manifest.json', [123, 125]),
        MapEntry('project/project.json', [123, 125]),
      ]);
      expect(reader.read(_Source(game)).entries, hasLength(2));
      expect(
        () => reader.read(_Source(_archive(2))),
        throwsA(isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'invalidPath',
        )),
      );
    });
  });
}

Matcher _packFailure(String code) => throwsA(isA<GamePackageFormatException>()
    .having((e) => e.code, 'code', 'resource_pack.$code'));

Uint8List _fixture(
    {bool png = false,
    bool glb = false,
    bool borderSnapshot = false,
    int previews = 0,
    int resources = 1,
    int supports = 0,
    bool chainedSupports = false,
    List<String>? capabilities,
    String? defect}) {
  final entries = <String, List<int>>{};
  final licence = switch (defect) {
    'invalid_license' => [0xff],
    'truncated_license' => [0xe2, 0x82],
    _ => utf8.encode('Création originale — attribution 🌱'),
  };
  final licencePath = 'licenses/${sha256.convert(licence)}.txt';
  final media = glb
      ? triangleGlb(edit: (json) {
          if (defect == 'external_buffer') {
            json['buffers'][0]['uri'] = 'external.bin';
          }
          if (defect == 'external_texture') {
            json['images'] = [
              {'uri': 'https://example.invalid/image.png'}
            ];
          }
        })
      : img.encodePng(img.Image(width: 2, height: 2));
  final extension = glb ? 'glb' : 'png';
  final mediaPath = 'blobs/${sha256.convert(media)}.$extension';
  final pngBytes = img.encodePng(img.Image(width: 2, height: 2));
  final pngPath = 'blobs/${sha256.convert(pngBytes)}.png';
  if (png && glb) entries[pngPath] = pngBytes;
  if (png || glb || borderSnapshot) {
    entries[mediaPath] = media;
    entries[licencePath] = licence;
  }
  for (var i = 0; i < previews; i++) {
    final image = img.Image(width: 2, height: 2)
      ..setPixelRgba(0, 0, i, 0, 0, 255);
    final bytes = img.encodePng(image);
    entries['previews/${sha256.convert(bytes)}.png'] = bytes;
  }
  final file = ResourcePackFileBinding(
      id: 'image',
      logicalPath: glb
          ? 'assets/models3d/model.glb'
          : borderSnapshot
              ? 'assets/borders/snapshots/original/frame.png'
              : 'assets/images/sheet.png',
      archivePath: mediaPath,
      rawSha256: sha256.convert(media).toString(),
      byteLength: media.length,
      mediaType: glb ? 'model/gltf-binary' : 'image/png',
      provenanceId: 'author',
      licenseIds: [
        defect == 'unknown_license' ? 'licenses/${'0' * 64}.txt' : licencePath
      ]);
  final pngFile = png && glb
      ? ResourcePackFileBinding(
          id: 'png',
          logicalPath: 'assets/images/sheet.png',
          archivePath: pngPath,
          byteLength: pngBytes.length,
          mediaType: 'image/png',
          rawSha256: sha256.convert(pngBytes).toString(),
          provenanceId: 'author',
          licenseIds: [licencePath])
      : file;
  final snapshotFingerprint = computeBorderSnapshotContentFingerprint(frames: [
    BorderSnapshotContentFrame(
      sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
      durationMs: 100,
      rgbaBytes:
          img.decodePng(pngBytes)!.getBytes(order: img.ChannelOrder.rgba),
    )
  ]);
  final snapshotHash =
      defect == 'snapshot_fingerprint' ? '0' * 64 : snapshotFingerprint;
  final catalog = ResourcePackCatalog(
    borderCatalog: borderSnapshot
        ? ProjectBorderCatalog(formatVersion: 10, visualSnapshots: [
            BorderVisualSnapshot(
              id: 'border-snapshot-sha256:$snapshotHash',
              contentFingerprint: snapshotHash,
              frames: [
                BorderVisualFrameSnapshot(
                    relativeAssetPath: file.logicalPath,
                    sourceRectPx: BorderPixelRect(
                        x: 0,
                        y: 0,
                        width: defect == 'snapshot_rect' ? 3 : 2,
                        height: 2),
                    durationMs: 100)
              ],
            )
          ])
        : null,
    tilesets: png
        ? [
            for (var i = 0; i < resources; i++)
              ProjectTilesetEntry(
                  id: 'sheet$i',
                  name: 'Original',
                  relativePath: pngFile.logicalPath,
                  source: ProjectTilesetSource.regularAtlas(
                      assetId: pngFile.id,
                      pixelWidth: 2,
                      pixelHeight: 2,
                      tileWidth: 2,
                      tileHeight: 2))
          ]
        : [],
    models3d: glb
        ? [
            ProjectModel3dEntry(
                id: 'model',
                name: 'Original model',
                sourceAssetId: 'image',
                relativePath: file.logicalPath,
                inspection: GlbModel3dInspector().inspect(triangleGlb()))
          ]
        : [],
    tilesetFolders: [
      for (var i = 0; i < supports; i++)
        ProjectTilesetFolder(
            id: 'folder$i',
            name: 'Folder',
            parentFolderId: chainedSupports && i > 0 ? 'folder${i - 1}' : null)
    ],
    files: png || glb || borderSnapshot ? [file, if (png && glb) pngFile] : [],
    provenance: png || glb || borderSnapshot
        ? [
            ResourcePackProvenance(
                id: 'author',
                author: 'Original author',
                sourceUrl: 'https://example.invalid/attribution',
                licenseIds: [
                  licencePath
                ],
                resources: [
                  if (png)
                    ResourcePackRef(
                        kind: ResourcePackKind.tileset, id: 'sheet0'),
                  if (glb)
                    ResourcePackRef(kind: ResourcePackKind.model3d, id: 'model')
                ])
          ]
        : [],
  ).toJson();
  if (defect == 'world_designation') {
    ((catalog['tilesets'] as List).first as Map)['isWorldTileset'] = true;
  }
  if (defect == 'negative_margin') {
    (((catalog['tilesets'] as List).first as Map)['source'] as Map)['marginX'] =
        -1;
  }
  if (defect == 'invalid_frame') {
    catalog['elements'] = [
      ProjectElementEntry(
          id: 'element',
          name: 'Original',
          tilesetId: 'sheet0',
          categoryId: '',
          frames: []).toJson()
    ];
  }
  if (defect == 'structured_reference') {
    ((catalog['tilesets'] as List).first as Map)['source'] =
        ProjectTilesetSource.imageCollection(
      pages: [
        const ProjectImageCollectionPage(
            id: 'page', assetId: 'image', pixelWidth: 2, pixelHeight: 2)
      ],
      tileDefinitions: [],
      properties: [
        ProjectTilesetProperty(
            name: 'opaque',
            type: ProjectTilesetPropertyType.structured,
            value: {'unknownRef': 'missing'})
      ],
    ).toJson();
  }
  if (defect == 'unknown_section') catalog['maps'] = [];
  if (defect == 'missing_reference') {
    (((catalog['tilesets'] as List).first as Map)['source'] as Map)['assetId'] =
        'missing';
  }
  if (defect == 'orphan') {
    catalog['elementCategories'] = [
      {'id': 'orphan', 'name': 'Orphan', 'parentCategoryId': 'missing'}
    ];
  }
  if (defect == 'unsafe_number') {
    catalog['extras'] = <String, Object?>{
      'smartTilePatternIds': <String>[],
      'unsafe': 9007199254740992
    };
  }
  if (defect == 'model_inspection') {
    (((catalog['models3d'] as List).first as Map)['inspection']
        as Map)['triangleCount'] = 100;
  }
  List<int> catalogBytes = utf8.encode(jsonEncode(catalog));
  if (defect == 'duplicate_json') {
    catalogBytes =
        utf8.encode(jsonEncode(catalog).replaceFirst('{', '{"tilesets":[], '));
  }
  if (defect == 'invalid_utf8') catalogBytes = [0xff];
  entries['catalog.json'] = catalogBytes;
  ResourcePackInventoryFile inventory(String path) => ResourcePackInventoryFile(
      path: path,
      byteLength: entries[path]!.length,
      rawSha256: sha256.convert(entries[path]!).toString(),
      mediaType: path == 'catalog.json'
          ? 'application/json'
          : path.endsWith('.txt')
              ? 'text/plain'
              : path.endsWith('.glb')
                  ? 'model/gltf-binary'
                  : 'image/png');
  final contentFiles =
      entries.keys.where((p) => p != 'catalog.json').map(inventory).toList();
  final catalogInventory = inventory('catalog.json');
  final declared = capabilities ??
      [
        if (png || borderSnapshot || previews > 0) 'images.png',
        if (glb) ...['models.glb', 'resources.model3d'],
        if (png) 'resources.tileset',
        if (defect == 'invalid_frame') 'resources.element'
      ];
  final manifest = ResourcePackManifest.fromJson({
    'format': 'avelune.asset-pack',
    'formatVersion': 1,
    'pack': {
      'id': 'original.workshop',
      'version': '1.0.0',
      'name': 'Original',
      'description': '',
      'universeId': 'original',
      'authors': ['Original'],
      'provenance': 'Original'
    },
    'compatibility': {
      'resourceLibraryCatalogVersion': 2,
      'smartTileCatalogVersion': 7,
      'borderCatalogVersion': 10,
      'requiredCapabilities': declared,
      'tileWidth': 2,
      'tileHeight': 2
    },
    'content': {
      'catalog': catalogInventory.toJson(),
      'files': contentFiles.map((e) => e.toJson()).toList(),
      'treeSha256': defect == 'tree'
          ? '0' * 64
          : resourcePackTreeSha256(catalogInventory, contentFiles)
    },
  });
  entries['manifest.json'] = ResourcePackManifestCodec().encodeUtf8(manifest);
  if (defect == 'missing') entries.remove(mediaPath);
  if (defect == 'extra') entries['licenses/${'e' * 64}.txt'] = [1];
  if (defect == 'unlisted_license') entries.remove(licencePath);
  if (defect == 'hash') entries[mediaPath] = List.filled(media.length, 1);
  final zip = DeterministicZipEncoder.encode(entries.entries.toList()
    ..sort((a, b) => PackagePathPolicy.compareUtf8(a.key, b.key)));
  if (defect == 'crc') {
    final structure = RandomAccessZipStructureReader(
            const GamePackageSecurityPolicy(),
            entryNameValidator: (_) {})
        .read(_Source(zip));
    zip[structure.entries.first.dataOffset] ^= 1;
  }
  return zip;
}

int _nodes(Object? value) =>
    1 +
    switch (value) {
      Map() => value.values.fold(0, (int count, item) => count + _nodes(item)),
      List() => value.fold(0, (int count, item) => count + _nodes(item)),
      _ => 0,
    };
int _depth(Object? value) => switch (value) {
      Map() => 1 +
          value.values.fold(0,
              (int depth, item) => _depth(item) > depth ? _depth(item) : depth),
      List() => 1 +
          value.fold(0,
              (int depth, item) => _depth(item) > depth ? _depth(item) : depth),
      _ => 0,
    };

final class _LengthSource implements RandomAccessPackageSource {
  _LengthSource(this.length);
  @override
  final int length;
  int reads = 0;
  @override
  Uint8List readAtSync(int offset, int length) {
    reads++;
    throw StateError('Virtual archive boundary reached.');
  }
}

final class _PayloadReached implements Exception {}

final class _SparseEntry {
  _SparseEntry(this.name, this.size, [this.bytes]);
  final String name;
  final int size;
  final List<int>? bytes;
}

final class _VirtualZip implements RandomAccessPackageSource {
  _VirtualZip(List<_SparseEntry> entries) {
    entries.sort((a, b) => PackagePathPolicy.compareUtf8(a.name, b.name));
    final central = BytesBuilder(copy: false);
    var offset = 0;
    for (final entry in entries) {
      final name = utf8.encode(entry.name);
      final crc = entry.bytes == null ? 0 : getCrc32(entry.bytes!);
      final local = ByteData(30)
        ..setUint32(0, 0x04034b50, Endian.little)
        ..setUint16(4, 20, Endian.little)
        ..setUint16(6, 0x0800, Endian.little)
        ..setUint16(12, 33, Endian.little)
        ..setUint32(14, crc, Endian.little)
        ..setUint32(18, entry.size, Endian.little)
        ..setUint32(22, entry.size, Endian.little)
        ..setUint16(26, name.length, Endian.little);
      segments.add((
        offset,
        Uint8List.fromList([...local.buffer.asUint8List(), ...name])
      ));
      if (entry.bytes != null) {
        segments
            .add((offset + 30 + name.length, Uint8List.fromList(entry.bytes!)));
      } else {
        virtualStarts.add(offset + 30 + name.length);
      }
      final header = ByteData(46)
        ..setUint32(0, 0x02014b50, Endian.little)
        ..setUint16(4, 0x0314, Endian.little)
        ..setUint16(6, 20, Endian.little)
        ..setUint16(8, 0x0800, Endian.little)
        ..setUint16(14, 33, Endian.little)
        ..setUint32(16, crc, Endian.little)
        ..setUint32(20, entry.size, Endian.little)
        ..setUint32(24, entry.size, Endian.little)
        ..setUint16(28, name.length, Endian.little)
        ..setUint32(38, 0x81a40000, Endian.little)
        ..setUint32(42, offset, Endian.little);
      central.add(header.buffer.asUint8List());
      central.add(name);
      offset += 30 + name.length + entry.size;
    }
    final directory = central.takeBytes();
    segments.add((offset, directory));
    final footer = ByteData(22)
      ..setUint32(0, 0x06054b50, Endian.little)
      ..setUint16(8, entries.length, Endian.little)
      ..setUint16(10, entries.length, Endian.little)
      ..setUint32(12, directory.length, Endian.little)
      ..setUint32(16, offset, Endian.little);
    segments.add((offset + directory.length, footer.buffer.asUint8List()));
    length = offset + directory.length + 22;
  }
  final segments = <(int, Uint8List)>[];
  final virtualStarts = <int>{};
  int payloadReads = 0;
  @override
  late final int length;
  @override
  Uint8List readAtSync(int offset, int length) {
    if (length > 1024 * 1024) throw StateError('Unbounded sparse I/O.');
    if (virtualStarts.contains(offset)) {
      payloadReads++;
      throw _PayloadReached();
    }
    final output = Uint8List(length);
    for (final (start, bytes) in segments) {
      final from = offset > start ? offset : start;
      final to = offset + length < start + bytes.length
          ? offset + length
          : start + bytes.length;
      if (to > from) {
        output.setRange(from - offset, to - offset, bytes, from - start);
      }
    }
    return output;
  }
}

_VirtualZip _virtualFixture(String kind, int size) {
  final catalogBytes = CanonicalJson.encodeUtf8(ResourcePackCatalog().toJson());
  final catalog = ResourcePackInventoryFile(
      path: 'catalog.json',
      byteLength: kind == 'catalog' ? size : catalogBytes.length,
      mediaType: 'application/json',
      rawSha256: sha256.convert(catalogBytes).toString());
  final files = <ResourcePackInventoryFile>[];
  final entries = <_SparseEntry>[
    _SparseEntry('catalog.json', catalog.byteLength,
        kind == 'catalog' ? null : catalogBytes)
  ];
  void add(
      String hash, int length, String root, String extension, String mime) {
    final path = '$root/$hash.$extension';
    files.add(ResourcePackInventoryFile(
        path: path, byteLength: length, mediaType: mime, rawSha256: hash));
    entries.add(_SparseEntry(path, length));
  }

  if (kind == 'payload') {
    add('0' * 64, ResourcePackSecurityPolicy.maxFileBytesV1, 'blobs', 'png',
        'image/png');
    add(
        '1' * 64,
        size - catalog.byteLength - ResourcePackSecurityPolicy.maxFileBytesV1,
        'blobs',
        'png',
        'image/png');
  } else if (kind == 'file' || kind == 'preview' || kind == 'glb') {
    add(
        '0' * 64,
        size,
        kind == 'preview' ? 'previews' : 'blobs',
        kind == 'glb' ? 'glb' : 'png',
        kind == 'glb' ? 'model/gltf-binary' : 'image/png');
  }
  final manifest = ResourcePackManifest.fromJson({
    'format': 'avelune.asset-pack',
    'formatVersion': 1,
    'pack': {
      'id': 'original',
      'version': '1.0.0',
      'name': 'Original',
      'description': '',
      'universeId': 'original',
      'authors': ['Original'],
      'provenance': 'Original'
    },
    'compatibility': {
      'resourceLibraryCatalogVersion': 2,
      'smartTileCatalogVersion': 7,
      'borderCatalogVersion': 10,
      'requiredCapabilities': [
        if (kind == 'glb') 'models.glb' else if (files.isNotEmpty) 'images.png'
      ],
      'tileWidth': 2,
      'tileHeight': 2
    },
    'content': {
      'catalog': catalog.toJson(),
      'files': files.map((f) => f.toJson()).toList(),
      'treeSha256': resourcePackTreeSha256(catalog, files)
    },
  });
  final bytes = ResourcePackManifestCodec().encodeUtf8(manifest);
  entries.add(_SparseEntry(
      'manifest.json',
      kind == 'manifest' ? size : bytes.length,
      kind == 'manifest' ? null : bytes));
  return _VirtualZip(entries);
}

Uint8List _editFixture(
    Uint8List input, void Function(Map<String, dynamic>) edit) {
  final archive = ZipDecoder().decodeBytes(input);
  final entries = {
    for (final file in archive.files) file.name: file.readBytes()!
  };
  final catalog =
      jsonDecode(utf8.decode(entries['catalog.json']!)) as Map<String, dynamic>;
  edit(catalog);
  return _rebuildFixture(entries, catalog);
}

Uint8List _rebuildFixture(
    Map<String, List<int>> entries, Map<String, dynamic> catalog) {
  entries['catalog.json'] = utf8.encode(jsonEncode(catalog));
  ResourcePackInventoryFile inventory(String path) => ResourcePackInventoryFile(
      path: path,
      byteLength: entries[path]!.length,
      mediaType: path == 'catalog.json'
          ? 'application/json'
          : path.endsWith('.png')
              ? 'image/png'
              : path.endsWith('.glb')
                  ? 'model/gltf-binary'
                  : 'text/plain',
      rawSha256: sha256.convert(entries[path]!).toString());
  final catalogFile = inventory('catalog.json');
  final files = entries.keys
      .where((path) => path != 'catalog.json' && path != 'manifest.json')
      .map(inventory)
      .toList();
  final original = jsonDecode(utf8.decode(entries['manifest.json']!))
      as Map<String, dynamic>;
  original['content'] = {
    'catalog': catalogFile.toJson(),
    'files': files.map((f) => f.toJson()).toList(),
    'treeSha256': resourcePackTreeSha256(catalogFile, files)
  };
  (original['compatibility'] as Map)['requiredCapabilities'] =
      ResourcePackCapabilities.requiredFor(
          ResourcePackCatalog.fromJson(catalog), files);
  entries['manifest.json'] = ResourcePackManifestCodec()
      .encodeUtf8(ResourcePackManifest.fromJson(original));
  return DeterministicZipEncoder.encode(entries.entries.toList()
    ..sort((a, b) => PackagePathPolicy.compareUtf8(a.key, b.key)));
}

Uint8List _replaceMedia(
    Uint8List input, String id, List<int> Function(List<int>) replace,
    {bool updateModel = false}) {
  final archive = ZipDecoder().decodeBytes(input);
  final entries = <String, List<int>>{
    for (final file in archive.files) file.name: file.readBytes()!
  };
  final catalog =
      jsonDecode(utf8.decode(entries['catalog.json']!)) as Map<String, dynamic>;
  final file =
      (catalog['files'] as List).cast<Map>().firstWhere((f) => f['id'] == id);
  final previous = file['archivePath'] as String;
  final bytes = replace(entries.remove(previous)!);
  final hash = sha256.convert(bytes).toString();
  final path = 'blobs/$hash.${previous.split('.').last}';
  entries[path] = bytes;
  file['archivePath'] = path;
  file['rawSha256'] = hash;
  file['byteLength'] = bytes.length;
  if (updateModel) {
    for (final model in (catalog['models3d'] as List).cast<Map>()) {
      if (model['sourceAssetId'] == id) {
        model['inspection'] = GlbModel3dInspector().inspect(bytes).toJson();
      }
    }
  }
  return _rebuildFixture(entries, catalog);
}

Uint8List _visualFixture(String kind, {bool outside = false}) {
  final fixture = _editFixture(_fixture(png: true), (catalog) {
    final source = TilesetSourceRect(x: outside ? 1 : 0, y: 0);
    final tile = (catalog['tilesets'] as List).first as Map;
    switch (kind) {
      case 'element':
        catalog['elementCategories'] = [
          const ProjectElementCategory(id: 'decor', name: 'Decor').toJson()
        ];
        catalog['elements'] = [
          ProjectElementEntry(
              id: 'decor',
              name: 'Decor',
              tilesetId: 'sheet0',
              categoryId: 'decor',
              frames: [TilesetVisualFrame(source: source)]).toJson()
        ];
      case 'palette':
        tile['paletteEntries'] = [
          TilesetPaletteEntry(
              id: 'palette',
              frames: [TilesetVisualFrame(source: source)]).toJson()
        ];
      case 'character_tileset':
        catalog['characters'] = [
          ProjectCharacterEntry(
              id: 'character',
              name: 'Original',
              tilesetId: 'sheet0',
              frameWidth: 1,
              frameHeight: 1,
              animations: [
                CharacterAnimation(
                    state: CharacterAnimationState.idle,
                    direction: EntityFacing.south,
                    frames: [CharacterAnimationFrame(source: source)])
              ]).toJson()
        ];
      case 'character_source':
        catalog['characters'] = [
          ProjectCharacterEntry(
              id: 'character',
              name: 'Original',
              tilesetId: 'sheet0',
              frameWidth: 1,
              frameHeight: 1,
              animations: [
                CharacterAnimation(
                    state: CharacterAnimationState.idle,
                    direction: EntityFacing.south,
                    sourceAssetId: 'image',
                    frames: [
                      CharacterAnimationFrame(
                          source: TilesetSourceRect(x: outside ? 2 : 1, y: 1))
                    ])
              ]).toJson()
        ];
      case 'character_custom':
        catalog['characterStudioCatalog'] =
            const ProjectCharacterStudioCatalog(customAnimationDefinitions: [
          CharacterCustomAnimationDefinition(
              id: 'custom',
              displayName: 'Custom',
              mode: CharacterCustomAnimationMode.single)
        ]).toJson();
        catalog['characters'] = [
          ProjectCharacterEntry(
              id: 'character',
              name: 'Original',
              tilesetId: 'sheet0',
              frameWidth: 1,
              frameHeight: 1,
              customAnimations: [
                CharacterCustomAnimationClip(
                    definitionId: 'custom',
                    sourceAssetId: 'image',
                    frames: [
                      CharacterAnimationFrame(
                          source: TilesetSourceRect(x: outside ? 2 : 1, y: 1))
                    ])
              ]).toJson()
        ];
      case 'smart_atlas':
      case 'smart_frame':
        final smart = ProjectSmartTileCatalog(
            atlases: [
              ProjectSmartTileAtlas(
                  id: 'atlas',
                  name: 'Atlas',
                  tilesetId: 'sheet0',
                  cellWidth: 2,
                  cellHeight: 2,
                  columns: kind == 'smart_atlas' && outside ? 2 : 1,
                  rows: 1)
            ],
            animations: kind == 'smart_frame'
                ? [
                    ProjectSmartTileAnimation(
                        id: 'animation',
                        name: 'Animation',
                        frames: [
                          ProjectSmartTileAnimationFrame(
                              frame: SmartTileFrameRef(
                                  atlasId: 'atlas',
                                  column: outside ? 1 : 0,
                                  row: 0),
                              durationMs: 100)
                        ])
                  ]
                : []);
        catalog['smartTileCatalog'] = smart.toJson()..remove('drafts');
      case 'image_collection':
        tile['source'] = ProjectTilesetSource.imageCollection(pages: [
          const ProjectImageCollectionPage(
              id: 'page', assetId: 'image', pixelWidth: 2, pixelHeight: 2)
        ], tileDefinitions: [
          ProjectImageCollectionTileDefinition(
              tileId: 7,
              pageId: 'page',
              sourceRect: ProjectTilesetPixelRect(
                  x: outside ? 2 : 0, y: 0, width: 2, height: 2))
        ]).toJson();
    }
  });
  if (kind != 'character_tileset') return fixture;
  final resized = _replaceMedia(
      fixture, 'image', (_) => img.encodePng(img.Image(width: 4, height: 4)));
  return _editFixture(resized, (catalog) {
    final source =
        ((catalog['tilesets'] as List).first as Map)['source'] as Map;
    source['pixelWidth'] = 4;
    source['pixelHeight'] = 4;
  });
}

Uint8List _padGlbJson(List<int> input, int jsonLength) {
  final data = ByteData.sublistView(Uint8List.fromList(input));
  final previousLength = data.getUint32(12, Endian.little);
  final tail = input.sublist(20 + previousLength);
  final output = Uint8List(20 + jsonLength + tail.length);
  output.setRange(0, 20 + previousLength, input);
  output.fillRange(20 + previousLength, 20 + jsonLength, 32);
  output.setRange(20 + jsonLength, output.length, tail);
  ByteData.sublistView(output)
    ..setUint32(8, output.length, Endian.little)
    ..setUint32(12, jsonLength, Endian.little);
  return output;
}

List<int> _textureGlb2({bool animated = false, Uint8List? texturePng}) {
  final input = texturedGlb();
  final length = ByteData.sublistView(Uint8List.fromList(input))
      .getUint32(12, Endian.little);
  final document = jsonDecode(utf8.decode(input.sublist(20, 20 + length)))
      as Map<String, dynamic>;
  final image = img.Image(width: 2, height: 2);
  if (animated) image.addFrame(img.Image(width: 2, height: 2));
  final png = texturePng ?? img.encodePng(image);
  final binary = Uint8List(60 + png.length)
    ..setRange(0, 60, input.sublist(28 + length, 88 + length))
    ..setRange(60, 60 + png.length, png);
  document['buffers'][0]['byteLength'] = binary.length;
  document['bufferViews'][2]['byteLength'] = png.length;
  return encodeGlb(document, binary);
}

Uint8List _pngWithInflatedBytes(int count) {
  final output = BytesBuilder()..add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> bytes) {
    final tagged = [...ascii.encode(type), ...bytes];
    output.add((ByteData(4)..setUint32(0, bytes.length)).buffer.asUint8List());
    output.add(tagged);
    output.add(
        (ByteData(4)..setUint32(0, getCrc32(tagged))).buffer.asUint8List());
  }

  final header = ByteData(13)
    ..setUint32(0, 2)
    ..setUint32(4, 2)
    ..setUint8(8, 8)
    ..setUint8(9, 6);
  chunk('IHDR', header.buffer.asUint8List());
  chunk('IDAT', ZLibEncoder().encode(Uint8List(count)));
  chunk('IEND', []);
  return output.takeBytes();
}
