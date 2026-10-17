import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import 'canonical_json.dart';
import 'game_package_format_exception.dart';
import 'package_path_policy.dart';
import 'resource_pack_inspector.dart';
import 'resource_pack_manifest_codec.dart';
import 'resource_pack_security_policy.dart';

final class ResourcePackBuildSource {
  const ResourcePackBuildSource({
    required this.path,
    required this.byteLength,
    required this.rawSha256,
    required this.mediaType,
    required this.openRead,
  });
  final String path;
  final int byteLength;
  final String rawSha256;
  final String mediaType;
  final Stream<List<int>> Function() openRead;

  ResourcePackInventoryFile get inventory => ResourcePackInventoryFile(
        path: path,
        byteLength: byteLength,
        rawSha256: rawSha256,
        mediaType: mediaType,
      );
}

abstract interface class ResourcePackArchiveSink {
  Future<void> write(Uint8List chunk);
  Future<void> finish();
  Future<void> abort();
}

final class ResourcePackBuildResult {
  const ResourcePackBuildResult(
      {required this.manifest,
      required this.archiveBytes,
      required this.archiveRawSha256});
  final ResourcePackManifest manifest;
  final int archiveBytes;
  final String archiveRawSha256;
}

final class ResourcePackBuilder {
  const ResourcePackBuilder({this.policy = const ResourcePackSecurityPolicy()});
  final ResourcePackSecurityPolicy policy;

  Future<ResourcePackBuildResult> build({
    required ResourcePackMetadata metadata,
    required ResourcePackCatalog catalog,
    required int tileWidth,
    required int tileHeight,
    required Iterable<ResourcePackBuildSource> sources,
    required ResourcePackArchiveSink sink,
  }) async {
    try {
      final files = sources.toList()
        ..sort((a, b) => PackagePathPolicy.compareUtf8(a.path, b.path));
      if (files.length + 2 > policy.maxZipEntries ||
          files.length + 2 >= 65535) {
        _fail('entry_count_exceeded');
      }
      var payloadBytes = 0;
      var previews = 0;
      final names = <String>{};
      for (final file in files) {
        file.inventory;
        if (!names.add(file.path)) _fail('duplicate_path', file.path);
        if (file.byteLength > policy.maxFileBytes) {
          _fail('file_too_large', file.path);
        }
        if (file.path.startsWith('previews/')) {
          previews++;
          if (file.byteLength > policy.maxPreviewBytes ||
              previews > policy.maxPreviewFiles) {
            _fail('preview_too_large', file.path);
          }
        }
        payloadBytes += file.byteLength;
        if (payloadBytes > policy.maxTotalPayloadBytes) {
          _fail('payload_too_large');
        }
      }
      ResourcePackDependencyGraph.fromCatalog(catalog).validateAll();
      final catalogBytes = CanonicalJson.encodeUtf8(catalog.toJson());
      if (catalogBytes.length > policy.maxCatalogBytes) {
        _fail('catalog_too_large');
      }
      payloadBytes += catalogBytes.length;
      if (payloadBytes > policy.maxTotalPayloadBytes) {
        _fail('payload_too_large');
      }
      final catalogFile = ResourcePackInventoryFile(
          path: 'catalog.json',
          byteLength: catalogBytes.length,
          mediaType: 'application/json',
          rawSha256: sha256.convert(catalogBytes).toString());
      final inventory = files.map((f) => f.inventory).toList();
      final manifest = ResourcePackManifest(
          pack: metadata,
          compatibility: ResourcePackCompatibility(
              resourceLibraryCatalogVersion:
                  ResourceLibraryCatalog.currentFormatVersion,
              smartTileCatalogVersion:
                  ProjectSmartTileCatalog.currentFormatVersion,
              borderCatalogVersion:
                  ProjectBorderCatalog.latestSupportedFormatVersion,
              requiredCapabilities:
                  ResourcePackCapabilities.requiredFor(catalog, inventory),
              tileWidth: tileWidth,
              tileHeight: tileHeight),
          content: ResourcePackContent(
              catalog: catalogFile,
              files: inventory,
              treeSha256: resourcePackTreeSha256(catalogFile, inventory)));
      final manifestBytes =
          ResourcePackManifestCodec(policy: policy).encodeUtf8(manifest);
      final entries = <ResourcePackBuildSource>[
        ...files,
        _inline('catalog.json', catalogBytes),
        _inline('manifest.json', manifestBytes),
      ]..sort((a, b) => PackagePathPolicy.compareUtf8(a.path, b.path));
      final prepared = <_Entry>[];
      var offset = 0;
      var centralSize = 0;
      for (final source in entries) {
        final name = Uint8List.fromList(utf8.encode(source.path));
        if (name.length > 65535) _fail('path_invalid', source.path);
        final entry = _Entry(source, name, offset);
        offset += 30 + name.length + source.byteLength;
        centralSize += 46 + name.length;
        if (offset + centralSize + 22 > policy.maxArchiveBytes ||
            offset + centralSize + 22 >= 0xffffffff) {
          _fail('archive_too_large');
        }
        prepared.add(entry);
      }
      for (final entry in prepared) {
        entry.crc = await _read(entry.source);
      }
      final digest = _DigestReceiver();
      final hasher = sha256.startChunkedConversion(digest);
      Future<void> write(List<int> bytes) async {
        for (var start = 0;
            start < bytes.length;
            start += policy.maxChunkBytes) {
          final end = start + policy.maxChunkBytes < bytes.length
              ? start + policy.maxChunkBytes
              : bytes.length;
          final chunk = Uint8List.fromList(bytes.sublist(start, end));
          await sink.write(chunk);
          hasher.add(chunk);
        }
      }

      for (final entry in prepared) {
        await write(entry.localHeader());
        await write(entry.name);
        final crc = await _read(entry.source, write: write);
        if (crc != entry.crc) _fail('source_changed', entry.source.path);
      }
      for (final entry in prepared) {
        await write(entry.centralHeader());
        await write(entry.name);
      }
      final footer = ByteData(22)
        ..setUint32(0, 0x06054b50, Endian.little)
        ..setUint16(8, entries.length, Endian.little)
        ..setUint16(10, entries.length, Endian.little)
        ..setUint32(12, centralSize, Endian.little)
        ..setUint32(16, offset, Endian.little);
      await write(footer.buffer.asUint8List());
      hasher.close();
      await sink.finish();
      return ResourcePackBuildResult(
          manifest: manifest,
          archiveBytes: offset + centralSize + 22,
          archiveRawSha256: digest.value!.toString());
    } catch (_) {
      try {
        await sink.abort();
      } catch (_) {}
      rethrow;
    }
  }

  Future<int> _read(ResourcePackBuildSource source,
      {Future<void> Function(List<int>)? write}) async {
    final result = _DigestReceiver();
    final digest = sha256.startChunkedConversion(result);
    var length = 0;
    var crc = 0;
    await for (final bytes in source.openRead()) {
      if (bytes.length > policy.maxChunkBytes ||
          bytes.any((b) => b < 0 || b > 255)) {
        _fail('source_chunk_invalid', source.path);
      }
      length += bytes.length;
      if (length > source.byteLength) _fail('source_changed', source.path);
      final owned = Uint8List.fromList(bytes);
      digest.add(owned);
      crc = getCrc32(owned, crc);
      if (write != null) await write(owned);
    }
    digest.close();
    if (length != source.byteLength ||
        result.value.toString() != source.rawSha256) {
      _fail('source_changed', source.path);
    }
    return crc;
  }

  ResourcePackBuildSource _inline(String path, Uint8List bytes) =>
      ResourcePackBuildSource(
          path: path,
          byteLength: bytes.length,
          rawSha256: sha256.convert(bytes).toString(),
          mediaType: 'application/json',
          openRead: () async* {
            for (var offset = 0;
                offset < bytes.length;
                offset += policy.maxChunkBytes) {
              final end = offset + policy.maxChunkBytes < bytes.length
                  ? offset + policy.maxChunkBytes
                  : bytes.length;
              yield Uint8List.sublistView(bytes, offset, end);
            }
          });
}

final class _Entry {
  _Entry(this.source, this.name, this.offset);
  final ResourcePackBuildSource source;
  final Uint8List name;
  final int offset;
  late int crc;
  Uint8List localHeader() => (ByteData(30)
        ..setUint32(0, 0x04034b50, Endian.little)
        ..setUint16(4, 20, Endian.little)
        ..setUint16(6, 0x0800, Endian.little)
        ..setUint16(12, 33, Endian.little)
        ..setUint32(14, crc, Endian.little)
        ..setUint32(18, source.byteLength, Endian.little)
        ..setUint32(22, source.byteLength, Endian.little)
        ..setUint16(26, name.length, Endian.little))
      .buffer
      .asUint8List();
  Uint8List centralHeader() => (ByteData(46)
        ..setUint32(0, 0x02014b50, Endian.little)
        ..setUint16(4, 0x0314, Endian.little)
        ..setUint16(6, 20, Endian.little)
        ..setUint16(8, 0x0800, Endian.little)
        ..setUint16(14, 33, Endian.little)
        ..setUint32(16, crc, Endian.little)
        ..setUint32(20, source.byteLength, Endian.little)
        ..setUint32(24, source.byteLength, Endian.little)
        ..setUint16(28, name.length, Endian.little)
        ..setUint32(38, 0x81a40000, Endian.little)
        ..setUint32(42, offset, Endian.little))
      .buffer
      .asUint8List();
}

final class _DigestReceiver implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

Never _fail(String code, [String path = r'$']) =>
    throw GamePackageFormatException(
        code: 'resource_pack.$code',
        path: path,
        message: 'Resource pack export refused: $code.');
