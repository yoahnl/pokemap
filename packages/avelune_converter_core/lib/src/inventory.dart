part of '../avelune_converter_core.dart';

enum SourceNodeKind { file, directory, link, special }

enum SourceScanState { complete, partial, failed, cancelled }

enum SourceProfileState { unknown, observed, requiresConfirmation, confirmed }

final class SourceScanLimits {
  const SourceScanLimits({
    this.maxEntries = 100000,
    this.maxDepth = 32,
    this.maxFileBytes = 536870912,
    this.maxTotalBytes = 8589934592,
    this.maxPathCodeUnits = 4096,
    this.maxProbeBytes = 65536,
    this.maxDiagnostics = 1000,
    this.maxProfileEvidence = 128,
    this.maxTotalPathCodeUnits = 8388608,
  });
  final int maxEntries;
  final int maxDepth;
  final int maxFileBytes;
  final int maxTotalBytes;
  final int maxPathCodeUnits;
  final int maxProbeBytes;
  final int maxDiagnostics;
  final int maxProfileEvidence;
  final int maxTotalPathCodeUnits;

  Map<String, Object?> toJson() => Map.unmodifiable({
        'maxEntries': maxEntries,
        'maxDepth': maxDepth,
        'maxFileBytes': maxFileBytes,
        'maxTotalBytes': maxTotalBytes,
        'maxPathCodeUnits': maxPathCodeUnits,
        'maxProbeBytes': maxProbeBytes,
        'maxDiagnostics': maxDiagnostics,
        'maxProfileEvidence': maxProfileEvidence,
        'maxTotalPathCodeUnits': maxTotalPathCodeUnits,
      });

  void _validate() {
    final ceilings = {
      'maxEntries': 1000000,
      'maxDepth': 128,
      'maxFileBytes': 9007199254740991,
      'maxTotalBytes': 9007199254740991,
      'maxPathCodeUnits': 4096,
      'maxProbeBytes': 1048576,
      'maxDiagnostics': 10000,
      'maxProfileEvidence': 1024,
      'maxTotalPathCodeUnits': 67108864,
    };
    for (final entry in toJson().entries) {
      final value = entry.value as int;
      _require(value > 0 && value <= ceilings[entry.key]!,
          'source.policy_limit', entry.key, 'Invalid scan quota');
    }
  }
}

final class SourceScanPolicy {
  SourceScanPolicy({
    this.limits = const SourceScanLimits(),
    List<String> excludedSegments = const [
      '.git',
      '.env',
      '.DS_Store',
      'credentials.json',
      'secrets.json',
      '.dart_tool',
      'node_modules',
      'build',
      'cache',
      'logs',
      'saves',
    ],
  }) : excludedSegments = List.unmodifiable(excludedSegments) {
    limits._validate();
    _require(excludedSegments.length <= 1024, 'source.policy_exclusions', r'$',
        'Too many excluded segments');
    for (final segment in excludedSegments) {
      validateSourceRelativePath(segment);
      _require(!segment.contains('/'), 'source.policy_exclusions', segment,
          'Exclusion must name one path segment');
    }
    _excludedKeys =
        Set.unmodifiable(excludedSegments.map(sourcePathCollisionKey));
  }
  final SourceScanLimits limits;
  final List<String> excludedSegments;
  late final Set<String> _excludedKeys;
  bool isExcluded(String path) => path.split('/').any((segment) {
        final key = sourcePathCollisionKey(segment);
        return _excludedKeys.contains(key) ||
            (_excludedKeys.contains('.env') && key.startsWith('.env.'));
      });
  Sha256Hash get canonicalHash => canonicalHashOf({
        'rulesVersion': 1,
        'pathRulesVersion': 1,
        'formatRulesVersion': 1,
        'profileRulesVersion': 1,
        'caseFoldingVersion': 'Unicode-17.0',
        'limits': limits.toJson(),
        'excludedSegments': _excludedKeys.toList()..sort(),
      });
}

final class ScanCancellation {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void check() {
    if (_cancelled) {
      throw ContractError('source.cancelled', r'$', 'Scan cancelled');
    }
  }
}

final class SourceNode {
  const SourceNode({
    required this.relativePath,
    required this.kind,
    required this.byteLength,
    required this.token,
  });
  final String relativePath;
  final SourceNodeKind kind;
  final int byteLength;
  final String token;
}

abstract interface class SourceTreePort {
  Stream<SourceNode> walk({
    required SourceScanPolicy policy,
    required ScanCancellation cancellation,
  });
  Stream<List<int>> read(
    SourceNode node, {
    required int maxBytes,
    required ScanCancellation cancellation,
  });
}

final class SourceScanDiagnostic {
  SourceScanDiagnostic({
    required this.code,
    required this.relativePath,
    required this.message,
    required this.blocksExtraction,
    List<String> relatedPaths = const [],
  }) : relatedPaths = List.unmodifiable(relatedPaths.toList()..sort()) {
    _require(
        code.isNotEmpty &&
            code.length <= 128 &&
            message.isNotEmpty &&
            message.length <= 1024 &&
            relativePath.length <= 4096 &&
            relatedPaths.length <= 1000000,
        'source.diagnostic',
        r'$',
        'Invalid bounded diagnostic');
  }
  final String code;
  final String relativePath;
  final String message;
  final bool blocksExtraction;
  final List<String> relatedPaths;
}

final class SourceFileEntry {
  SourceFileEntry({
    required this.fileId,
    required this.relativePath,
    required this.kind,
    required this.byteLength,
    required this.sha256,
    required this.format,
    required this.family,
  }) {
    validateSourceRelativePath(relativePath);
    _require(byteLength >= 0 && byteLength <= 9007199254740991,
        'source.entry_size', relativePath, 'Invalid source entry size');
    _require(
        kind == SourceNodeKind.file || (byteLength == 0 && sha256 == null),
        'source.entry_kind',
        relativePath,
        'Only regular files have byte hashes');
    _require(
        RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(format) &&
            RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(family),
        'source.entry_classification',
        relativePath,
        'Invalid classification');
  }
  final ConverterId fileId;
  final String relativePath;
  final SourceNodeKind kind;
  final int byteLength;
  final Sha256Hash? sha256;
  final String format;
  final String family;
  Map<String, Object?> _contentJson() => Map.unmodifiable({
        'relativePath': relativePath,
        'kind': kind.name,
        'byteLength': byteLength,
        'sha256': sha256?.value,
        'format': format,
        'family': family,
      });
  Map<String, Object?> toJson() =>
      Map.unmodifiable({..._contentJson(), 'fileId': fileId.value});
}

final class SourceProfileEvidence {
  const SourceProfileEvidence({
    required this.relativePath,
    required this.fileHash,
    required this.version,
    required this.line,
    required this.excerpt,
  });
  final String relativePath;
  final Sha256Hash fileHash;
  final String version;
  final int line;
  final String excerpt;
  void _validate() {
    validateSourceRelativePath(relativePath);
    _require(
        _essentialsVersion.hasMatch(version) &&
            line > 0 &&
            line <= 2147483647 &&
            excerpt.isNotEmpty &&
            excerpt.length <= 240,
        'source.profile_evidence',
        relativePath,
        'Invalid Essentials evidence');
  }

  Map<String, Object?> toJson() => Map.unmodifiable({
        'relativePath': relativePath,
        'fileHash': fileHash.value,
        'version': version,
        'line': line,
        'excerpt': excerpt,
      });
}

final class ConfirmedProfileOverride {
  const ConfirmedProfileOverride({
    required this.version,
    required this.sourceSnapshotHash,
    required this.evidenceHash,
    required this.humanConfirmed,
    required this.reason,
  });
  final String version;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash evidenceHash;
  final bool humanConfirmed;
  final String reason;
}

final _essentialsVersion = RegExp(r'^[0-9]{1,3}(?:\.[0-9]{1,3}){0,2}$');

int _compareProfileEvidence(SourceProfileEvidence a, SourceProfileEvidence b) {
  final path = a.relativePath.compareTo(b.relativePath);
  if (path != 0) return path;
  final line = a.line.compareTo(b.line);
  if (line != 0) return line;
  final version = a.version.compareTo(b.version);
  return version != 0 ? version : a.excerpt.compareTo(b.excerpt);
}

final class SourceProfile {
  SourceProfile({
    required Sha256Hash sourceSnapshotHash,
    required List<SourceProfileEvidence> evidence,
  }) : this._(sourceSnapshotHash, evidence, null, null);
  SourceProfile._(this.sourceSnapshotHash, List<SourceProfileEvidence> evidence,
      this._confirmedVersion, this.confirmationReason,
      [this._confirmationAllowed = true])
      : evidence = List.unmodifiable(
            evidence.toList()..sort(_compareProfileEvidence)) {
    _require(evidence.length <= 1024, 'source.profile_quota', r'$',
        'Too much profile evidence');
    for (final item in evidence) {
      item._validate();
    }
  }
  final Sha256Hash sourceSnapshotHash;
  final List<SourceProfileEvidence> evidence;
  final String? _confirmedVersion;
  final String? confirmationReason;
  final bool _confirmationAllowed;
  SourceProfileState get state {
    if (_confirmedVersion != null) return SourceProfileState.confirmed;
    final versions = evidence.map((item) => item.version).toSet();
    if (versions.isEmpty) return SourceProfileState.unknown;
    return versions.length == 1
        ? SourceProfileState.observed
        : SourceProfileState.requiresConfirmation;
  }

  String? get version =>
      _confirmedVersion ??
      (state == SourceProfileState.observed ? evidence.first.version : null);
  Sha256Hash get evidenceHash => canonicalHashOf({
        'family': 'pokemon-essentials',
        'rulesVersion': 1,
        'evidence': evidence.map((item) => item.toJson()).toList(),
      });
  SourceProfile confirm(ConfirmedProfileOverride override) {
    _require(_confirmationAllowed, 'source.incomplete_profile', r'$',
        'Incomplete inventories cannot confirm a source profile');
    _require(
        override.humanConfirmed &&
            override.reason.trim().isNotEmpty &&
            override.reason.length <= 1024 &&
            _essentialsVersion.hasMatch(override.version),
        'source.profile_confirmation',
        r'$',
        'Explicit profile confirmation required');
    _require(
        override.sourceSnapshotHash == sourceSnapshotHash &&
            override.evidenceHash == evidenceHash,
        'source.stale_profile',
        r'$',
        'Profile confirmation belongs to another source or evidence set');
    return SourceProfile._(
        sourceSnapshotHash, evidence, override.version, override.reason.trim());
  }
}

final class SourceSnapshot {
  SourceSnapshot({
    required this.logicalProjectNamespace,
    required this.policyHash,
    required List<SourceFileEntry> entries,
    required List<SourceScanDiagnostic> diagnostics,
    required List<String> excludedPaths,
    required List<SourceProfileEvidence> profileEvidence,
    required this.state,
  })  : entries = List.unmodifiable(entries.toList()
          ..sort((a, b) => a.relativePath.compareTo(b.relativePath))),
        diagnostics = List.unmodifiable(diagnostics.toList()
          ..sort((a, b) {
            final path = a.relativePath.compareTo(b.relativePath);
            return path == 0 ? a.code.compareTo(b.code) : path;
          })),
        excludedPaths =
            List.unmodifiable(excludedPaths.toSet().toList()..sort()),
        profileEvidence = List.unmodifiable(
            profileEvidence.toList()..sort(_compareProfileEvidence)) {
    _require(
        entries.length <= 1000000 &&
            diagnostics.length <= 10000 &&
            excludedPaths.length <= 1000000 &&
            profileEvidence.length <= 1024,
        'source.snapshot_quota',
        r'$',
        'Snapshot collection quota exceeded');
    final byPath = <String, SourceFileEntry>{};
    final ids = <ConverterId>{};
    final prefixOrigins = <String, String>{};
    for (final entry in entries) {
      _require(
          !byPath.containsKey(entry.relativePath) && ids.add(entry.fileId),
          'source.snapshot_duplicate',
          entry.relativePath,
          'Duplicate source entry');
      byPath[entry.relativePath] = entry;
      if (state == SourceScanState.complete) {
        for (final prefix in _sourcePathPrefixes(entry.relativePath)) {
          final key = sourcePathCollisionKey(prefix);
          final previous = prefixOrigins[key];
          _require(
              previous == null || previous == prefix,
              'source.snapshot_collision',
              entry.relativePath,
              'Complete inventory cannot contain ambiguous path prefixes');
          prefixOrigins[key] = prefix;
        }
        _require(
            entry.kind == SourceNodeKind.directory ||
                (entry.kind == SourceNodeKind.file && entry.sha256 != null),
            'source.snapshot_incomplete',
            entry.relativePath,
            'Complete inventory requires hashed regular files');
      }
    }
    for (final path in excludedPaths) {
      validateSourceRelativePath(path);
      _require(!byPath.containsKey(path), 'source.snapshot_exclusion', path,
          'Excluded path must not also be inventoried');
    }
    for (final item in profileEvidence) {
      item._validate();
      _require(
          byPath[item.relativePath]?.sha256 == item.fileHash,
          'source.snapshot_evidence',
          item.relativePath,
          'Evidence must belong to the hashed inventory');
    }
    _require(
        state != SourceScanState.complete ||
            !diagnostics.any((item) => item.blocksExtraction),
        'source.snapshot_blocked',
        r'$',
        'Blocked inventory cannot be complete');
  }
  final ConverterId logicalProjectNamespace;
  final Sha256Hash policyHash;
  final List<SourceFileEntry> entries;
  final List<SourceScanDiagnostic> diagnostics;
  final List<String> excludedPaths;
  final List<SourceProfileEvidence> profileEvidence;
  final SourceScanState state;
  late final Sha256Hash canonicalHash = _hashManifest();
  SourceProfile get profile => SourceProfile._(canonicalHash, profileEvidence,
      null, null, state == SourceScanState.complete);
  Sha256Hash _hashManifest() {
    final digest = _SourceDigestSink();
    final sink = sha256.startChunkedConversion(digest);
    void add(String value) => sink.add(utf8.encode(value));
    add('{"diagnostics":[');
    var first = true;
    for (final diagnostic in diagnostics) {
      if (!first) add(',');
      first = false;
      add('{"blocksExtraction":${diagnostic.blocksExtraction},"code":${jsonEncode(diagnostic.code)},"relatedPaths":[');
      var firstRelated = true;
      for (final path in diagnostic.relatedPaths) {
        if (!firstRelated) add(',');
        firstRelated = false;
        add(jsonEncode(path));
      }
      add('],"relativePath":${jsonEncode(diagnostic.relativePath)}}');
    }
    add('],"entries":[');
    first = true;
    for (final entry in entries) {
      if (!first) add(',');
      first = false;
      add(canonicalJsonOf(entry._contentJson()));
    }
    add('],"excludedPaths":[');
    first = true;
    for (final path in excludedPaths) {
      if (!first) add(',');
      first = false;
      add(jsonEncode(path));
    }
    add('],"policyHash":${jsonEncode(policyHash.value)},"rulesVersion":1,"state":${jsonEncode(state.name)}}');
    sink.close();
    return digest.hash;
  }

  Map<String, Object?> toJson() => Map.unmodifiable({
        'rulesVersion': 1,
        'logicalProjectNamespace': logicalProjectNamespace.value,
        'policyHash': policyHash.value,
        'canonicalHash': canonicalHash.value,
        'state': state.name,
        'entries': List.unmodifiable(entries.map((item) => item.toJson())),
        'excludedPaths': excludedPaths,
        'profileEvidence':
            List.unmodifiable(profileEvidence.map((item) => item.toJson())),
        'diagnostics':
            List.unmodifiable(diagnostics.map((item) => Map.unmodifiable({
                  'code': item.code,
                  'relativePath': item.relativePath,
                  'message': item.message,
                  'blocksExtraction': item.blocksExtraction,
                  'relatedPaths': item.relatedPaths,
                }))),
      });
}

final class _SourceDigestSink implements Sink<Digest> {
  Digest? _digest;
  Sha256Hash get hash => Sha256Hash(_digest!.toString());
  @override
  void add(Digest data) => _digest = data;
  @override
  void close() {}
}

String sourcePathCollisionKey(String path) {
  for (var index = 0; index < path.length; index++) {
    if (path.codeUnitAt(index) >= 0x80) {
      return unorm.nfc(_SourceUnicodeCaseFolding.fold(unorm.nfc(path)));
    }
  }
  return path.toLowerCase();
}

void validateSourceRelativePath(String path, {int maxCodeUnits = 4096}) {
  _require(
      maxCodeUnits > 0 &&
          path.isNotEmpty &&
          path.length <= maxCodeUnits &&
          !path.contains('\\') &&
          !path.contains(':') &&
          !RegExp(r'[\x00-\x1f\x7f]').hasMatch(path),
      'source.path',
      path,
      'Invalid relative source path');
  for (final segment in path.split('/')) {
    _require(segment.isNotEmpty && segment != '.' && segment != '..',
        'source.path', path, 'Path must contain only safe relative segments');
  }
  for (var index = 0; index < path.length; index++) {
    final unit = path.codeUnitAt(index);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      _require(
          index + 1 < path.length &&
              path.codeUnitAt(index + 1) >= 0xdc00 &&
              path.codeUnitAt(index + 1) <= 0xdfff,
          'source.path_unicode',
          path,
          'Unpaired Unicode surrogate');
      index++;
    } else {
      _require(unit < 0xdc00 || unit > 0xdfff, 'source.path_unicode', path,
          'Unpaired Unicode surrogate');
    }
  }
}

String _sourceFormat(String path) {
  final name = sourcePathCollisionKey(path.split('/').last);
  final dot = name.lastIndexOf('.');
  final extension = dot < 0 ? '' : name.substring(dot + 1);
  return switch (extension) {
    'rxdata' => 'ruby-marshal',
    'rb' => 'ruby-text',
    'png' || 'jpg' || 'jpeg' || 'bmp' || 'gif' => 'raster',
    'ogg' || 'wav' || 'mp3' || 'mid' || 'midi' => 'audio',
    'txt' || 'md' || 'ini' || 'json' || 'yaml' || 'yml' => 'text',
    _ => 'unknown',
  };
}

String _sourceFamily(String path) =>
    switch (sourcePathCollisionKey(path.split('/').first)) {
      'data' => 'data',
      'pbs' => 'catalog',
      'graphics' => 'graphics',
      'audio' => 'audio',
      'plugins' || 'scripts' => 'scripts',
      _ => 'project',
    };

Iterable<SourceProfileEvidence> _observeEssentials(
  String path,
  Sha256Hash hash,
  List<int> prefix,
) sync* {
  final format = _sourceFormat(path);
  if (format != 'text' && format != 'ruby-text') return;
  final patterns = [
    RegExp(
        r'(?i:Pok[ée]mon\s+Essentials|Essentials)\s+(?:version\s+|v)?([0-9]{1,3}(?:\.[0-9]{1,3}){0,2})(?![0-9.])'),
    RegExp(
        r'''ESSENTIALS_VERSION\s*=\s*["']([0-9]{1,3}(?:\.[0-9]{1,3}){0,2})["']'''),
    RegExp(
        r'''Essentials::VERSION\s*=\s*["']([0-9]{1,3}(?:\.[0-9]{1,3}){0,2})["']'''),
  ];
  final lines = utf8.decode(prefix, allowMalformed: true).split('\n');
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final seen = <String>{};
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(line)) {
        final version = match.group(1)!;
        if (!seen.add(version)) continue;
        final at = line.indexOf(version);
        final start = at > 80 ? at - 80 : 0;
        final end = start + 240 < line.length ? start + 240 : line.length;
        yield SourceProfileEvidence(
            relativePath: path,
            fileHash: hash,
            version: version,
            line: index + 1,
            excerpt: line.substring(start, end));
      }
    }
  }
}

Iterable<String> _sourcePathPrefixes(String path) sync* {
  var prefix = '';
  for (final segment in path.split('/')) {
    prefix = prefix.isEmpty ? segment : '$prefix/$segment';
    yield prefix;
  }
}

final class SourceScanner {
  Future<SourceSnapshot> scan({
    required SourceTreePort source,
    required ConverterId logicalProjectNamespace,
    SourceScanPolicy? policy,
    ScanCancellation? cancellation,
    void Function(JobProgress progress)? onProgress,
  }) async {
    final effective = policy ?? SourceScanPolicy();
    final cancel = cancellation ?? ScanCancellation();
    final limits = effective.limits;
    final entries = <SourceFileEntry>[];
    final diagnostics = <SourceScanDiagnostic>[];
    final excluded = <String>{};
    final evidence = <SourceProfileEvidence>[];
    var state = SourceScanState.complete;
    void diagnose(
      String code,
      String path,
      String message, {
      bool blocks = true,
      List<String> related = const [],
    }) {
      if (blocks && state == SourceScanState.complete) {
        state = SourceScanState.partial;
      }
      if (diagnostics.length < limits.maxDiagnostics) {
        diagnostics.add(SourceScanDiagnostic(
            code: code,
            relativePath: path.length <= 4096 ? path : path.substring(0, 4096),
            message: message,
            blocksExtraction: blocks,
            relatedPaths: related));
      } else {
        diagnostics[diagnostics.length - 1] = SourceScanDiagnostic(
            code: 'source.diagnostic_limit',
            relativePath: r'$',
            message: 'Diagnostic quota exceeded',
            blocksExtraction: true);
        state = SourceScanState.partial;
      }
    }

    SourceSnapshot snapshot() => SourceSnapshot(
        logicalProjectNamespace: logicalProjectNamespace,
        policyHash: effective.canonicalHash,
        entries: entries,
        diagnostics: diagnostics,
        excludedPaths: excluded.toList(),
        profileEvidence: evidence,
        state: state);

    Future<Map<String, SourceNode>> enumerate({required bool initial}) async {
      final result = <String, SourceNode>{};
      var count = 0;
      var pathUnits = 0;
      var declaredBytes = 0;
      await for (final node
          in source.walk(policy: effective, cancellation: cancel)) {
        cancel.check();
        if (++count > limits.maxEntries) {
          throw ContractError('source.entry_limit', node.relativePath,
              'Source entry quota exceeded');
        }
        pathUnits += node.relativePath.length;
        if (pathUnits > limits.maxTotalPathCodeUnits) {
          throw ContractError('source.path_total_limit', node.relativePath,
              'Cumulative path quota exceeded');
        }
        try {
          validateSourceRelativePath(node.relativePath,
              maxCodeUnits: limits.maxPathCodeUnits);
          _require(
              node.relativePath.split('/').length <= limits.maxDepth,
              'source.depth_limit',
              node.relativePath,
              'Source depth quota exceeded');
          _require(node.byteLength >= 0 && node.token.isNotEmpty, 'source.node',
              node.relativePath, 'Invalid source node');
        } on ContractError catch (error) {
          diagnose(error.code, node.relativePath, error.message);
          continue;
        }
        if (effective.isExcluded(node.relativePath)) {
          if (initial) excluded.add(node.relativePath);
          continue;
        }
        _require(
            !result.containsKey(node.relativePath),
            'source.duplicate_path',
            node.relativePath,
            'Duplicate path in source walk');
        result[node.relativePath] = node;
        if (node.kind == SourceNodeKind.file) {
          declaredBytes += node.byteLength;
          if (node.byteLength > limits.maxFileBytes) {
            diagnose('source.file_limit', node.relativePath,
                'Declared file exceeds byte quota');
          }
          if (declaredBytes > limits.maxTotalBytes) {
            throw ContractError('source.total_limit', node.relativePath,
                'Declared source exceeds aggregate byte quota');
          }
        }
      }
      return result;
    }

    try {
      cancel.check();
      final nodes = await enumerate(initial: true);
      final ordered = nodes.values.toList()
        ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
      final groups = <String, Set<String>>{};
      for (final node in ordered) {
        for (final prefix in _sourcePathPrefixes(node.relativePath)) {
          (groups[sourcePathCollisionKey(prefix)] ??= {}).add(prefix);
        }
      }
      final ambiguous = <String>{};
      for (final group in groups.values) {
        if (group.length < 2) continue;
        final paths = group.toList()..sort();
        ambiguous.addAll(paths);
        diagnose('source.path_collision', paths.first,
            'Case or Unicode ambiguous source paths',
            related: paths);
      }
      bool forbidden(SourceNode node) {
        var prefix = '';
        for (final segment in node.relativePath.split('/')) {
          prefix = prefix.isEmpty ? segment : '$prefix/$segment';
          if (ambiguous.contains(prefix)) return true;
        }
        return node.byteLength > limits.maxFileBytes;
      }

      final files = ordered
          .where((node) => node.kind == SourceNodeKind.file && !forbidden(node))
          .toList();
      onProgress?.call(
          JobProgress(done: 0, total: files.length, unit: JobUnit.files));
      var done = 0;
      var actualTotal = 0;
      for (final node in ordered) {
        cancel.check();
        if (forbidden(node)) continue;
        if (node.kind == SourceNodeKind.link ||
            node.kind == SourceNodeKind.special) {
          diagnose(
              node.kind == SourceNodeKind.link
                  ? 'source.link'
                  : 'source.special',
              node.relativePath,
              'Links and special source files cannot be extracted');
          continue;
        }
        final fileId = ConverterId('f1:${canonicalHashOf({
              'namespace': logicalProjectNamespace.value,
              'relativePath': node.relativePath,
              'kind': node.kind.name,
            }).value}');
        if (node.kind == SourceNodeKind.directory) {
          entries.add(SourceFileEntry(
              fileId: fileId,
              relativePath: node.relativePath,
              kind: node.kind,
              byteLength: 0,
              sha256: null,
              format: 'directory',
              family: _sourceFamily(node.relativePath)));
          continue;
        }
        try {
          final digest = _SourceDigestSink();
          final sink = sha256.startChunkedConversion(digest);
          final prefix = <int>[];
          var actual = 0;
          final remainingTotal = limits.maxTotalBytes - actualTotal;
          final budget = limits.maxFileBytes < remainingTotal
              ? limits.maxFileBytes
              : remainingTotal;
          await for (final chunk
              in source.read(node, maxBytes: budget, cancellation: cancel)) {
            cancel.check();
            actual += chunk.length;
            actualTotal += chunk.length;
            _require(
                actual <= limits.maxFileBytes &&
                    actualTotal <= limits.maxTotalBytes,
                'source.actual_byte_limit',
                node.relativePath,
                'Actual source bytes exceed quota');
            _require(actual <= node.byteLength, 'source.changed',
                node.relativePath, 'Source file grew after preflight');
            sink.add(chunk);
            final remaining = limits.maxProbeBytes - prefix.length;
            if (remaining > 0) prefix.addAll(chunk.take(remaining));
          }
          cancel.check();
          _require(actual == node.byteLength, 'source.changed',
              node.relativePath, 'Source file shrank after preflight');
          sink.close();
          final hash = digest.hash;
          entries.add(SourceFileEntry(
              fileId: fileId,
              relativePath: node.relativePath,
              kind: node.kind,
              byteLength: actual,
              sha256: hash,
              format: _sourceFormat(node.relativePath),
              family: _sourceFamily(node.relativePath)));
          for (final observation
              in _observeEssentials(node.relativePath, hash, prefix)) {
            if (evidence.length >= limits.maxProfileEvidence) {
              diagnose('source.profile_evidence_limit', node.relativePath,
                  'Profile evidence quota exceeded');
              break;
            }
            evidence.add(observation);
          }
        } on ContractError catch (error) {
          if (error.code == 'source.cancelled') rethrow;
          diagnose(error.code, node.relativePath, error.message);
        } catch (_) {
          diagnose(
              'source.read_failed', node.relativePath, 'Source read failed');
        }
        done++;
        onProgress?.call(
            JobProgress(done: done, total: files.length, unit: JobUnit.files));
      }
      cancel.check();
      final after = await enumerate(initial: false);
      for (final path in {...nodes.keys, ...after.keys}.toList()..sort()) {
        final beforeNode = nodes[path];
        final afterNode = after[path];
        if (beforeNode == null ||
            afterNode == null ||
            beforeNode.kind != afterNode.kind ||
            beforeNode.byteLength != afterNode.byteLength ||
            beforeNode.token != afterNode.token) {
          diagnose(
              'source.changed', path, 'Source tree changed during inventory');
        }
      }
      cancel.check();
    } on ContractError catch (error) {
      if (error.code == 'source.cancelled') {
        diagnose(error.code, r'$', 'Scan cancelled');
        state = SourceScanState.cancelled;
      } else {
        diagnose(error.code, error.path, error.message);
        state =
            entries.isEmpty ? SourceScanState.failed : SourceScanState.partial;
      }
    } catch (_) {
      diagnose('source.walk_failed', r'$', 'Source enumeration failed');
      state =
          entries.isEmpty ? SourceScanState.failed : SourceScanState.partial;
    }
    return snapshot();
  }
}
