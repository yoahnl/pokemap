import 'dart:io';
import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';

import '../contracts/artifact_ref.dart';
import 'project_file_reader.dart';

const int maximumAuthoringArtifactBytesV1 = 256 * 1024 * 1024;

final class ArtifactStoreException implements Exception {
  const ArtifactStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ArtifactStoreException($code): $message';
}

final class StoredArtifact {
  const StoredArtifact({
    required this.reference,
    required this.deduplicated,
  });

  final ContentArtifactRef reference;
  final bool deduplicated;
}

/// Opaque byte staging boundary used before an asset mutation is planned.
abstract interface class ArtifactStore {
  Future<StoredArtifact> put(
    List<int> bytes, {
    String? declaredMediaType,
  });

  ContentArtifactRef? inspect(String handle);

  Future<List<int>> read(String handle);

  Future<bool> release(String handle);

  List<ContentArtifactRef> list();
}

/// Secure filesystem acquisition boundary exposed by local protocol adapters.
abstract interface class ArtifactFileStager {
  Future<StoredArtifact> importFile(
    String sourcePath, {
    String? declaredMediaType,
  });
}

/// Deterministic in-memory store suitable for direct API clients and tests.
///
/// Production protocol adapters may replace it with a durable store while
/// keeping the same path-free handles and validation behavior.
final class MemoryArtifactStore implements ArtifactStore {
  MemoryArtifactStore({required int maximumArtifactBytes})
      : maximumArtifactBytes =
            maximumArtifactBytes < maximumAuthoringArtifactBytesV1
                ? maximumArtifactBytes
                : maximumAuthoringArtifactBytesV1 {
    if (maximumArtifactBytes <= 0) {
      throw ArgumentError.value(
        maximumArtifactBytes,
        'maximumArtifactBytes',
        'must be positive',
      );
    }
  }

  final int maximumArtifactBytes;
  final Map<String, _ArtifactEntry> _entries = {};

  @override
  Future<StoredArtifact> put(
    List<int> bytes, {
    String? declaredMediaType,
  }) async {
    if (bytes.length > maximumArtifactBytes) {
      throw const ArtifactStoreException(
        'artifact.too_large',
        'The artifact exceeds the configured byte limit.',
      );
    }
    if (bytes.any((byte) => byte < 0 || byte > 255)) {
      throw const ArtifactStoreException(
        'artifact.bytes_invalid',
        'The artifact payload contains invalid bytes.',
      );
    }
    final mediaType = sniffArtifactMediaType(bytes);
    final declared = declaredMediaType?.trim().toLowerCase();
    if (declared != null &&
        declared.isNotEmpty &&
        mediaType != 'application/octet-stream' &&
        declared != mediaType) {
      throw const ArtifactStoreException(
        'artifact.mime_mismatch',
        'The declared media type conflicts with the inspected bytes.',
      );
    }
    final reference = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: mediaType == 'application/octet-stream' &&
              declared != null &&
              declared.isNotEmpty
          ? declared
          : mediaType,
    );
    final existing = _entries[reference.handle];
    if (existing != null) {
      existing.retainCount++;
      return StoredArtifact(reference: existing.reference, deduplicated: true);
    }
    _entries[reference.handle] = _ArtifactEntry(
      reference: reference,
      bytes: List<int>.unmodifiable(bytes),
    );
    return StoredArtifact(reference: reference, deduplicated: false);
  }

  @override
  ContentArtifactRef? inspect(String handle) => _entries[handle]?.reference;

  @override
  Future<List<int>> read(String handle) async {
    final entry = _entries[handle];
    if (entry == null) {
      throw const ArtifactStoreException(
        'artifact.unknown',
        'The artifact handle is unknown or has expired.',
      );
    }
    return List<int>.unmodifiable(entry.bytes);
  }

  @override
  Future<bool> release(String handle) async {
    final entry = _entries[handle];
    if (entry == null) return false;
    entry.retainCount--;
    if (entry.retainCount <= 0) _entries.remove(handle);
    return true;
  }

  @override
  List<ContentArtifactRef> list() => List.unmodifiable(
        _entries.values.map((entry) => entry.reference).toList()
          ..sort((left, right) => left.handle.compareTo(right.handle)),
      );
}

/// Filesystem acquisition adapter that rejects traversal and escaping links
/// before delegating bytes to the same content-addressed store.
final class LocalArtifactStore implements ArtifactStore, ArtifactFileStager {
  LocalArtifactStore({
    required Iterable<String> allowedSourceRoots,
    required int maximumArtifactBytes,
  })  : _allowedSourceRoots = List.unmodifiable(allowedSourceRoots),
        _memory = MemoryArtifactStore(
          maximumArtifactBytes: maximumArtifactBytes,
        ) {
    if (_allowedSourceRoots.isEmpty ||
        _allowedSourceRoots.any((root) => root.trim().isEmpty)) {
      throw ArgumentError.value(
        allowedSourceRoots,
        'allowedSourceRoots',
        'must contain at least one nonblank directory',
      );
    }
  }

  final List<String> _allowedSourceRoots;
  final MemoryArtifactStore _memory;
  final Map<String, ContentArtifactRef> _authorizedSourceArtifacts =
      <String, ContentArtifactRef>{};

  /// Grants one exact, user-selected file to this staging session.
  ///
  /// The resolved path is captured instead of its parent directory so a file
  /// picker does not silently broaden the staging capability to Downloads or
  /// another ambient folder. [importFile] resolves the path again, which also
  /// rejects a symlink that was retargeted after authorization.
  Future<void> authorizeSourceFile(String sourcePath) async {
    final source = File(sourcePath);
    late final String resolvedSource;
    try {
      resolvedSource = await source.resolveSymbolicLinks();
    } on FileSystemException {
      throw const ArtifactStoreException(
        'artifact.source_unavailable',
        'The artifact source is unavailable.',
      );
    }
    final metadata = await _statSource(resolvedSource);
    if (metadata.type != FileSystemEntityType.file) {
      throw const ArtifactStoreException(
        'artifact.source_not_regular',
        'The artifact source must be a regular file.',
      );
    }
    if (metadata.size > _memory.maximumArtifactBytes) {
      throw const ArtifactStoreException(
        'artifact.too_large',
        'The artifact exceeds the configured byte limit.',
      );
    }
    final bytes = await _readStableSource(sourcePath, resolvedSource);
    _authorizedSourceArtifacts[resolvedSource] = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: sniffArtifactMediaType(bytes),
    );
  }

  @override
  Future<StoredArtifact> importFile(
    String sourcePath, {
    String? declaredMediaType,
  }) async {
    final source = File(sourcePath);
    late final String resolvedSource;
    try {
      resolvedSource = await source.resolveSymbolicLinks();
    } on FileSystemException {
      throw const ArtifactStoreException(
        'artifact.source_unavailable',
        'The artifact source is unavailable.',
      );
    }
    final roots = <String>[];
    for (final root in _allowedSourceRoots) {
      try {
        roots.add(await Directory(root).resolveSymbolicLinks());
      } on FileSystemException {
        throw const ArtifactStoreException(
          'artifact.source_root_unavailable',
          'An allowed artifact source root is unavailable.',
        );
      }
    }
    final authorized = _authorizedSourceArtifacts[resolvedSource];
    if (authorized == null &&
        !roots.any(
          (root) =>
              workspacePathIsWithin(root: root, candidate: resolvedSource),
        )) {
      throw const ArtifactStoreException(
        'artifact.source_outside_allowed_roots',
        'The artifact source resolves outside the allowed roots.',
      );
    }
    final before = await _statSource(resolvedSource);
    if (before.type != FileSystemEntityType.file) {
      throw const ArtifactStoreException(
        'artifact.source_not_regular',
        'The artifact source must be a regular file.',
      );
    }
    if (before.size > _memory.maximumArtifactBytes) {
      throw const ArtifactStoreException(
        'artifact.too_large',
        'The artifact exceeds the configured byte limit.',
      );
    }
    final bytes = await _readStableSource(sourcePath, resolvedSource);
    final after = await _statSource(resolvedSource);
    if (before.modified != after.modified || before.size != after.size) {
      throw const ArtifactStoreException(
        'artifact.source_changed_during_read',
        'The artifact source changed while it was inspected.',
      );
    }
    if (authorized != null) {
      final actual = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: sniffArtifactMediaType(bytes),
      );
      if (actual.digest != authorized.digest ||
          actual.byteLength != authorized.byteLength) {
        throw const ArtifactStoreException(
          'artifact.source_changed_after_authorization',
          'The selected artifact changed after it was authorized.',
        );
      }
    }
    return _memory.put(bytes, declaredMediaType: declaredMediaType);
  }

  Future<Uint8List> _readStableSource(
    String sourcePath,
    String resolvedSource,
  ) async {
    RandomAccessFile? reader;
    try {
      reader = await File(resolvedSource).open();
      final bytes = BytesBuilder(copy: false);
      var total = 0;
      while (true) {
        final remaining = _memory.maximumArtifactBytes - total;
        final chunk = await reader.read(
          remaining < 1024 * 1024 ? remaining + 1 : 1024 * 1024,
        );
        if (chunk.isEmpty) break;
        total += chunk.length;
        if (total > _memory.maximumArtifactBytes) {
          throw const ArtifactStoreException(
            'artifact.too_large',
            'The artifact exceeds the configured byte limit.',
          );
        }
        bytes.add(chunk);
      }
      final resolvedAfterRead = await File(sourcePath).resolveSymbolicLinks();
      if (resolvedAfterRead != resolvedSource) {
        throw const ArtifactStoreException(
          'artifact.source_changed_during_read',
          'The artifact source changed while it was inspected.',
        );
      }
      final captured = bytes.takeBytes();
      await reader.setPosition(0);
      var offset = 0;
      while (offset < captured.length) {
        final remaining = captured.length - offset;
        final chunk = await reader.read(
          remaining < 1024 * 1024 ? remaining : 1024 * 1024,
        );
        if (chunk.isEmpty || !_sameByteRange(captured, offset, chunk)) {
          throw const ArtifactStoreException(
            'artifact.source_changed_during_read',
            'The artifact source changed while it was inspected.',
          );
        }
        offset += chunk.length;
      }
      if ((await reader.read(1)).isNotEmpty) {
        throw const ArtifactStoreException(
          'artifact.source_changed_during_read',
          'The artifact source changed while it was inspected.',
        );
      }
      return captured;
    } on ArtifactStoreException {
      rethrow;
    } on FileSystemException {
      throw const ArtifactStoreException(
        'artifact.source_unavailable',
        'The artifact source is unavailable.',
      );
    } finally {
      await _closeArtifactSource(reader);
    }
  }

  Future<FileStat> _statSource(String resolvedSource) async {
    try {
      return await File(resolvedSource).stat();
    } on FileSystemException {
      throw const ArtifactStoreException(
        'artifact.source_unavailable',
        'The artifact source is unavailable.',
      );
    }
  }

  @override
  Future<StoredArtifact> put(
    List<int> bytes, {
    String? declaredMediaType,
  }) =>
      _memory.put(bytes, declaredMediaType: declaredMediaType);

  @override
  ContentArtifactRef? inspect(String handle) => _memory.inspect(handle);

  @override
  Future<List<int>> read(String handle) => _memory.read(handle);

  @override
  Future<bool> release(String handle) => _memory.release(handle);

  @override
  List<ContentArtifactRef> list() => _memory.list();
}

Future<void> _closeArtifactSource(RandomAccessFile? reader) async {
  if (reader == null) return;
  try {
    await reader.close();
  } on FileSystemException {
    return;
  }
}

bool _sameByteRange(List<int> expected, int offset, List<int> actual) {
  if (offset + actual.length > expected.length) return false;
  for (var index = 0; index < actual.length; index++) {
    if (expected[offset + index] != actual[index]) return false;
  }
  return true;
}

String sniffArtifactMediaType(List<int> bytes) {
  if (_startsWith(
      bytes, const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return 'image/png';
  }
  if (_startsWith(bytes, const [0xff, 0xd8, 0xff])) return 'image/jpeg';
  if (_startsWith(bytes, const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
      bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  if (bytes.length >= 8 &&
      String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
    try {
      return const PresentationMediaHeaderProbe()
          .inspect(bytes, declaredMediaType: 'video/mp4')
          .mediaType;
    } on PresentationMediaProbeException {
      return detectAudioMediaFormat(bytes)?.mediaType ??
          'application/octet-stream';
    }
  }
  final audioFormat = detectAudioMediaFormat(bytes);
  if (audioFormat != null) return audioFormat.mediaType;
  if (_startsWith(bytes, const [0x00, 0x01, 0x00, 0x00]) ||
      _startsWith(bytes, const [0x4f, 0x54, 0x54, 0x4f])) {
    return 'font/ttf';
  }
  if (bytes.isNotEmpty && bytes.every(_isTextByte)) return 'text/plain';
  return 'application/octet-stream';
}

bool _startsWith(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}

bool _isTextByte(int byte) =>
    byte == 0x09 ||
    byte == 0x0a ||
    byte == 0x0d ||
    (byte >= 0x20 && byte <= 0x7e);

final class _ArtifactEntry {
  _ArtifactEntry({required this.reference, required this.bytes});

  final ContentArtifactRef reference;
  final List<int> bytes;
  int retainCount = 1;
}
