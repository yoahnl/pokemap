part of '../avelune_converter_core.dart';

final class SourceArchiveLimits {
  const SourceArchiveLimits({
    this.maxFiles = 4096,
    this.maxTotalBytes = 134217728,
    this.maxFileBytes = 67108864,
    this.maxReferences = 200000,
    this.maxEncodedCodeUnits = 180000000,
    this.maxTotalNodes = 4000000,
    this.maxTotalEntries = 4000000,
    this.maxTotalLocationCodeUnits = 67108864,
  });

  final int maxFiles;
  final int maxTotalBytes;
  final int maxFileBytes;
  final int maxReferences;
  final int maxEncodedCodeUnits;
  final int maxTotalNodes;
  final int maxTotalEntries;
  final int maxTotalLocationCodeUnits;

  void _validate() {
    final values = [
      (maxFiles, 65536),
      (maxTotalBytes, 268435456),
      (maxFileBytes, 67108864),
      (maxReferences, 1000000),
      (maxEncodedCodeUnits, 536870912),
      (maxTotalNodes, 8000000),
      (maxTotalEntries, 8000000),
      (maxTotalLocationCodeUnits, 134217728),
    ];
    if (values.any((value) => value.$1 <= 0 || value.$1 > value.$2)) {
      throw ContractError('source_archive.invalid_limits', r'$',
          'Archive limits must be positive and bounded.');
    }
  }
}

final class SourceArchivedFile {
  SourceArchivedFile._(this.entry, this.rawBytes, this.document);

  final SourceFileEntry entry;
  final List<int> rawBytes;
  final MarshalDocument document;
  ConverterId get fileId => entry.fileId;
  Sha256Hash get contentHash => entry.sha256!;
}

final class SourcePreservedData {
  SourcePreservedData._({
    required this.id,
    required this.fileId,
    required this.contentHash,
    required this.nodeId,
    required this.binaryLocation,
    this.locator,
  });

  final ConverterId id;
  final ConverterId fileId;
  final Sha256Hash contentHash;
  final int nodeId;
  final BinaryDecodeLocation binaryLocation;
  final SourceLocator? locator;
  String get status => 'preservedOnly';
  String get decoderPolicyVersion => 'marshal-4.8-v1';
  Map<String, Object?> toJson() => Map.unmodifiable({
        'id': id.value,
        'status': status,
        'decoderPolicyVersion': decoderPolicyVersion,
        'fileId': fileId.value,
        'contentHash': contentHash.value,
        'nodeId': nodeId,
        'binaryLocation': _archiveLocationJson(binaryLocation),
        'locator': locator?.toJson(),
      });
}

final class SourceArchive {
  SourceArchive({this.limits = const SourceArchiveLimits()}) {
    limits._validate();
    _encodedUnits = _archiveJsonUnits(_archiveEnvelope([], []));
  }

  factory SourceArchive.fromJson(Object? input,
      {SourceArchiveLimits limits = const SourceArchiveLimits()}) {
    final archive = SourceArchive(limits: limits);
    final root = _archiveMap(
        input,
        {
          'schemaVersion',
          'kind',
          'decoderPolicyVersion',
          'files',
          'references'
        },
        r'$');
    _archiveRequire(
        root['schemaVersion'] == '1.0' &&
            root['kind'] == 'sourceArchive' &&
            root['decoderPolicyVersion'] == _sourceArchiveDecoderPolicy,
        'shape',
        r'$',
        'Unexpected archive schema or decoder policy.');
    final files = _archiveList(root['files'], r'$.files');
    final references = _archiveList(root['references'], r'$.references');
    archive._quota(files.length, limits.maxFiles, 'files', r'$.files');
    archive._quota(
        references.length, limits.maxReferences, 'references', r'$.references');
    var encodedUnits = archive._encodedUnits;
    var totalBytes = 0;
    final pendingFiles = <(SourceFileEntry, String)>[];
    final fileIds = <ConverterId>{};
    final filePaths = <String>{};
    for (var index = 0; index < files.length; index++) {
      final path = r'$.files' '[$index]';
      final file =
          _archiveMap(files[index], {'entry', 'contentHash', 'rawBytes'}, path);
      final entry = _archiveEntry(file['entry'], '$path.entry');
      _archiveRequire(
          fileIds.add(entry.fileId) && filePaths.add(entry.relativePath),
          'duplicate_file',
          path,
          'Duplicate archived file.');
      archive._quota(entry.byteLength, limits.maxFileBytes, 'file_bytes', path);
      totalBytes += entry.byteLength;
      archive._quota(totalBytes, limits.maxTotalBytes, 'total_bytes', path);
      final hash = _archiveHash(file['contentHash'], '$path.contentHash');
      _archiveRequire(hash == entry.sha256, 'hash', path,
          'File hash differs from its inventory entry.');
      final encoded = _archiveString(
          file['rawBytes'], limits.maxEncodedCodeUnits, '$path.rawBytes',
          quota: 'encoded');
      encodedUnits += _archiveJsonUnits(_archiveFileJson(entry, encoded)) +
          (index == 0 ? 0 : 1);
      archive._quota(encodedUnits, limits.maxEncodedCodeUnits, 'encoded', path);
      _archiveRequire(encoded.length == 4 * ((entry.byteLength + 2) ~/ 3),
          'length', path, 'Encoded length differs from the declared bytes.');
      pendingFiles.add((entry, encoded));
    }
    final pendingReferences = <Map<String, Object?>>[];
    final referenceIds = <ConverterId>{};
    for (var index = 0; index < references.length; index++) {
      final path = r'$.references' '[$index]';
      final record = _archiveReferenceInput(references[index], path);
      final id = ConverterId(record['id'] as String);
      _archiveRequire(referenceIds.add(id), 'duplicate_reference', path,
          'Duplicate preserved reference.');
      encodedUnits += _archiveJsonUnits(record) + (index == 0 ? 0 : 1);
      archive._quota(encodedUnits, limits.maxEncodedCodeUnits, 'encoded', path);
      pendingReferences.add(record);
    }
    archive._quota(encodedUnits, limits.maxEncodedCodeUnits, 'encoded', r'$');
    for (final pending in pendingFiles) {
      archive._nextDecodeLimits(pending.$1.relativePath);
      final bytes = _archiveBase64(
          pending.$2, pending.$1.byteLength, pending.$1.relativePath);
      archive.add(pending.$1, bytes);
    }
    for (final record in pendingReferences) {
      final reference = archive.reference(
        fileId: ConverterId(record['fileId'] as String),
        nodeId: record['nodeId'] as int,
        locator: record['locator'] == null
            ? null
            : _archiveLocator(record['locator'], r'$.references.locator'),
      );
      _archiveRequire(
          canonicalJsonOf(reference.toJson(), limits: archive._jsonLimits) ==
              canonicalJsonOf(record, limits: archive._jsonLimits),
          'reference',
          r'$.references',
          'Preserved reference differs from its verified source node.');
    }
    archive.seal();
    return archive;
  }

  final SourceArchiveLimits limits;
  final Map<ConverterId, SourceArchivedFile> _files = {};
  final Map<ConverterId, SourcePreservedData> _references = {};
  final Map<(ConverterId, int, String), SourcePreservedData> _referenceIndex =
      {};
  final Set<String> _paths = {};
  int _totalBytes = 0;
  int _totalNodes = 0;
  int _totalEntries = 0;
  int _totalLocationUnits = 0;
  int _encodedUnits = 0;
  bool _sealed = false;
  Sha256Hash? _sealedCanonicalHash;
  bool get isSealed => _sealed;
  void seal() => _sealed = true;
  Map<ConverterId, SourceArchivedFile> get files => UnmodifiableMapView(_files);
  Map<ConverterId, SourcePreservedData> get references =>
      UnmodifiableMapView(_references);

  ContractLimits get _jsonLimits => ContractLimits(
        maxDepth: 16,
        maxNodes: 128,
        maxStringCodeUnits: limits.maxEncodedCodeUnits,
        maxTextCodeUnits: limits.maxEncodedCodeUnits,
      );

  Sha256Hash get canonicalHash => _sealed
      ? _sealedCanonicalHash ??= _computeCanonicalHash()
      : _computeCanonicalHash();

  Sha256Hash _computeCanonicalHash() {
    _quota(_encodedUnits, limits.maxEncodedCodeUnits, 'encoded', r'$');
    final digest = _SourceDigestSink();
    final sink = sha256.startChunkedConversion(digest);
    void text(String value) => sink.add(utf8.encode(value));
    text('{"decoderPolicyVersion":"$_sourceArchiveDecoderPolicy","files":[');
    final sortedFiles = _files.values.toList()
      ..sort((a, b) => a.fileId.value.compareTo(b.fileId.value));
    var first = true;
    for (final file in sortedFiles) {
      if (!first) text(',');
      first = false;
      text(canonicalJsonOf(_archiveFileJson(file.entry, null),
          limits: _jsonLimits));
    }
    text('],"kind":"sourceArchive","references":[');
    final sortedReferences = _references.values.toList()
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    first = true;
    for (final reference in sortedReferences) {
      if (!first) text(',');
      first = false;
      text(canonicalJsonOf(reference.toJson(), limits: _jsonLimits));
    }
    text('],"schemaVersion":"1.0"}');
    sink.close();
    return digest.hash;
  }

  SourceArchivedFile add(SourceFileEntry entry, List<int> bytes) {
    _mutable();
    final path = entry.relativePath;
    _archiveRequire(entry.kind == SourceNodeKind.file && entry.sha256 != null,
        'file_kind', path, 'Only hashed regular files can be archived.');
    _archiveRequire(bytes.length == entry.byteLength, 'length', path,
        'Source byte length differs from its inventory entry.');
    _quota(bytes.length, limits.maxFileBytes, 'file_bytes', path);
    final previous = _files[entry.fileId];
    if (previous == null) {
      _quota(_files.length + 1, limits.maxFiles, 'files', path);
      _quota(_totalBytes + bytes.length, limits.maxTotalBytes, 'total_bytes',
          path);
      _archiveRequire(!_paths.contains(path), 'duplicate_file', path,
          'An archived path cannot identify another file.');
    }
    final encodedUnits = _archiveJsonUnits(_archiveFileJson(entry, '')) +
        4 * ((bytes.length + 2) ~/ 3) +
        (_files.isEmpty ? 0 : 1);
    if (previous == null) {
      _quota(_encodedUnits + encodedUnits, limits.maxEncodedCodeUnits,
          'encoded', path);
    }
    final decodeLimits = previous == null ? _nextDecodeLimits(path) : null;
    final copy = Uint8List(bytes.length);
    for (var index = 0; index < copy.length; index++) {
      final byte = bytes[index];
      _archiveRequire(byte >= 0 && byte <= 255, 'bytes', path,
          'Original source must contain byte values.');
      copy[index] = byte;
    }
    _archiveRequire(Sha256Hash(sha256.convert(copy).toString()) == entry.sha256,
        'hash', path, 'Original source differs from its inventory hash.');
    if (previous != null) {
      _archiveRequire(
          canonicalJsonOf(previous.entry.toJson()) ==
              canonicalJsonOf(entry.toJson()),
          'duplicate_file',
          path,
          'An archived file ID cannot identify another entry.');
      return previous;
    }
    final raw = copy.asUnmodifiableView();
    final MarshalDocument document;
    try {
      document = const MarshalDecoder()
          .decode(raw, sourcePath: path, limits: decodeLimits!);
    } on BinaryDecodeError catch (error) {
      final quotas = {
        'marshal.quota.nodes': (
          'nodes',
          limits.maxTotalNodes - _totalNodes,
          2000000
        ),
        'marshal.quota.total_entries': (
          'entries',
          limits.maxTotalEntries - _totalEntries,
          2000000
        ),
        'marshal.quota.locations': (
          'locations',
          limits.maxTotalLocationCodeUnits - _totalLocationUnits,
          8388608
        ),
      };
      final quota = quotas[error.code];
      if (quota != null && quota.$2 <= quota.$3) {
        throw ContractError('source_archive.quota.${quota.$1}', path,
            'Aggregate graph quota exceeded at byte ${error.location.byteOffset}.');
      }
      rethrow;
    }
    final entries = document.nodes.fold<int>(
        0,
        (total, node) =>
            total +
            node.elements.length +
            node.pairs.length * 2 +
            node.instanceVariables.length * 2 +
            (node.defaultValue == null ? 0 : 1));
    final locationUnits = document.nodes
        .fold<int>(0, (total, node) => total + node.location.graphPath.length);
    final file = SourceArchivedFile._(entry, raw, document);
    _files[entry.fileId] = file;
    _paths.add(path);
    _totalBytes += bytes.length;
    _totalNodes += document.nodes.length;
    _totalEntries += entries;
    _totalLocationUnits += locationUnits;
    _encodedUnits += encodedUnits;
    return file;
  }

  SourcePreservedData reference({
    required ConverterId fileId,
    required int nodeId,
    SourceLocator? locator,
  }) {
    _mutable();
    final file = _files[fileId];
    _archiveRequire(file != null, 'reference_file', fileId.value,
        'A preserved reference requires an archived file.');
    final document = file!.document;
    _archiveRequire(
        nodeId >= 0 && nodeId < document.nodes.length,
        'reference_node',
        file.entry.relativePath,
        'The referenced node must belong to the archived document.');
    final validatedLocator = locator == null
        ? null
        : _archiveLocator(locator.toJson(), file.entry.relativePath);
    _archiveRequire(
        validatedLocator == null ||
            validatedLocator.file == file.entry.relativePath,
        'locator',
        file.entry.relativePath,
        'Semantic locator must identify the archived file.');
    final location = document.node(nodeId).location;
    final key = (fileId, nodeId, canonicalJsonOf(validatedLocator?.toJson()));
    final previous = _referenceIndex[key];
    if (previous != null) return previous;
    _quota(_references.length + 1, limits.maxReferences, 'references',
        file.entry.relativePath);
    final provisional = SourcePreservedData._(
        id: ConverterId('p1:${'0' * 64}'),
        fileId: fileId,
        contentHash: file.contentHash,
        nodeId: nodeId,
        binaryLocation: location,
        locator: validatedLocator);
    final encodedUnits =
        _archiveJsonUnits(provisional.toJson()) + (_references.isEmpty ? 0 : 1);
    _quota(_encodedUnits + encodedUnits, limits.maxEncodedCodeUnits, 'encoded',
        file.entry.relativePath);
    final id = ConverterId('p1:${canonicalHashOf({
          'fileId': fileId.value,
          'contentHash': file.contentHash.value,
          'nodeId': nodeId,
          'decoderPolicyVersion': _sourceArchiveDecoderPolicy,
          'binaryLocation': _archiveLocationJson(location),
          'locator': validatedLocator?.toJson(),
        }, limits: _jsonLimits).value}');
    final reference = SourcePreservedData._(
        id: id,
        fileId: fileId,
        contentHash: file.contentHash,
        nodeId: nodeId,
        binaryLocation: location,
        locator: validatedLocator);
    _references[id] = reference;
    _referenceIndex[key] = reference;
    _encodedUnits += encodedUnits;
    return reference;
  }

  Map<String, Object?> toJson() {
    _quota(_encodedUnits, limits.maxEncodedCodeUnits, 'encoded', r'$');
    final files = _files.values.toList()
      ..sort((a, b) => a.fileId.value.compareTo(b.fileId.value));
    final references = _references.values.toList()
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    return _archiveEnvelope([
      for (final file in files)
        _archiveFileJson(file.entry, base64Encode(file.rawBytes))
    ], [
      for (final reference in references) reference.toJson()
    ]);
  }

  void _mutable() => _archiveRequire(
      !_sealed, 'sealed', r'$', 'A sealed source archive cannot be changed.');

  MarshalDecodeLimits _nextDecodeLimits(String path) {
    _quota(_totalNodes + 1, limits.maxTotalNodes, 'nodes', path);
    _quota(_totalEntries + 1, limits.maxTotalEntries, 'entries', path);
    _quota(_totalLocationUnits + 1, limits.maxTotalLocationCodeUnits,
        'locations', path);
    int remaining(int maximum, int consumed, int perFile) {
      final left = maximum - consumed;
      return left < perFile ? left : perFile;
    }

    return MarshalDecodeLimits(
      maxNodes: remaining(limits.maxTotalNodes, _totalNodes, 2000000),
      maxTotalEntries:
          remaining(limits.maxTotalEntries, _totalEntries, 2000000),
      maxTotalLocationCodeUnits: remaining(
          limits.maxTotalLocationCodeUnits, _totalLocationUnits, 8388608),
    );
  }

  void _quota(int actual, int maximum, String family, String path) =>
      _archiveRequire(actual <= maximum, 'quota.$family', path,
          'Source archive $family quota exceeded.');
}

const _sourceArchiveDecoderPolicy = 'marshal-4.8-v1';

void _archiveRequire(bool condition, String code, String path, String message) {
  if (!condition) throw ContractError('source_archive.$code', path, message);
}

Map<String, Object?> _archiveEnvelope(List<Map<String, Object?>> files,
        List<Map<String, Object?>> references) =>
    Map.unmodifiable({
      'schemaVersion': '1.0',
      'kind': 'sourceArchive',
      'decoderPolicyVersion': _sourceArchiveDecoderPolicy,
      'files': List.unmodifiable(files),
      'references': List.unmodifiable(references),
    });

Map<String, Object?> _archiveFileJson(SourceFileEntry entry, String? raw) =>
    Map.unmodifiable({
      'entry': entry.toJson(),
      'contentHash': entry.sha256!.value,
      if (raw != null) 'rawBytes': raw,
    });

Map<String, Object?> _archiveLocationJson(BinaryDecodeLocation location) =>
    Map.unmodifiable({
      'sourcePath': location.sourcePath,
      'byteOffset': location.byteOffset,
      'graphPath': location.graphPath,
      'tag': location.tag,
    });

Map<String, Object?> _archiveMap(
    Object? input, Set<String> fields, String path) {
  _archiveRequire(
      input is Map &&
          input.length == fields.length &&
          input.keys.every((key) => key is String && fields.contains(key)),
      'shape',
      path,
      'Archive object has missing or unknown fields.');
  return Map<String, Object?>.from(input as Map);
}

List _archiveList(Object? input, String path) {
  _archiveRequire(input is List, 'shape', path, 'Expected an archive list.');
  return input as List;
}

String _archiveString(Object? input, int maximum, String path,
    {String? quota}) {
  _archiveRequire(
      input is String, 'shape', path, 'Expected an archive string.');
  final value = input as String;
  _archiveRequire(
      value.length <= maximum,
      quota == null ? 'shape' : 'quota.$quota',
      path,
      'Archive string exceeds its bound.');
  return value;
}

int _archiveInt(Object? input, int minimum, int maximum, String path) {
  _archiveRequire(input is int && input >= minimum && input <= maximum, 'shape',
      path, 'Expected a bounded archive integer.');
  return input as int;
}

Sha256Hash _archiveHash(Object? input, String path) {
  final value = _archiveString(input, 64, path);
  _archiveRequire(RegExp(r'^[a-f0-9]{64}$').hasMatch(value), 'hash', path,
      'Expected a source SHA-256 digest.');
  return Sha256Hash(value);
}

ConverterId _archiveId(Object? input, String path) =>
    ConverterId(_archiveString(input, 192, path));

SourceFileEntry _archiveEntry(Object? input, String path) {
  final json = _archiveMap(
      input,
      {
        'fileId',
        'relativePath',
        'kind',
        'byteLength',
        'sha256',
        'format',
        'family'
      },
      path);
  _archiveRequire(json['kind'] == 'file', 'file_kind', path,
      'Only hashed regular files can be archived.');
  return SourceFileEntry(
    fileId: _archiveId(json['fileId'], '$path.fileId'),
    relativePath:
        _archiveString(json['relativePath'], 4096, '$path.relativePath'),
    kind: SourceNodeKind.file,
    byteLength: _archiveInt(
        json['byteLength'], 0, 9007199254740991, '$path.byteLength'),
    sha256: _archiveHash(json['sha256'], '$path.sha256'),
    format: _archiveString(json['format'], 64, '$path.format'),
    family: _archiveString(json['family'], 64, '$path.family'),
  );
}

SourceLocator _archiveLocator(Object? input, String path) {
  final json = _archiveMap(
      input,
      {
        'file',
        'mapId',
        'eventId',
        'pageIndex',
        'commandIndex',
        'tileId',
        'line'
      },
      path);
  final file = _archiveString(json['file'], 2048, '$path.file');
  validateSourceRelativePath(file, maxCodeUnits: 2048);
  for (final field in [
    'mapId',
    'eventId',
    'pageIndex',
    'commandIndex',
    'tileId',
    'line'
  ]) {
    if (json[field] != null) {
      _archiveInt(
          json[field], field == 'line' ? 1 : 0, 2147483647, '$path.$field');
    }
  }
  return SourceLocator._(Map.unmodifiable(json));
}

Map<String, Object?> _archiveReferenceInput(Object? input, String path) {
  final json = _archiveMap(
      input,
      {
        'id',
        'status',
        'decoderPolicyVersion',
        'fileId',
        'contentHash',
        'nodeId',
        'binaryLocation',
        'locator'
      },
      path);
  _archiveId(json['id'], '$path.id');
  _archiveId(json['fileId'], '$path.fileId');
  _archiveHash(json['contentHash'], '$path.contentHash');
  _archiveInt(json['nodeId'], 0, 1999999, '$path.nodeId');
  _archiveRequire(
      json['status'] == 'preservedOnly' &&
          json['decoderPolicyVersion'] == _sourceArchiveDecoderPolicy,
      'reference',
      path,
      'Unexpected preserved reference policy.');
  final location = _archiveMap(json['binaryLocation'],
      {'sourcePath', 'byteOffset', 'graphPath', 'tag'}, '$path.binaryLocation');
  _archiveString(
      location['sourcePath'], 4096, '$path.binaryLocation.sourcePath');
  _archiveString(location['graphPath'], 8192, '$path.binaryLocation.graphPath');
  _archiveInt(
      location['byteOffset'], 0, 67108864, '$path.binaryLocation.byteOffset');
  if (location['tag'] != null) {
    _archiveInt(location['tag'], 0, 255, '$path.binaryLocation.tag');
  }
  json['binaryLocation'] = Map<String, Object?>.unmodifiable(location);
  if (json['locator'] != null) {
    json['locator'] =
        _archiveLocator(json['locator'], '$path.locator').toJson();
  }
  return json;
}

Uint8List _archiveBase64(String value, int expectedLength, String path) {
  _archiveRequire(value.length % 4 == 0, 'base64', path,
      'Original bytes require canonical padded base64.');
  var padding = 0;
  if (value.endsWith('=')) padding++;
  if (value.endsWith('==')) padding++;
  for (var index = 0; index < value.length - padding; index++) {
    final unit = value.codeUnitAt(index);
    _archiveRequire(
        (unit >= 65 && unit <= 90) ||
            (unit >= 97 && unit <= 122) ||
            (unit >= 48 && unit <= 57) ||
            unit == 43 ||
            unit == 47,
        'base64',
        path,
        'Original bytes require canonical base64.');
  }
  if (padding > 0) {
    final unit = value.codeUnitAt(value.length - padding - 1);
    final digit = unit >= 65 && unit <= 90
        ? unit - 65
        : unit >= 97 && unit <= 122
            ? unit - 71
            : unit >= 48 && unit <= 57
                ? unit + 4
                : unit == 43
                    ? 62
                    : 63;
    _archiveRequire((digit & (padding == 2 ? 15 : 3)) == 0, 'base64', path,
        'Original bytes require canonical base64 padding bits.');
  }
  _archiveRequire(value.length ~/ 4 * 3 - padding == expectedLength, 'length',
      path, 'Base64 decoded length differs from its inventory entry.');
  try {
    return base64Decode(value);
  } on FormatException catch (error) {
    if (error is ContractError) rethrow;
    throw ContractError(
        'source_archive.base64', path, 'Malformed base64 bytes.');
  }
}

int _archiveJsonUnits(Object? value) {
  if (value == null) return 4;
  if (value is bool) return value ? 4 : 5;
  if (value is int) return value.toString().length;
  if (value is String) {
    var length = 2;
    for (var index = 0; index < value.length; index++) {
      final unit = value.codeUnitAt(index);
      length += unit == 34 ||
              unit == 92 ||
              unit == 8 ||
              unit == 9 ||
              unit == 10 ||
              unit == 12 ||
              unit == 13
          ? 2
          : unit < 32 || (unit >= 0xd800 && unit <= 0xdfff)
              ? 6
              : 1;
    }
    return length;
  }
  if (value is List) {
    return 2 +
        (value.isEmpty ? 0 : value.length - 1) +
        value.fold<int>(0, (total, item) => total + _archiveJsonUnits(item));
  }
  final map = value as Map<String, Object?>;
  return 2 +
      (map.isEmpty ? 0 : map.length - 1) +
      map.entries.fold<int>(
          0,
          (total, entry) =>
              total +
              _archiveJsonUnits(entry.key) +
              1 +
              _archiveJsonUnits(entry.value));
}
