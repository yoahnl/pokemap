import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';

final class ConverterAssetReviewSetLimits {
  const ConverterAssetReviewSetLimits({
    required this.maxTotalCandidates,
    this.maxSegments = 256,
    this.maxTotalFrames = 64,
    this.maxTotalCandidateVersions = 4096,
    this.maxTotalParts = 65536,
    this.maxTotalClaims = 65536,
    this.maxTotalDecisions = 65536,
    this.maxJsonBytes = 8388608,
    this.segmentLimits = const AssetReviewLimits(),
    this.jsonLimits = const ContractLimits(),
  });

  final int maxTotalCandidates;
  final int maxSegments;
  final int maxTotalFrames;
  final int maxTotalCandidateVersions;
  final int maxTotalParts;
  final int maxTotalClaims;
  final int maxTotalDecisions;
  final int maxJsonBytes;
  final AssetReviewLimits segmentLimits;
  final ContractLimits jsonLimits;
}

final class ConverterAssetReviewSet {
  ConverterAssetReviewSet._({
    required this.sessionId,
    required this.logicalProjectNamespace,
    required this.sourceSnapshotHash,
    required this.normalizedSourceHash,
    required List<int> selectedSourceMapIds,
    required List<int> proposalSourceMapIds,
    required Map<int, AssetReviewSession> segments,
    required this.limits,
    required this.revision,
  })  : selectedSourceMapIds = _mapIds(selectedSourceMapIds),
        proposalSourceMapIds = _mapIds(proposalSourceMapIds),
        segments = Map.unmodifiable(Map.fromEntries(segments.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))) {
    _validate();
    _checkedJson();
  }

  factory ConverterAssetReviewSet.create({
    required ConverterId sessionId,
    required ConverterId logicalProjectNamespace,
    required Sha256Hash sourceSnapshotHash,
    required Sha256Hash normalizedSourceHash,
    required List<int> selectedSourceMapIds,
    required List<int> proposalSourceMapIds,
    required Map<int, AssetReviewSession> segments,
    required ConverterAssetReviewSetLimits limits,
  }) =>
      ConverterAssetReviewSet._(
        sessionId: sessionId,
        logicalProjectNamespace: logicalProjectNamespace,
        sourceSnapshotHash: sourceSnapshotHash,
        normalizedSourceHash: normalizedSourceHash,
        selectedSourceMapIds: selectedSourceMapIds,
        proposalSourceMapIds: proposalSourceMapIds,
        segments: segments,
        limits: limits,
        revision: 1,
      );

  factory ConverterAssetReviewSet.fromJson(Object? input,
      {ConverterAssetReviewSetLimits? admissionLimits}) {
    final raw = _object(input);
    final limits = _readSetLimits(raw['limits']);
    _validateLimits(limits);
    if (admissionLimits != null) {
      _validateLimits(admissionLimits);
      _within(_setLimitsJson(limits), _setLimitsJson(admissionLimits));
    }
    final encoded = canonicalJsonOf(input, limits: limits.jsonLimits);
    _require(utf8.encode(encoded).length <= limits.maxJsonBytes,
        'review.set.quota', 'Review set JSON byte budget exceeded');
    final json = _object(jsonDecode(encoded));
    _keys(json, const {
      'schemaVersion',
      'kind',
      'sessionId',
      'logicalProjectNamespace',
      'sourceSnapshotHash',
      'normalizedSourceHash',
      'selectedSourceMapIds',
      'proposalSourceMapIds',
      'revision',
      'outputMode',
      'limits',
      'segments',
      'setHash'
    });
    _require(
        json['schemaVersion'] == '2.0' &&
            json['kind'] == 'converterAssetReviewSet',
        'review.set.document',
        'Unsupported review set format');
    final segments = <int, AssetReviewSession>{};
    final rows = _list(json['segments']);
    _require(rows.length <= limits.maxSegments, 'review.set.quota',
        'Review segment budget exceeded');
    for (final raw in rows) {
      final row = _object(raw);
      _keys(row, const {'sourceMapId', 'limits', 'sessionHash', 'session'});
      final id = _integer(row['sourceMapId']);
      _require(!segments.containsKey(id), 'review.set.context',
          'Duplicate review segment map');
      final childLimits = _readReviewLimits(row['limits']);
      _within(_reviewLimitsJson(childLimits),
          _reviewLimitsJson(limits.segmentLimits));
      final child = AssetReviewSession.fromJson(
          _unpackReviewSession(row['session'], childLimits),
          limits: childLimits);
      _require(child.canonicalHash.value == row['sessionHash'],
          'review.set.hash', 'Review segment hash differs');
      segments[id] = child;
    }
    final result = ConverterAssetReviewSet._(
        sessionId: ConverterId(_string(json['sessionId'])),
        logicalProjectNamespace:
            ConverterId(_string(json['logicalProjectNamespace'])),
        sourceSnapshotHash: Sha256Hash(_string(json['sourceSnapshotHash'])),
        normalizedSourceHash: Sha256Hash(_string(json['normalizedSourceHash'])),
        selectedSourceMapIds:
            _list(json['selectedSourceMapIds']).map(_integer).toList(),
        proposalSourceMapIds:
            _list(json['proposalSourceMapIds']).map(_integer).toList(),
        segments: segments,
        limits: limits,
        revision: _integer(json['revision']));
    _require(result.outputMode.name == json['outputMode'], 'review.set.context',
        'Review output mode differs from its segments');
    _require(result.canonicalHash.value == json['setHash'], 'review.set.hash',
        'Review set hash differs');
    _require(encoded == result._checkedJson(), 'review.set.document',
        'Review set representation must be canonical');
    return result;
  }

  final ConverterId sessionId;
  final ConverterId logicalProjectNamespace;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash normalizedSourceHash;
  final List<int> selectedSourceMapIds;
  final List<int> proposalSourceMapIds;
  final Map<int, AssetReviewSession> segments;
  final ConverterAssetReviewSetLimits limits;
  final int revision;

  AssetOutputMode get outputMode => segments.values.first.outputMode;
  AssetOutputMode get seedOutputMode =>
      segments.values.first.frames.first.outputMode;
  late final Sha256Hash canonicalHash =
      canonicalHashOf(_json(includeSessions: false), limits: limits.jsonLimits);
  List<AssetCandidate> get activeCandidates => List.unmodifiable(
      segments.values.expand((s) => s.activeCandidates).toList()
        ..sort((a, b) => a.candidateId.value.compareTo(b.candidateId.value)));
  Map<ConverterId, Sha256Hash> get approvedCandidateHashes => Map.unmodifiable({
        for (final c in activeCandidates)
          for (final s in segments.values)
            if (s.approvedCandidateHashes[c.candidateId] case final hash?)
              c.candidateId: hash,
      });
  ReviewDecisions get activeDecisions => ReviewDecisions.fromJson({
        'schemaVersion': '1.0',
        'kind': 'reviewDecisions',
        'exampleOnly': false,
        'sessionId': sessionId.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'revision': revision,
        'decisions': [
          for (final s in segments.values)
            ...s.activeDecisions.decisions.map((d) => d.toJson())
        ],
      }, limits: limits.jsonLimits);

  Map<String, Object?> toJson() =>
      (jsonDecode(_checkedJson()) as Map).cast<String, Object?>();

  void validatePlacements(List<SourceMapIr> sourceMaps) {
    final maps = {for (final map in sourceMaps) map.map.sourceMapId: map};
    _require(maps.length == sourceMaps.length, 'review.set.context',
        'Source maps must be unique');
    for (final segment in segments.values) {
      for (final frame in segment.frames) {
        for (final candidate in frame.candidates) {
          for (final claim in frame.placementClaims[candidate.candidateId] ??
              <SourcePlacementClaim>[]) {
            final map = maps[claim.sourceMapId];
            _require(map != null, 'review.claim.map',
                'Placement map is unavailable for validation');
            claim.validateAgainst(map!, candidate);
          }
        }
      }
    }
  }

  ConverterAssetReviewSet replaceSegment({
    required int sourceMapId,
    required AssetReviewSession next,
    required Sha256Hash expectedSetHash,
    required Sha256Hash expectedSegmentHash,
  }) {
    final previous = segments[sourceMapId];
    _require(
        expectedSetHash == canonicalHash &&
            previous != null &&
            previous.canonicalHash == expectedSegmentHash,
        'review.set.conflict',
        'Review set or segment changed');
    if (previous!.canonicalHash == next.canonicalHash) return this;
    _require(
        previous.sessionId == next.sessionId &&
            previous.proposalGenerationHash == next.proposalGenerationHash &&
            canonicalHashOf({
                  for (final e in previous.baseProposalHashes.entries)
                    e.key.value: e.value.value
                }) ==
                canonicalHashOf({
                  for (final e in next.baseProposalHashes.entries)
                    e.key.value: e.value.value
                }) &&
            canonicalJsonOf(_reviewLimitsJson(previous.limits)) ==
                canonicalJsonOf(_reviewLimitsJson(next.limits)) &&
            previous.outputMode == next.outputMode &&
            previous.frames.first.canonicalHash ==
                next.frames.first.canonicalHash &&
            next.revision > previous.revision,
        'review.set.conflict',
        'Replacement must continue the same review segment');
    return _replace({...segments, sourceMapId: next});
  }

  ConverterAssetReviewSet changeOutputMode({
    required AssetOutputMode outputMode,
    required Sha256Hash expectedSetHash,
  }) {
    _require(expectedSetHash == canonicalHash, 'review.set.conflict',
        'Review set changed');
    _require(outputMode != AssetOutputMode.packedObjects,
        'review.set.output_mode', 'Packed objects are not admitted');
    if (outputMode == this.outputMode) return this;
    return _replace({
      for (final e in segments.entries)
        e.key: e.value.changeOutputMode(
            outputMode: outputMode, expectedSessionHash: e.value.canonicalHash)
    });
  }

  ConverterAssetReviewSet _replace(Map<int, AssetReviewSession> next) =>
      ConverterAssetReviewSet._(
          sessionId: sessionId,
          logicalProjectNamespace: logicalProjectNamespace,
          sourceSnapshotHash: sourceSnapshotHash,
          normalizedSourceHash: normalizedSourceHash,
          selectedSourceMapIds: selectedSourceMapIds,
          proposalSourceMapIds: proposalSourceMapIds,
          segments: next,
          limits: limits,
          revision: revision + 1);

  Map<String, Object?> _json({required bool includeSessions}) => {
        'schemaVersion': '2.0',
        'kind': 'converterAssetReviewSet',
        'sessionId': sessionId.value,
        'logicalProjectNamespace': logicalProjectNamespace.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizedSourceHash': normalizedSourceHash.value,
        'selectedSourceMapIds': selectedSourceMapIds,
        'proposalSourceMapIds': proposalSourceMapIds,
        'revision': revision,
        'outputMode': outputMode.name,
        'limits': _setLimitsJson(limits),
        'segments': [
          for (final e in segments.entries)
            {
              'sourceMapId': e.key,
              'limits': _reviewLimitsJson(e.value.limits),
              'sessionHash': e.value.canonicalHash.value,
              if (includeSessions) 'session': _packReviewSession(e.value),
            }
        ],
      };

  String _checkedJson() {
    final encoded = canonicalJsonOf(
        {..._json(includeSessions: true), 'setHash': canonicalHash.value},
        limits: limits.jsonLimits);
    _require(utf8.encode(encoded).length <= limits.maxJsonBytes,
        'review.set.quota', 'Review set JSON byte budget exceeded');
    return encoded;
  }

  void _validate() {
    _validateLimits(limits);
    _require(
        revision > 0 &&
            revision <= 2147483647 &&
            segments.isNotEmpty &&
            canonicalJsonOf(segments.keys.toList()) ==
                canonicalJsonOf(proposalSourceMapIds) &&
            selectedSourceMapIds.every(segments.containsKey),
        'review.set.context',
        'Review segments must cover the exact proposal map scope');
    var frames = 0;
    var versions = 0;
    var parts = 0;
    var claims = 0;
    var decisions = 0;
    final owners = <ConverterId, int>{};
    final sessionIds = <ConverterId>{};
    for (final e in segments.entries) {
      final child = e.value;
      _within(_reviewLimitsJson(child.limits),
          _reviewLimitsJson(limits.segmentLimits));
      _require(
          sessionIds.add(child.sessionId) &&
              child.logicalProjectNamespace == logicalProjectNamespace &&
              child.sourceSnapshotHash == sourceSnapshotHash &&
              canonicalJsonOf(_mapIds(child.selectedSourceMapIds)) ==
                  canonicalJsonOf(selectedSourceMapIds) &&
              child.outputMode == outputMode &&
              child.frames.first.outputMode == seedOutputMode &&
              child.outputMode != AssetOutputMode.packedObjects &&
              seedOutputMode != AssetOutputMode.packedObjects,
          'review.set.context',
          'Review segment context differs');
      frames += child.frames.length;
      final seenVersions = <Sha256Hash>{};
      for (final frame in child.frames) {
        decisions += frame.decisions.length;
        for (final candidate in frame.candidates) {
          final owner = owners.putIfAbsent(candidate.candidateId, () => e.key);
          _require(
              owner == e.key &&
                  candidate.parts.every((p) =>
                      p.locator.mapId == null || p.locator.mapId == e.key),
              'review.set.context',
              'Candidate belongs to a different map segment');
          if (seenVersions.add(candidate.canonicalHash)) {
            versions++;
            parts += candidate.parts.length;
          }
        }
        _require(
            frame.placementClaims.values
                .expand((v) => v)
                .every((c) => c.sourceMapId == e.key),
            'review.set.context',
            'Placement claim belongs to a different map segment');
      }
      final pool = child.toJson()['placementClaimLists'] as Map;
      claims += pool.values
          .fold<int>(0, (count, value) => count + (value as List).length);
    }
    for (final pair in [
      (segments.length, limits.maxSegments),
      (owners.length, limits.maxTotalCandidates),
      (frames, limits.maxTotalFrames),
      (versions, limits.maxTotalCandidateVersions),
      (parts, limits.maxTotalParts),
      (claims, limits.maxTotalClaims),
      (decisions, limits.maxTotalDecisions)
    ]) {
      _require(pair.$1 <= pair.$2, 'review.set.quota',
          'Review set cumulative budget exceeded');
    }
  }
}

Map<String, Object?> _packReviewSession(AssetReviewSession session) {
  final raw = session.toJson();
  final lists = _object(raw['placementClaimLists']);
  final contexts = <String, List<Object?>>{};
  for (final claims in lists.values) {
    for (final value in _list(claims)) {
      final claim = _object(value);
      final context = <Object?>[
        claim['sourceSnapshotHash'],
        claim['sourceMapFileId'],
        claim['sourceMapHash'],
        claim['sourceMapId'],
      ];
      contexts[canonicalJsonOf(context)] = context;
    }
  }
  final keys = contexts.keys.toList()..sort();
  final indices = {for (final entry in keys.indexed) entry.$2: entry.$1};
  return {
    ...raw,
    'placementClaimContexts': [for (final key in keys) contexts[key]],
    'placementClaimLists': {
      for (final entry in lists.entries)
        entry.key: [
          for (final value in _list(entry.value))
            _packClaim(_object(value), indices),
        ],
    },
  };
}

List<Object?> _packClaim(
        Map<String, Object?> claim, Map<String, int> indices) =>
    [
      indices[canonicalJsonOf([
        claim['sourceSnapshotHash'],
        claim['sourceMapFileId'],
        claim['sourceMapHash'],
        claim['sourceMapId'],
      ])],
      claim['partId'],
      claim['sourceZ'],
      claim['tileId'],
      claim['x'],
      claim['y'],
    ];

Map<String, Object?> _unpackReviewSession(
    Object? input, AssetReviewLimits limits) {
  final raw = _object(input);
  final contexts = _list(raw['placementClaimContexts']);
  final lists = _object(raw['placementClaimLists']);
  _require(contexts.length <= limits.maxTotalClaims, 'review.set.quota',
      'Placement context budget exceeded');
  for (final value in contexts) {
    final context = _list(value);
    _require(context.length == 4, 'review.set.document',
        'Placement context requires four exact fields');
    Sha256Hash(_string(context[0]));
    ConverterId(_string(context[1]));
    Sha256Hash(_string(context[2]));
    _require(_integer(context[3]) > 0, 'review.set.document',
        'Placement context map must be positive');
  }
  var count = 0;
  for (final value in lists.values) {
    count += _list(value).length;
    _require(count <= limits.maxTotalClaims, 'review.set.quota',
        'Placement claim budget exceeded');
  }
  return {
    for (final entry in raw.entries)
      if (entry.key != 'placementClaimContexts' &&
          entry.key != 'placementClaimLists')
        entry.key: entry.value,
    'placementClaimLists': {
      for (final entry in lists.entries)
        entry.key: [
          for (final value in _list(entry.value)) _unpackClaim(value, contexts),
        ],
    },
  };
}

Map<String, Object?> _unpackClaim(Object? value, List<Object?> contexts) {
  final claim = _list(value);
  _require(claim.length == 6, 'review.set.document',
      'Placement claim requires six exact fields');
  final index = _integer(claim[0]);
  _require(index >= 0 && index < contexts.length, 'review.set.document',
      'Placement context index is unavailable');
  final context = _list(contexts[index]);
  return {
    'sourceSnapshotHash': context[0],
    'sourceMapFileId': context[1],
    'sourceMapHash': context[2],
    'sourceMapId': context[3],
    'partId': _string(claim[1]),
    'sourceZ': _integer(claim[2]),
    'tileId': _integer(claim[3]),
    'x': _integer(claim[4]),
    'y': _integer(claim[5]),
  };
}

List<int> _mapIds(List<int> values) {
  _require(
      values.isNotEmpty &&
          values.length <= 1024 &&
          values.every((id) => id > 0 && id <= 2147483647) &&
          values.toSet().length == values.length,
      'review.set.context',
      'Map scope must contain unique bounded source IDs');
  return List.unmodifiable(values.toList()..sort());
}

Map<String, Object?> _jsonLimitsJson(ContractLimits limits) => {
      'maxDepth': limits.maxDepth,
      'maxNodes': limits.maxNodes,
      'maxStringCodeUnits': limits.maxStringCodeUnits,
      'maxTextCodeUnits': limits.maxTextCodeUnits
    };
Map<String, Object?> _reviewLimitsJson(AssetReviewLimits limits) => {
      'maxFrames': limits.maxFrames,
      'maxCandidates': limits.maxCandidates,
      'maxCandidateVersions': limits.maxCandidateVersions,
      'maxTotalParts': limits.maxTotalParts,
      'maxTotalClaims': limits.maxTotalClaims,
      'maxTotalDecisions': limits.maxTotalDecisions,
      'jsonLimits': _jsonLimitsJson(limits.jsonLimits)
    };
Map<String, Object?> _setLimitsJson(ConverterAssetReviewSetLimits limits) => {
      'maxTotalCandidates': limits.maxTotalCandidates,
      'maxSegments': limits.maxSegments,
      'maxTotalFrames': limits.maxTotalFrames,
      'maxTotalCandidateVersions': limits.maxTotalCandidateVersions,
      'maxTotalParts': limits.maxTotalParts,
      'maxTotalClaims': limits.maxTotalClaims,
      'maxTotalDecisions': limits.maxTotalDecisions,
      'maxJsonBytes': limits.maxJsonBytes,
      'segmentLimits': _reviewLimitsJson(limits.segmentLimits),
      'jsonLimits': _jsonLimitsJson(limits.jsonLimits)
    };

ContractLimits _readJsonLimits(Object? input) {
  final json = _object(input);
  _keys(json, _jsonLimitsJson(const ContractLimits()).keys.toSet());
  return ContractLimits(
      maxDepth: _integer(json['maxDepth']),
      maxNodes: _integer(json['maxNodes']),
      maxStringCodeUnits: _integer(json['maxStringCodeUnits']),
      maxTextCodeUnits: _integer(json['maxTextCodeUnits']));
}

AssetReviewLimits _readReviewLimits(Object? input) {
  final json = _object(input);
  _keys(json, _reviewLimitsJson(const AssetReviewLimits()).keys.toSet());
  return AssetReviewLimits(
      maxFrames: _integer(json['maxFrames']),
      maxCandidates: _integer(json['maxCandidates']),
      maxCandidateVersions: _integer(json['maxCandidateVersions']),
      maxTotalParts: _integer(json['maxTotalParts']),
      maxTotalClaims: _integer(json['maxTotalClaims']),
      maxTotalDecisions: _integer(json['maxTotalDecisions']),
      jsonLimits: _readJsonLimits(json['jsonLimits']));
}

ConverterAssetReviewSetLimits _readSetLimits(Object? input) {
  final json = _object(input);
  _keys(
      json,
      _setLimitsJson(
              const ConverterAssetReviewSetLimits(maxTotalCandidates: 1024))
          .keys
          .toSet());
  return ConverterAssetReviewSetLimits(
      maxTotalCandidates: _integer(json['maxTotalCandidates']),
      maxSegments: _integer(json['maxSegments']),
      maxTotalFrames: _integer(json['maxTotalFrames']),
      maxTotalCandidateVersions: _integer(json['maxTotalCandidateVersions']),
      maxTotalParts: _integer(json['maxTotalParts']),
      maxTotalClaims: _integer(json['maxTotalClaims']),
      maxTotalDecisions: _integer(json['maxTotalDecisions']),
      maxJsonBytes: _integer(json['maxJsonBytes']),
      segmentLimits: _readReviewLimits(json['segmentLimits']),
      jsonLimits: _readJsonLimits(json['jsonLimits']));
}

void _validateLimits(ConverterAssetReviewSetLimits limits) => _within(
    _setLimitsJson(limits),
    _setLimitsJson(const ConverterAssetReviewSetLimits(
        maxTotalCandidates: 1024, maxSegments: 1024, maxJsonBytes: 16777216)));
void _within(Map<String, Object?> values, Map<String, Object?> upper) {
  for (final e in values.entries) {
    if (e.value is Map<String, Object?>) {
      _within(e.value as Map<String, Object?>,
          upper[e.key] as Map<String, Object?>);
    } else {
      _require(
          e.value is int &&
              (e.value as int) > 0 &&
              (e.value as int) <= (upper[e.key] as int),
          'review.set.limits',
          'Review budget exceeds its explicit admission limit');
    }
  }
}

void _keys(Map<String, Object?> value, Set<String> expected) => _require(
    value.length == expected.length && expected.every(value.containsKey),
    'review.set.document',
    'Exact current-format fields are required');
Map<String, Object?> _object(Object? value) {
  _require(value is Map && value.keys.every((key) => key is String),
      'review.set.document', 'Expected JSON object');
  return (value as Map).cast<String, Object?>();
}

List<Object?> _list(Object? value) {
  _require(value is List, 'review.set.document', 'Expected JSON list');
  return (value as List).cast<Object?>();
}

int _integer(Object? value) {
  _require(value is int, 'review.set.document', 'Expected JSON integer');
  return value as int;
}

String _string(Object? value) {
  _require(value is String, 'review.set.document', 'Expected JSON string');
  return value as String;
}

void _require(bool condition, String code, String message) {
  if (!condition) throw ContractError(code, r'$', message);
}
