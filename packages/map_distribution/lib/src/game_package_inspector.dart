import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'game_package_compatibility.dart';
import 'game_package_content_validator.dart';
import 'game_package_format_exception.dart';
import 'game_package_inspection.dart';
import 'game_package_manifest.dart';
import 'game_package_manifest_codec.dart';
import 'game_package_project_validator.dart';
import 'game_package_security_policy.dart';
import 'random_access_package_source.dart';
import 'random_access_zip_structure_reader.dart';
import 'zip_structure_reader.dart';

/// Inspects untrusted package bytes without touching the filesystem.
final class GamePackageInspector {
  const GamePackageInspector({
    this.policy = const GamePackageSecurityPolicy(),
    this.trustRequirement = PackageTrustRequirement.signatureOptional,
    this.signatureVerifier,
    this.hostCompatibility,
  });

  final GamePackageSecurityPolicy policy;
  final PackageTrustRequirement trustRequirement;
  final GamePackageSignatureVerifier? signatureVerifier;
  final GamePackageHostCompatibility? hostCompatibility;

  /// Inspects a package through bounded random-access reads.
  ///
  /// The archive and media payloads are hashed incrementally. Only the
  /// manifest, JSON/text entries, and a bounded media header are materialized.
  GamePackageInspectionResult inspectSourceSync(
    RandomAccessPackageSource source,
  ) {
    final fileLength = source.length;
    if (fileLength > policy.maxArchiveBytes) {
      _fail('archiveTooLarge', r'$', 'Package archive exceeds policy.');
    }
    final structure = RandomAccessZipStructureReader(policy).read(source);
    final manifests = structure.entries
        .where((entry) => entry.name == 'game-manifest.json')
        .toList(growable: false);
    if (manifests.isEmpty) {
      _fail('manifestMissing', r'$', 'game-manifest.json is required.');
    }
    if (manifests.length > 1) {
      _fail('duplicateEntry', 'game-manifest.json', 'Duplicate manifest.');
    }
    final manifestEntry = manifests.single;
    if (manifestEntry.size > policy.maxManifestBytes) {
      _fail(
        'manifestTooLarge',
        'game-manifest.json',
        'Manifest exceeds policy.',
      );
    }
    final payloadEntries = structure.entries
        .where((entry) => entry.name != 'game-manifest.json')
        .toList(growable: false);
    final payloadTotal = _validatePayloadQuotas(
      payloadEntries.map((entry) => (name: entry.name, size: entry.size)),
    );
    final manifestBytes = _readAt(
      source,
      manifestEntry.dataOffset,
      manifestEntry.size,
    );
    GamePackageBinarySecretScanner('game-manifest.json').add(manifestBytes);
    if (getCrc32(manifestBytes) != manifestEntry.crc32) {
      _fail(
        'hashMismatch',
        manifestEntry.name,
        'ZIP CRC does not match content.',
      );
    }
    const codec = GamePackageManifestCodec();
    final manifest = codec.decodeUtf8(manifestBytes);
    final signatureStatus = _verifySignature(manifest, codec);
    final compatibility = _evaluateCompatibility(manifest);
    final rawByPath = <String, RandomAccessZipStructureEntry>{
      for (final entry in payloadEntries) entry.name: entry,
    };
    final inventoryByPath = <String, GamePackageFileEntry>{
      for (final entry in manifest.content.files) entry.path: entry,
    };
    for (final path in rawByPath.keys) {
      if (!inventoryByPath.containsKey(path)) {
        _fail(
          'unlistedFile',
          path,
          'Archive entry is absent from inventory.',
        );
      }
    }
    for (final path in inventoryByPath.keys) {
      if (!rawByPath.containsKey(path)) {
        _fail(
          'missingFile',
          path,
          'Inventory entry is absent from archive.',
        );
      }
    }

    final contentValidator = GamePackageContentValidator(policy);
    for (final inventoryEntry in manifest.content.files) {
      final raw = rawByPath[inventoryEntry.path]!;
      if (raw.size != inventoryEntry.size) {
        _fail(
          'sizeMismatch',
          raw.name,
          'Extracted size differs from the inventory.',
        );
      }
      if (p.extension(raw.name).toLowerCase() == '.json' &&
          raw.size > policy.maxJsonBytes) {
        _fail(
          'entryTooLarge',
          raw.name,
          'JSON file exceeds its dedicated quota.',
        );
      }
      final streamed = _streamEntry(
        source,
        raw,
        bufferWholeEntry: _requiresWholeContent(raw.name),
      );
      if (streamed.crc32 != raw.crc32 ||
          streamed.sha256 != inventoryEntry.sha256) {
        _fail(
          'hashMismatch',
          raw.name,
          'Payload digest differs from the inventory.',
        );
      }
      contentValidator.validate(
        inventoryEntry,
        streamed.validationBytes,
        streamedTextValidated: _isStreamValidatedText(raw.name),
      );
      if (raw.name == 'project/project.json') {
        GamePackageProjectValidator(policy).validate(
          manifest,
          streamed.validationBytes,
          payloadPaths: rawByPath.keys.toSet(),
        );
      }
    }
    if (source.length != fileLength) {
      _fail(
        'invalidZipStructure',
        r'$',
        'Package changed while it was being inspected.',
      );
    }
    final packageSha256 = _hashSource(source, fileLength);
    if (source.length != fileLength) {
      _fail(
        'invalidZipStructure',
        r'$',
        'Package changed while its receipt was being created.',
      );
    }
    final receipt = GamePackageInspectionReceipt(
      receiptVersion: 1,
      securityPolicyVersion: 1,
      gameId: manifest.gameId,
      gameVersion: manifest.gameVersion.toString(),
      treeSha256: manifest.content.treeSha256,
      manifestSha256: sha256.convert(manifestBytes).toString(),
      packageSha256: packageSha256,
      archiveBytes: fileLength,
      payloadBytes: payloadTotal,
      fileCount: payloadEntries.length,
      signatureStatus: signatureStatus,
    );
    return GamePackageInspectionResult(
      manifest: manifest,
      payloadPaths: manifest.content.files.map((entry) => entry.path).toList(),
      signatureStatus: signatureStatus,
      compatibility: compatibility,
      receipt: receipt,
    );
  }

  GamePackageInspectionResult inspect(List<int> packageBytes) {
    if (packageBytes.length > policy.maxArchiveBytes) {
      _fail('archiveTooLarge', r'$', 'Package archive exceeds policy.');
    }
    if (packageBytes.any((byte) => byte < 0 || byte > 255)) {
      _fail('invalidZipStructure', r'$', 'Package contains non-byte values.');
    }
    final bytes = packageBytes is Uint8List
        ? packageBytes
        : Uint8List.fromList(packageBytes);
    final structure = ZipStructureReader(policy).read(bytes);
    final manifests = structure.entries
        .where((entry) => entry.name == 'game-manifest.json')
        .toList(growable: false);
    if (manifests.isEmpty) {
      _fail('manifestMissing', r'$', 'game-manifest.json is required.');
    }
    if (manifests.length > 1) {
      _fail('duplicateEntry', 'game-manifest.json', 'Duplicate manifest.');
    }
    final manifestEntry = manifests.single;
    if (manifestEntry.size > policy.maxManifestBytes) {
      _fail(
        'manifestTooLarge',
        'game-manifest.json',
        'Manifest exceeds policy.',
      );
    }
    final payloadEntries = structure.entries
        .where((entry) => entry.name != 'game-manifest.json')
        .toList(growable: false);
    final payloadTotal = _validatePayloadQuotas(
      payloadEntries.map((entry) => (name: entry.name, size: entry.size)),
    );
    _verifyCrc(manifestEntry);
    GamePackageBinarySecretScanner('game-manifest.json')
        .add(manifestEntry.data);
    const codec = GamePackageManifestCodec();
    final manifest = codec.decodeUtf8(manifestEntry.data);
    final signatureStatus = _verifySignature(manifest, codec);
    final compatibility = _evaluateCompatibility(manifest);

    final rawByPath = <String, ZipStructureEntry>{
      for (final entry in payloadEntries) entry.name: entry,
    };
    final inventoryByPath = <String, GamePackageFileEntry>{
      for (final entry in manifest.content.files) entry.path: entry,
    };
    for (final path in rawByPath.keys) {
      if (!inventoryByPath.containsKey(path)) {
        _fail('unlistedFile', path, 'Archive entry is absent from inventory.');
      }
    }
    for (final path in inventoryByPath.keys) {
      if (!rawByPath.containsKey(path)) {
        _fail('missingFile', path, 'Inventory entry is absent from archive.');
      }
    }

    final contentValidator = GamePackageContentValidator(policy);
    for (final inventoryEntry in manifest.content.files) {
      final raw = rawByPath[inventoryEntry.path]!;
      _verifyCrc(raw);
      if (raw.size != inventoryEntry.size) {
        _fail(
          'sizeMismatch',
          raw.name,
          'Extracted size differs from the inventory.',
        );
      }
      final digest = sha256.convert(raw.data).toString();
      if (digest != inventoryEntry.sha256) {
        _fail(
          'hashMismatch',
          raw.name,
          'Payload digest differs from the inventory.',
        );
      }
      contentValidator.validate(inventoryEntry, raw.data);
      if (raw.name == 'project/project.json') {
        GamePackageProjectValidator(policy).validate(
          manifest,
          raw.data,
          payloadPaths: rawByPath.keys.toSet(),
        );
      }
    }

    final receipt = GamePackageInspectionReceipt(
      receiptVersion: 1,
      securityPolicyVersion: 1,
      gameId: manifest.gameId,
      gameVersion: manifest.gameVersion.toString(),
      treeSha256: manifest.content.treeSha256,
      manifestSha256: sha256.convert(manifestEntry.data).toString(),
      packageSha256: sha256.convert(bytes).toString(),
      archiveBytes: bytes.length,
      payloadBytes: payloadTotal,
      fileCount: payloadEntries.length,
      signatureStatus: signatureStatus,
    );
    return GamePackageInspectionResult(
      manifest: manifest,
      payloadPaths: manifest.content.files.map((entry) => entry.path).toList(),
      signatureStatus: signatureStatus,
      compatibility: compatibility,
      receipt: receipt,
    );
  }

  PackageSignatureStatus _verifySignature(
    GamePackageManifest manifest,
    GamePackageManifestCodec codec,
  ) {
    final signature = manifest.signature;
    if (signature == null) {
      if (trustRequirement == PackageTrustRequirement.signatureRequired) {
        _fail(
          'signatureRequired',
          r'$.signature',
          'This package channel requires a publisher signature.',
        );
      }
      return PackageSignatureStatus.notPresent;
    }
    final verifier = signatureVerifier;
    if (verifier == null) {
      if (trustRequirement == PackageTrustRequirement.signatureRequired) {
        _fail(
          'signatureInvalid',
          r'$.signature',
          'No trusted verifier is available for this publisher key.',
        );
      }
      return PackageSignatureStatus.presentUnverified;
    }
    var valid = false;
    try {
      valid = verifier.verify(
        keyId: signature.keyId,
        preimage: codec.signaturePreimageUtf8(manifest),
        signature: base64Decode(signature.value),
      );
    } on Object {
      valid = false;
    }
    if (!valid) {
      _fail(
        'signatureInvalid',
        r'$.signature',
        'Publisher signature verification failed.',
      );
    }
    return PackageSignatureStatus.verified;
  }

  GamePackageCompatibilityResult? _evaluateCompatibility(
    GamePackageManifest manifest,
  ) {
    final host = hostCompatibility;
    if (host == null) return null;
    final compatibility =
        const GamePackageCompatibilityEvaluator().evaluate(manifest, host);
    if (compatibility.decision == GamePackageCompatibilityDecision.reject) {
      throw GamePackageFormatException(
        code: compatibility.code!,
        path: r'$.compatibility',
        message: 'Package is not compatible with this host.',
        relatedCodes: compatibility.blockingCodes,
      );
    }
    return compatibility;
  }

  int _validatePayloadQuotas(
    Iterable<({String name, int size})> entries,
  ) {
    var entryCount = 0;
    var payloadTotal = 0;
    for (final entry in entries) {
      entryCount++;
      if (entryCount > policy.maxPayloadEntries) {
        _fail(
          'entryCountExceeded',
          r'$.content.files',
          'Payload entry count exceeds policy.',
        );
      }
      if (entry.size > policy.maxFileBytes) {
        _fail('entryTooLarge', entry.name, 'Payload entry exceeds policy.');
      }
      payloadTotal += entry.size;
      if (payloadTotal > policy.maxTotalPayloadBytes) {
        _fail(
          'archiveTooLarge',
          r'$.content.totalBytes',
          'Payload total exceeds policy.',
        );
      }
    }
    return payloadTotal;
  }

  ({
    int crc32,
    String sha256,
    Uint8List validationBytes,
  }) _streamEntry(
    RandomAccessPackageSource source,
    RandomAccessZipStructureEntry entry, {
    required bool bufferWholeEntry,
  }) {
    const chunkSize = 1024 * 1024;
    final mediaHeaderLimit = policy.maxMediaHeaderBytes;
    final digestSink = _SingleDigestSink();
    final hashInput = sha256.startChunkedConversion(digestSink);
    final validationBytes = BytesBuilder(copy: false);
    final secretScanner = GamePackageBinarySecretScanner(entry.name);
    final textInput = _isStreamValidatedText(entry.name)
        ? const Utf8Decoder(allowMalformed: false)
            .startChunkedConversion(_DiscardStringSink())
        : null;
    var crc32 = 0;
    var remaining = entry.size;
    var offset = entry.dataOffset;
    var buffered = 0;
    while (remaining > 0) {
      final length = remaining < chunkSize ? remaining : chunkSize;
      final chunk = _readAt(source, offset, length);
      secretScanner.add(chunk);
      if (textInput != null) {
        try {
          textInput.add(chunk);
        } on FormatException {
          _fail('executableContent', entry.name, 'Text data is not UTF-8.');
        }
      }
      hashInput.add(chunk);
      crc32 = getCrc32(chunk, crc32);
      if (bufferWholeEntry || buffered < mediaHeaderLimit) {
        final take = bufferWholeEntry
            ? chunk.length
            : (mediaHeaderLimit - buffered < chunk.length
                ? mediaHeaderLimit - buffered
                : chunk.length);
        validationBytes.add(chunk.sublist(0, take));
        buffered += take;
      }
      offset += length;
      remaining -= length;
    }
    if (textInput != null) {
      try {
        textInput.close();
      } on FormatException {
        _fail('executableContent', entry.name, 'Text data is not UTF-8.');
      }
    }
    hashInput.close();
    return (
      crc32: crc32,
      sha256: digestSink.value.toString(),
      validationBytes: validationBytes.takeBytes(),
    );
  }

  String _hashSource(RandomAccessPackageSource source, int fileLength) {
    const chunkSize = 1024 * 1024;
    final digestSink = _SingleDigestSink();
    final hashInput = sha256.startChunkedConversion(digestSink);
    var offset = 0;
    while (offset < fileLength) {
      final remaining = fileLength - offset;
      final length = remaining < chunkSize ? remaining : chunkSize;
      hashInput.add(_readAt(source, offset, length));
      offset += length;
    }
    hashInput.close();
    return digestSink.value.toString();
  }

  bool _requiresWholeContent(String path) {
    final extension = p.extension(path).toLowerCase();
    return extension == '.json';
  }

  bool _isStreamValidatedText(String path) {
    final extension = p.extension(path).toLowerCase();
    return extension == '.txt' || extension == '.md';
  }

  Uint8List _readAt(
    RandomAccessPackageSource source,
    int offset,
    int length,
  ) {
    final bytes = source.readAtSync(offset, length);
    if (bytes.length != length) {
      _fail('invalidZipStructure', r'$', 'Package changed during inspection.');
    }
    return bytes;
  }

  void _verifyCrc(ZipStructureEntry entry) {
    if (getCrc32(entry.data) != entry.crc32) {
      _fail('hashMismatch', entry.name, 'ZIP CRC does not match content.');
    }
  }

  Never _fail(String code, String path, String message) {
    throw GamePackageFormatException(
      code: code,
      path: path,
      message: message,
    );
  }
}

final class _SingleDigestSink implements Sink<Digest> {
  Digest? _digest;

  Digest get value => _digest ?? (throw StateError('Digest is not complete.'));

  @override
  void add(Digest data) {
    if (_digest != null) throw StateError('Digest was emitted twice.');
    _digest = data;
  }

  @override
  void close() {}
}

final class _DiscardStringSink implements Sink<String> {
  const _DiscardStringSink();

  @override
  void add(String data) {}

  @override
  void close() {}
}
