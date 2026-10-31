import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
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

final _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

const _parallelBatchEntries = 64;
const _parallelBatchBytes = 4 * 1024 * 1024;

typedef _ManifestHeader = ({
  int fileLength,
  List<RandomAccessZipStructureEntry> payloadEntries,
  int payloadTotal,
  Uint8List manifestBytes,
  GamePackageManifest manifest,
  PackageSignatureStatus signatureStatus,
  GamePackageCompatibilityResult? compatibility,
});

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
    RandomAccessPackageSource source, {
    String? knownPackageSha256,
  }) {
    _checkKnownPackageSha256(knownPackageSha256);
    final header = _inspectManifestSync(source);
    final payload = _matchPayloadInventory(header);
    final contentValidator = GamePackageContentValidator(policy);
    for (final inventoryEntry in header.manifest.content.files) {
      _inspectPayloadEntry(
        source,
        inventoryEntry,
        payload.rawByPath[inventoryEntry.path]!,
        contentValidator,
      );
    }
    final pokemonRuleset = _validateProject(source, header, payload);
    _checkUnchangedLength(
      source,
      header.fileLength,
      'Package changed while it was being inspected.',
    );
    final packageSha256 =
        knownPackageSha256 ?? _hashSource(source, header.fileLength);
    _checkUnchangedLength(
      source,
      header.fileLength,
      'Package changed while its receipt was being created.',
    );
    return _inspectionResult(header, packageSha256, pokemonRuleset);
  }

  Future<GamePackageInspectionResult> inspectSourceParallel(
    Future<RandomAccessPackageSource> Function() openSource, {
    int workers = 4,
    String? knownPackageSha256,
  }) async {
    _checkKnownPackageSha256(knownPackageSha256);
    final source = await openSource();
    _PackageHashWorker? hashWorker;
    try {
      final header = _inspectManifestSync(source);
      final payload = _matchPayloadInventory(header);
      if (knownPackageSha256 == null) {
        hashWorker = await _PackageHashWorker.spawn(
          policy,
          openSource,
          header.fileLength,
        );
      }
      await _inspectPayloadInParallel(
        openSource,
        header.manifest.content.files,
        payload.rawByPath,
        workers < 1 ? 1 : workers,
      );
      final pokemonRuleset = _validateProject(source, header, payload);
      _checkUnchangedLength(
        source,
        header.fileLength,
        'Package changed while it was being inspected.',
      );
      final packageSha256 = knownPackageSha256 ?? await hashWorker!.digest;
      _checkUnchangedLength(
        source,
        header.fileLength,
        'Package changed while its receipt was being created.',
      );
      return _inspectionResult(header, packageSha256, pokemonRuleset);
    } finally {
      hashWorker?.stop();
      await _closePackageSource(source);
    }
  }

  void _checkKnownPackageSha256(String? knownPackageSha256) {
    if (knownPackageSha256 != null &&
        !_sha256Hex.hasMatch(knownPackageSha256)) {
      throw ArgumentError.value(
        knownPackageSha256,
        'knownPackageSha256',
        'Expected a lowercase hexadecimal SHA-256 digest.',
      );
    }
  }

  ({
    Map<String, RandomAccessZipStructureEntry> rawByPath,
    Map<String, GamePackageFileEntry> inventoryByPath,
  }) _matchPayloadInventory(_ManifestHeader header) {
    final rawByPath = <String, RandomAccessZipStructureEntry>{
      for (final entry in header.payloadEntries) entry.name: entry,
    };
    final inventoryByPath = <String, GamePackageFileEntry>{
      for (final entry in header.manifest.content.files) entry.path: entry,
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
    return (rawByPath: rawByPath, inventoryByPath: inventoryByPath);
  }

  void _inspectPayloadEntry(
    RandomAccessPackageSource source,
    GamePackageFileEntry inventoryEntry,
    RandomAccessZipStructureEntry raw,
    GamePackageContentValidator contentValidator,
  ) {
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
  }

  Future<void> _inspectPayloadInParallel(
    Future<RandomAccessPackageSource> Function() openSource,
    List<GamePackageFileEntry> inventory,
    Map<String, RandomAccessZipStructureEntry> rawByPath,
    int workers,
  ) async {
    if (inventory.isEmpty) return;
    final events = ReceivePort();
    final isolates = <Isolate>[];
    final pendingByWorker = <SendPort, int>{};
    var nextIndex = 0;
    var completed = 0;
    _PayloadFailure? firstFailure;
    List<_PayloadTask>? nextBatch() {
      if (firstFailure != null || nextIndex >= inventory.length) return null;
      final batch = <_PayloadTask>[];
      var batchBytes = 0;
      while (nextIndex < inventory.length &&
          batch.length < _parallelBatchEntries &&
          batchBytes < _parallelBatchBytes) {
        final inventoryEntry = inventory[nextIndex];
        batch.add(_PayloadTask(
          nextIndex,
          inventoryEntry,
          rawByPath[inventoryEntry.path]!,
        ));
        batchBytes += inventoryEntry.size;
        nextIndex++;
      }
      return batch;
    }

    void recordFailure(_PayloadFailure failure) {
      final current = firstFailure;
      if (current == null || failure.index < current.index) {
        firstFailure = failure;
      }
    }

    try {
      final workerCount =
          workers < inventory.length ? workers : inventory.length;
      for (var worker = 0; worker < workerCount; worker++) {
        isolates.add(await Isolate.spawn(
          _inspectPayloadWorker,
          (events.sendPort, policy, openSource),
          onError: events.sendPort,
          onExit: events.sendPort,
        ));
      }
      var running = isolates.length;
      await for (final event in events) {
        if (event is SendPort) {
          completed += pendingByWorker.remove(event) ?? 0;
          final batch = nextBatch();
          if (batch != null) pendingByWorker[event] = batch.length;
          event.send(batch);
        } else if (event is _PayloadFailure) {
          recordFailure(event);
        } else if (event is List && event.length == 2) {
          recordFailure(_PayloadFailure(
            -1,
            RemoteError('${event[0]}', '${event[1]}'),
            '${event[1]}',
          ));
        } else if (event == null) {
          running--;
          if (running == 0) break;
        }
      }
    } finally {
      events.close();
      for (final isolate in isolates) {
        isolate.kill(priority: Isolate.immediate);
      }
    }
    final failure = firstFailure;
    if (failure != null) {
      Error.throwWithStackTrace(
        failure.error,
        StackTrace.fromString(failure.stackTrace),
      );
    }
    if (completed != inventory.length) {
      throw StateError('Parallel payload inspection did not complete.');
    }
  }

  PokemonRulesetReference _validateProject(
    RandomAccessPackageSource source,
    _ManifestHeader header,
    ({
      Map<String, RandomAccessZipStructureEntry> rawByPath,
      Map<String, GamePackageFileEntry> inventoryByPath,
    }) payload,
  ) {
    final rawByPath = payload.rawByPath;
    final inventoryByPath = payload.inventoryByPath;
    PokemonRulesetReference? pokemonRuleset;
    final projectEntry = rawByPath['project/project.json'];
    if (projectEntry != null) {
      List<int>? readVerifiedPayload(String path) {
        final raw = rawByPath[path];
        if (raw == null) return null;
        final bytes = _readAt(source, raw.dataOffset, raw.size);
        if (getCrc32(bytes) != raw.crc32 ||
            sha256.convert(bytes).toString() != inventoryByPath[path]!.sha256) {
          _fail('hashMismatch', path,
              'Payload changed during spatial validation.');
        }
        return bytes;
      }

      final project = GamePackageProjectValidator(policy).validate(
        header.manifest,
        Uint8List.fromList(readVerifiedPayload('project/project.json')!),
        payloadPaths: rawByPath.keys.toSet(),
        readPayload: readVerifiedPayload,
      );
      pokemonRuleset = project.pokemon.ruleset.reference;
    }
    if (pokemonRuleset == null) {
      _fail(
        'missingFile',
        'project/project.json',
        'The package must contain its project manifest.',
      );
    }
    return pokemonRuleset;
  }

  void _checkUnchangedLength(
    RandomAccessPackageSource source,
    int fileLength,
    String message,
  ) {
    if (source.length != fileLength) {
      _fail('invalidZipStructure', r'$', message);
    }
  }

  GamePackageInspectionResult _inspectionResult(
    _ManifestHeader header,
    String packageSha256,
    PokemonRulesetReference pokemonRuleset,
  ) {
    final manifest = header.manifest;
    final receipt = GamePackageInspectionReceipt(
      receiptVersion: 1,
      securityPolicyVersion: 1,
      gameId: manifest.gameId,
      gameVersion: manifest.gameVersion.toString(),
      treeSha256: manifest.content.treeSha256,
      manifestSha256: sha256.convert(header.manifestBytes).toString(),
      packageSha256: packageSha256,
      archiveBytes: header.fileLength,
      payloadBytes: header.payloadTotal,
      fileCount: header.payloadEntries.length,
      signatureStatus: header.signatureStatus,
      pokemonRuleset: pokemonRuleset,
    );
    return GamePackageInspectionResult(
      manifest: manifest,
      payloadPaths: manifest.content.files.map((entry) => entry.path).toList(),
      signatureStatus: header.signatureStatus,
      compatibility: header.compatibility,
      receipt: receipt,
    );
  }

  GamePackageManifestInspection inspectManifestSync(
    RandomAccessPackageSource source,
  ) {
    final header = _inspectManifestSync(source);
    return GamePackageManifestInspection(
      manifest: header.manifest,
      manifestSha256: sha256.convert(header.manifestBytes).toString(),
      signatureStatus: header.signatureStatus,
      compatibility: header.compatibility,
      archiveBytes: header.fileLength,
    );
  }

  _ManifestHeader _inspectManifestSync(RandomAccessPackageSource source) {
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
    if (!manifest.compatibility.requiredCapabilities
        .contains('catalog.partitioned@2')) {
      _fail('missingCatalogCapability', 'game-manifest.json',
          'Partitioned catalog capability is required.');
    }
    final signatureStatus = _verifySignature(manifest, codec);
    final compatibility = _evaluateCompatibility(manifest);
    return (
      fileLength: fileLength,
      payloadEntries: payloadEntries,
      payloadTotal: payloadTotal,
      manifestBytes: manifestBytes,
      manifest: manifest,
      signatureStatus: signatureStatus,
      compatibility: compatibility,
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
    if (!manifest.compatibility.requiredCapabilities
        .contains('catalog.partitioned@2')) {
      _fail('missingCatalogCapability', 'game-manifest.json',
          'Partitioned catalog capability is required.');
    }
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
    PokemonRulesetReference? pokemonRuleset;
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
    }
    final projectEntry = rawByPath['project/project.json'];
    if (projectEntry != null) {
      final project = GamePackageProjectValidator(policy).validate(
        manifest,
        projectEntry.data,
        payloadPaths: rawByPath.keys.toSet(),
        readPayload: (path) => rawByPath[path]?.data,
      );
      pokemonRuleset = project.pokemon.ruleset.reference;
    }
    if (pokemonRuleset == null) {
      _fail(
        'missingFile',
        'project/project.json',
        'The package must contain its project manifest.',
      );
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
      pokemonRuleset: pokemonRuleset,
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
      if (buffered == 0 &&
          p.extension(entry.name).toLowerCase() == '.blob' &&
          chunk.length >= 4 &&
          chunk[0] == 0x67 &&
          chunk[1] == 0x6c &&
          chunk[2] == 0x54 &&
          chunk[3] == 0x46) {
        bufferWholeEntry = true;
      }
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
    return extension == '.json' || extension == '.glb';
  }

  bool _isStreamValidatedText(String path) {
    final extension = p.extension(path).toLowerCase();
    return extension == '.txt' || extension == '.md' || extension == '.vtt';
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

Future<void> _closePackageSource(RandomAccessPackageSource source) async {
  if (source is ClosableRandomAccessPackageSource) await source.close();
}

final class _PayloadTask {
  const _PayloadTask(this.index, this.inventoryEntry, this.raw);

  final int index;
  final GamePackageFileEntry inventoryEntry;
  final RandomAccessZipStructureEntry raw;
}

final class _PayloadFailure {
  const _PayloadFailure(this.index, this.error, this.stackTrace);

  final int index;
  final Object error;
  final String stackTrace;
}

void _sendFailure(SendPort port, int index, Object error, StackTrace stack) {
  try {
    port.send(_PayloadFailure(index, error, '$stack'));
  } on Object {
    port.send(
        _PayloadFailure(index, RemoteError('$error', '$stack'), '$stack'));
  }
}

Future<void> _inspectPayloadWorker(
  (
    SendPort,
    GamePackageSecurityPolicy,
    Future<RandomAccessPackageSource> Function(),
  ) message,
) async {
  final (coordinator, policy, openSource) = message;
  final batches = ReceivePort();
  RandomAccessPackageSource? source;
  try {
    final openedSource = source = await openSource();
    final inspector = GamePackageInspector(policy: policy);
    final contentValidator = GamePackageContentValidator(policy);
    coordinator.send(batches.sendPort);
    await for (final batch in batches) {
      if (batch is! List<_PayloadTask>) break;
      for (final task in batch) {
        try {
          inspector._inspectPayloadEntry(
            openedSource,
            task.inventoryEntry,
            task.raw,
            contentValidator,
          );
        } on Object catch (error, stack) {
          _sendFailure(coordinator, task.index, error, stack);
          return;
        }
      }
      coordinator.send(batches.sendPort);
    }
  } on Object catch (error, stack) {
    _sendFailure(coordinator, -1, error, stack);
  } finally {
    batches.close();
    final openedSource = source;
    if (openedSource != null) await _closePackageSource(openedSource);
  }
}

final class _PackageHashWorker {
  _PackageHashWorker._(this._isolate, this._events, this._outcome);

  final Isolate _isolate;
  final ReceivePort _events;
  final Completer<Object?> _outcome;

  static Future<_PackageHashWorker> spawn(
    GamePackageSecurityPolicy policy,
    Future<RandomAccessPackageSource> Function() openSource,
    int fileLength,
  ) async {
    final events = ReceivePort();
    final outcome = Completer<Object?>();
    events.listen((event) {
      if (!outcome.isCompleted) outcome.complete(event);
      events.close();
    });
    try {
      final isolate = await Isolate.spawn(
        _hashPackageWorker,
        (events.sendPort, policy, openSource, fileLength),
        onError: events.sendPort,
        onExit: events.sendPort,
      );
      return _PackageHashWorker._(isolate, events, outcome);
    } on Object {
      events.close();
      rethrow;
    }
  }

  Future<String> get digest async {
    final outcome = await _outcome.future;
    if (outcome is String) return outcome;
    if (outcome is _PayloadFailure) {
      Error.throwWithStackTrace(
        outcome.error,
        StackTrace.fromString(outcome.stackTrace),
      );
    }
    if (outcome is List && outcome.length == 2) {
      throw RemoteError('${outcome[0]}', '${outcome[1]}');
    }
    throw StateError('Package hash worker exited without a digest.');
  }

  void stop() {
    _events.close();
    _isolate.kill(priority: Isolate.immediate);
  }
}

Future<void> _hashPackageWorker(
  (
    SendPort,
    GamePackageSecurityPolicy,
    Future<RandomAccessPackageSource> Function(),
    int,
  ) message,
) async {
  final (coordinator, policy, openSource, fileLength) = message;
  try {
    final source = await openSource();
    try {
      coordinator.send(
        GamePackageInspector(policy: policy)._hashSource(source, fileLength),
      );
    } finally {
      await _closePackageSource(source);
    }
  } on Object catch (error, stack) {
    _sendFailure(coordinator, -1, error, stack);
  }
}
