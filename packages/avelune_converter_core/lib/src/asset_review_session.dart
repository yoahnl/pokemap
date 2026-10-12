part of '../avelune_converter_core.dart';

final class AssetReviewLimits {
  const AssetReviewLimits({
    this.maxFrames = 64,
    this.maxCandidates = 256,
    this.maxCandidateVersions = 4096,
    this.maxTotalParts = 65536,
    this.maxTotalClaims = 65536,
    this.maxTotalDecisions = 65536,
    this.jsonLimits = const ContractLimits(),
  });
  final int maxFrames;
  final int maxCandidates;
  final int maxCandidateVersions;
  final int maxTotalParts;
  final int maxTotalClaims;
  final int maxTotalDecisions;
  final ContractLimits jsonLimits;

  void _validate() {
    for (final value in [
      maxFrames,
      maxCandidates,
      maxCandidateVersions,
      maxTotalParts,
      maxTotalClaims,
      maxTotalDecisions
    ]) {
      _reviewRequire(value > 0 && value <= 1000000, 'review.limits',
          'Review limits must be positive and bounded');
    }
  }
}

final class AssetReviewGeometry {
  AssetReviewGeometry({
    required List<Map<String, Object?>> parts,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.anchorX,
    required this.anchorY,
    required this.anchorConvention,
  }) : parts = _reviewGeometryParts(parts);
  final List<Map<String, Object?>> parts;
  final int canvasWidth;
  final int canvasHeight;
  final int anchorX;
  final int anchorY;
  final AnchorConvention anchorConvention;

  Map<String, Object?> _fields() => {
        'parts': parts,
        'canvasSize': {'width': canvasWidth, 'height': canvasHeight},
        'anchor': {
          'unit': 'pixel',
          'x': anchorX,
          'y': anchorY,
          'convention': anchorConvention.name
        },
      };
}

List<Map<String, Object?>> _reviewGeometryParts(
    List<Map<String, Object?>> parts) {
  _reviewRequire(parts.isNotEmpty && parts.length <= 4096,
      'review.geometry.quota', 'Geometry must contain bounded explicit parts');
  return List.unmodifiable((_freezeJson(parts, const ContractLimits()) as List)
      .cast<Map<String, Object?>>());
}

final class AssetUnionInput {
  const AssetUnionInput(
      {required this.candidateId,
      required this.expectedCandidateHash,
      required this.offsetX,
      required this.offsetY});
  final ConverterId candidateId;
  final Sha256Hash expectedCandidateHash;
  final int offsetX;
  final int offsetY;
}

final class AssetSplitGroup {
  AssetSplitGroup(
      {required this.candidateId,
      required List<ConverterId> partIds,
      required this.name,
      required this.category,
      this.anchor})
      : partIds = List.unmodifiable(partIds) {
    _reviewRequire(partIds.isNotEmpty && partIds.length <= 4096,
        'review.split.parts', 'A split group must contain explicit parts');
    _unique(partIds, r'$.partIds');
  }
  final ConverterId candidateId;
  final List<ConverterId> partIds;
  final String name;
  final AssetCategory category;
  final ({int x, int y, AnchorConvention convention})? anchor;
}

final class SourcePlacementClaim {
  SourcePlacementClaim(
      {required this.sourceSnapshotHash,
      required this.sourceMapHash,
      required this.sourceMapFileId,
      required this.sourceMapId,
      required this.sourceZ,
      required this.x,
      required this.y,
      required this.tileId,
      required this.partId}) {
    _reviewRequire(
        sourceMapId >= 0 &&
            sourceMapId <= 2147483647 &&
            sourceZ >= 0 &&
            sourceZ <= 2 &&
            x >= 0 &&
            x <= 2147483647 &&
            y >= 0 &&
            y <= 2147483647 &&
            tileId > 0 &&
            tileId <= 2147483647,
        'review.claim.bounds',
        'Placement coordinates and tile must be bounded');
  }

  factory SourcePlacementClaim.fromJson(Object? input) {
    final json = _reviewObject(_freezeJson(input, const ContractLimits()));
    _reviewKeys(json, const {
      'sourceSnapshotHash',
      'sourceMapHash',
      'sourceMapFileId',
      'sourceMapId',
      'sourceZ',
      'x',
      'y',
      'tileId',
      'partId'
    });
    return SourcePlacementClaim(
      sourceSnapshotHash: Sha256Hash(_reviewString(json['sourceSnapshotHash'])),
      sourceMapHash: Sha256Hash(_reviewString(json['sourceMapHash'])),
      sourceMapFileId: ConverterId(_reviewString(json['sourceMapFileId'])),
      sourceMapId: _reviewInt(json['sourceMapId']),
      sourceZ: _reviewInt(json['sourceZ']),
      x: _reviewInt(json['x']),
      y: _reviewInt(json['y']),
      tileId: _reviewInt(json['tileId']),
      partId: ConverterId(_reviewString(json['partId'])),
    );
  }

  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash sourceMapHash;
  final ConverterId sourceMapFileId;
  final int sourceMapId;
  final int sourceZ;
  final int x;
  final int y;
  final int tileId;
  final ConverterId partId;

  Map<String, Object?> toJson() => {
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'sourceMapHash': sourceMapHash.value,
        'sourceMapFileId': sourceMapFileId.value,
        'sourceMapId': sourceMapId,
        'sourceZ': sourceZ,
        'x': x,
        'y': y,
        'tileId': tileId,
        'partId': partId.value,
      };

  Sha256Hash get canonicalHash => canonicalHashOf(toJson());
  String get placementKey => canonicalHashOf({
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'sourceMapHash': sourceMapHash.value,
        'sourceMapFileId': sourceMapFileId.value,
        'sourceMapId': sourceMapId,
        'sourceZ': sourceZ,
        'x': x,
        'y': y,
      }).value;

  SourcePlacementClaim withPartId(ConverterId id) => SourcePlacementClaim(
        sourceSnapshotHash: sourceSnapshotHash,
        sourceMapHash: sourceMapHash,
        sourceMapFileId: sourceMapFileId,
        sourceMapId: sourceMapId,
        sourceZ: sourceZ,
        x: x,
        y: y,
        tileId: tileId,
        partId: id,
      );

  void _validateCandidate(AssetCandidate candidate) {
    final parts = candidate.parts.where((p) => p.partId == partId);
    _reviewRequire(
        candidate.sourceSnapshotHash == sourceSnapshotHash && parts.length == 1,
        'review.claim.candidate',
        'Placement claim belongs to another snapshot or part');
    final part = parts.single;
    final locator = part.locator;
    _reviewRequire(
        part.sourceLayer == sourceZ &&
            locator.mapId == sourceMapId &&
            locator.tileId == tileId &&
            locator.eventId == null &&
            locator.pageIndex == null &&
            locator.commandIndex == null,
        'review.claim.locator',
        'Placement claim contradicts the part locator');
  }

  void validateAgainst(SourceMapIr map, AssetCandidate candidate) {
    _validateCandidate(candidate);
    _reviewRequire(
        !map.exampleOnly &&
            map.sourceSnapshotHash == sourceSnapshotHash &&
            map.logicalProjectNamespace == candidate.logicalProjectNamespace &&
            map.canonicalHash == sourceMapHash &&
            map.map.sourceFileId == sourceMapFileId &&
            map.map.sourceMapId == sourceMapId &&
            x < map.map.width &&
            y < map.map.height,
        'review.claim.source',
        'Placement claim does not match the exact source map');
    final layers = map.map.layers.where((layer) => layer.sourceZ == sourceZ);
    _reviewRequire(
        layers.length == 1 &&
            layers.single.cells[y * map.map.width + x] == tileId,
        'review.claim.cell',
        'Placement claim does not match the source cell');
  }
}

final class AssetReviewConflict {
  AssetReviewConflict(
      {required this.claim, required List<ConverterId> candidateIds})
      : candidateIds = List.unmodifiable(candidateIds);
  final SourcePlacementClaim claim;
  final List<ConverterId> candidateIds;
}

final class AssetReviewFrame {
  AssetReviewFrame._(
      {required List<AssetCandidate> candidates,
      required List<VisionReviewProposal> visionProposals,
      required this.outputMode,
      required Map<ConverterId, ReviewDecision> decisions,
      required Map<ConverterId, Sha256Hash> approvedCandidateHashes,
      required Map<ConverterId, List<SourcePlacementClaim>> placementClaims})
      : candidates = List.unmodifiable(candidates),
        visionProposals = List.unmodifiable(visionProposals),
        decisions = Map.unmodifiable(decisions),
        approvedCandidateHashes = Map.unmodifiable(approvedCandidateHashes),
        placementClaims = Map.unmodifiable({
          for (final entry in placementClaims.entries)
            entry.key: List<SourcePlacementClaim>.unmodifiable(entry.value)
        });
  final List<AssetCandidate> candidates;
  final List<VisionReviewProposal> visionProposals;
  final AssetOutputMode outputMode;
  final Map<ConverterId, ReviewDecision> decisions;
  final Map<ConverterId, Sha256Hash> approvedCandidateHashes;
  final Map<ConverterId, List<SourcePlacementClaim>> placementClaims;

  Map<String, Object?> _json() => {
        'candidateHashes':
            candidates.map((c) => c.canonicalHash.value).toList(),
        'visionProposals': visionProposals.map((p) => p.toJson()).toList(),
        'outputMode': outputMode.name,
        'decisions': [
          for (final c in candidates)
            if (decisions[c.candidateId] case final decision?) decision.toJson()
        ],
        'approvedCandidateHashes': {
          for (final entry in approvedCandidateHashes.entries)
            entry.key.value: entry.value.value
        },
        'placementClaims': {
          for (final entry in placementClaims.entries)
            entry.key.value: entry.value.map((claim) => claim.toJson()).toList()
        },
      };
  Sha256Hash get canonicalHash => canonicalHashOf(_json());
}

final class AssetReviewSession {
  AssetReviewSession._(
      {required this.sessionId,
      required this.logicalProjectNamespace,
      required this.sourceSnapshotHash,
      required List<int> selectedSourceMapIds,
      required this.proposalGenerationHash,
      required Map<ConverterId, Sha256Hash> baseProposalHashes,
      required List<AssetReviewFrame> frames,
      required this.cursor,
      required this.revision,
      required this.limits})
      : selectedSourceMapIds = List.unmodifiable(selectedSourceMapIds),
        baseProposalHashes = Map.unmodifiable(baseProposalHashes),
        frames = List.unmodifiable(frames) {
    _validate();
    _freezeJson(_json(), limits.jsonLimits);
  }

  factory AssetReviewSession.create(
      {required ConverterId sessionId,
      required ConverterId logicalProjectNamespace,
      required Sha256Hash sourceSnapshotHash,
      required List<int> selectedSourceMapIds,
      required AssetOutputMode outputMode,
      required Sha256Hash proposalGenerationHash,
      required List<AssetCandidate> candidates,
      Map<ConverterId, List<SourcePlacementClaim>> placementClaims = const {},
      List<SourceMapIr> sourceMaps = const [],
      AssetReviewLimits limits = const AssetReviewLimits()}) {
    limits._validate();
    _reviewRequire(candidates.length <= limits.maxCandidates,
        'review.candidates.quota', 'Candidate budget exceeded');
    for (final candidate in candidates) {
      _reviewRequire(
          candidate.state == CandidateState.needsReview ||
              candidate.state == CandidateState.proposed,
          'review.initial.state',
          'Initial proposals cannot carry a review decision');
    }
    final value = AssetReviewSession._(
      sessionId: sessionId,
      logicalProjectNamespace: logicalProjectNamespace,
      sourceSnapshotHash: sourceSnapshotHash,
      selectedSourceMapIds: selectedSourceMapIds,
      proposalGenerationHash: proposalGenerationHash,
      baseProposalHashes: {
        for (final c in candidates) c.candidateId: c.canonicalHash
      },
      frames: [
        AssetReviewFrame._(
            candidates: candidates,
            visionProposals: const [],
            outputMode: outputMode,
            decisions: const {},
            approvedCandidateHashes: const {},
            placementClaims: placementClaims)
      ],
      cursor: 0,
      revision: 1,
      limits: limits,
    );
    value.validatePlacements(sourceMaps);
    return value;
  }

  factory AssetReviewSession.fromJson(Object? input,
      {AssetReviewLimits limits = const AssetReviewLimits()}) {
    limits._validate();
    final json = _reviewObject(_freezeJson(input, limits.jsonLimits));
    _reviewKeys(json, const {
      'schemaVersion',
      'kind',
      'sessionId',
      'logicalProjectNamespace',
      'sourceSnapshotHash',
      'selectedSourceMapIds',
      'outputMode',
      'proposalGenerationHash',
      'baseProposalHashes',
      'candidateVersions',
      'frames',
      'cursor',
      'revision'
    });
    _reviewRequire(
        json['schemaVersion'] == '1.1' && json['kind'] == 'assetReviewSession',
        'review.document.version',
        'Unsupported review document');
    final sessionId = ConverterId(_reviewString(json['sessionId']));
    final snapshot = Sha256Hash(_reviewString(json['sourceSnapshotHash']));
    final versionsJson = _reviewObject(json['candidateVersions']);
    final framesJson = _reviewList(json['frames']);
    _reviewRequire(
        versionsJson.length <= limits.maxCandidateVersions &&
            framesJson.isNotEmpty &&
            framesJson.length <= limits.maxFrames,
        'review.document.quota',
        'Review document budget exceeded');
    var parts = 0;
    for (final value in versionsJson.values) {
      parts += _reviewList(_reviewObject(value)['parts']).length;
      _reviewRequire(parts <= limits.maxTotalParts, 'review.parts.quota',
          'Unique candidate geometry budget exceeded');
    }
    final versions = <Sha256Hash, AssetCandidate>{};
    for (final entry in versionsJson.entries) {
      final hash = Sha256Hash(entry.key);
      final candidate =
          AssetCandidate.fromJson(entry.value, limits: limits.jsonLimits);
      _reviewRequire(candidate.canonicalHash == hash, 'review.version.hash',
          'Candidate version content does not match its hash');
      versions[hash] = candidate;
    }
    final frames = <AssetReviewFrame>[];
    var claimsCount = 0;
    var decisionsCount = 0;
    for (final raw in framesJson) {
      final value = _reviewObject(raw);
      _reviewKeys(value, const {
        'candidateHashes',
        'visionProposals',
        'outputMode',
        'decisions',
        'approvedCandidateHashes',
        'placementClaims'
      });
      final hashes = _reviewList(value['candidateHashes']);
      final decisionsJson = _reviewList(value['decisions']);
      final claimsJson = _reviewObject(value['placementClaims']);
      decisionsCount += decisionsJson.length;
      for (final list in claimsJson.values) {
        claimsCount += _reviewList(list).length;
      }
      _reviewRequire(
          hashes.length <= limits.maxCandidates &&
              decisionsCount <= limits.maxTotalDecisions &&
              claimsCount <= limits.maxTotalClaims,
          'review.history.quota',
          'Review history budget exceeded');
      final candidates = <AssetCandidate>[];
      for (final hash in hashes) {
        final candidate = versions[Sha256Hash(_reviewString(hash))];
        _reviewRequire(candidate != null, 'review.version.reference',
            'Frame references an unknown candidate version');
        candidates.add(candidate!);
      }
      final decisions = ReviewDecisions.fromJson({
        'schemaVersion': '1.0',
        'kind': 'reviewDecisions',
        'exampleOnly': false,
        'sessionId': sessionId.value,
        'sourceSnapshotHash': snapshot.value,
        'revision': _reviewInt(json['revision']),
        'decisions': decisionsJson,
      }, limits: limits.jsonLimits)
          .decisions;
      _unique(decisions.map((d) => d.candidateId), r'$.frame.decisions');
      frames.add(AssetReviewFrame._(
        candidates: candidates,
        visionProposals: _reviewList(value['visionProposals'])
            .map(VisionReviewProposal._fromJson)
            .toList(),
        outputMode: _reviewOutputMode(value['outputMode']),
        decisions: {for (final d in decisions) d.candidateId: d},
        approvedCandidateHashes:
            _reviewHashMap(value['approvedCandidateHashes']),
        placementClaims: {
          for (final entry in claimsJson.entries)
            ConverterId(entry.key): _reviewList(entry.value)
                .map(SourcePlacementClaim.fromJson)
                .toList()
        },
      ));
    }
    final document = AssetReviewSession._(
      sessionId: sessionId,
      logicalProjectNamespace:
          ConverterId(_reviewString(json['logicalProjectNamespace'])),
      sourceSnapshotHash: snapshot,
      selectedSourceMapIds:
          _reviewList(json['selectedSourceMapIds']).map(_reviewInt).toList(),
      proposalGenerationHash:
          Sha256Hash(_reviewString(json['proposalGenerationHash'])),
      baseProposalHashes: _reviewHashMap(json['baseProposalHashes']),
      frames: frames,
      cursor: _reviewInt(json['cursor']),
      revision: _reviewInt(json['revision']),
      limits: limits,
    );
    _reviewRequire(
        document.outputMode == _reviewOutputMode(json['outputMode']),
        'review.output.context',
        'Current output mode disagrees with its frame');
    final referenced = {
      for (final frame in frames)
        for (final candidate in frame.candidates) candidate.canonicalHash
    };
    _reviewRequire(
        referenced.length == versions.length,
        'review.version.unreferenced',
        'Document contains unreferenced candidate versions');
    return document;
  }

  final ConverterId sessionId;
  final ConverterId logicalProjectNamespace;
  final Sha256Hash sourceSnapshotHash;
  final List<int> selectedSourceMapIds;
  final Sha256Hash proposalGenerationHash;
  final Map<ConverterId, Sha256Hash> baseProposalHashes;
  final List<AssetReviewFrame> frames;
  final int cursor;
  final int revision;
  final AssetReviewLimits limits;
  AssetReviewFrame get frame => frames[cursor];
  AssetOutputMode get outputMode => frame.outputMode;
  bool get canUndo => cursor > 0;
  bool get canRedo => cursor + 1 < frames.length;
  List<AssetCandidate> get activeCandidates => List.unmodifiable(
      frame.candidates.where((c) => c.state != CandidateState.superseded));
  Map<ConverterId, Sha256Hash> get approvedCandidateHashes =>
      frame.approvedCandidateHashes;

  ReviewDecisions get activeDecisions => ReviewDecisions.fromJson({
        'schemaVersion': '1.0',
        'kind': 'reviewDecisions',
        'exampleOnly': false,
        'sessionId': sessionId.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'revision': revision,
        'decisions': [
          for (final candidate in activeCandidates)
            if (frame.decisions[candidate.candidateId] case final decision?)
              decision.toJson()
        ],
      }, limits: limits.jsonLimits);

  List<AssetReviewConflict> get conflicts {
    final owners = <String, List<ConverterId>>{};
    final claims = <String, SourcePlacementClaim>{};
    for (final candidate in activeCandidates) {
      if (candidate.integrationMode != IntegrationMode.replacePlacements ||
          candidate.state == CandidateState.keepLiteral) {
        continue;
      }
      for (final claim in frame.placementClaims[candidate.candidateId] ??
          <SourcePlacementClaim>[]) {
        owners
            .putIfAbsent(claim.placementKey, () => [])
            .add(candidate.candidateId);
        claims[claim.placementKey] = claim;
      }
    }
    final keys = owners.keys
        .where((key) => owners[key]!.toSet().length > 1)
        .toList()
      ..sort();
    return List.unmodifiable([
      for (final key in keys)
        AssetReviewConflict(
            claim: claims[key]!, candidateIds: owners[key]!.toSet().toList())
    ]);
  }

  Map<String, Object?> _json() => {
        'schemaVersion': '1.1',
        'kind': 'assetReviewSession',
        'sessionId': sessionId.value,
        'logicalProjectNamespace': logicalProjectNamespace.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'selectedSourceMapIds': selectedSourceMapIds,
        'outputMode': outputMode.name,
        'proposalGenerationHash': proposalGenerationHash.value,
        'baseProposalHashes': {
          for (final entry in baseProposalHashes.entries)
            entry.key.value: entry.value.value
        },
        'candidateVersions': {
          for (final frame in frames)
            for (final candidate in frame.candidates)
              candidate.canonicalHash.value: candidate.toJson()
        },
        'frames': frames.map((frame) => frame._json()).toList(),
        'cursor': cursor,
        'revision': revision,
      };
  Map<String, Object?> toJson() =>
      _reviewObject(_freezeJson(_json(), limits.jsonLimits));
  late final Sha256Hash canonicalHash =
      canonicalHashOf(_json(), limits: limits.jsonLimits);

  void _validate() {
    limits._validate();
    _reviewRequire(
        frames.isNotEmpty &&
            frames.length <= limits.maxFrames &&
            cursor >= 0 &&
            cursor < frames.length &&
            revision >= frames.length &&
            revision <= 2147483647,
        'review.history.bounds',
        'Invalid review history or revision');
    _reviewRequire(
        selectedSourceMapIds.isNotEmpty &&
            selectedSourceMapIds.length <= 10000 &&
            selectedSourceMapIds.every((id) => id >= 0 && id <= 2147483647),
        'review.maps',
        'Review requires a bounded source map selection');
    _unique(selectedSourceMapIds, r'$.selectedSourceMapIds');
    final versions = <Sha256Hash>{};
    final knownCandidates = <Sha256Hash, AssetCandidate>{};
    var partCount = 0;
    var claimCount = 0;
    var decisionCount = 0;
    for (final frame in frames) {
      _reviewRequire(frame.candidates.length <= limits.maxCandidates,
          'review.candidates.quota', 'Candidate budget exceeded');
      _unique(
          frame.candidates.map((c) => c.candidateId), r'$.frame.candidates');
      final candidates = {for (final c in frame.candidates) c.candidateId: c};
      decisionCount += frame.decisions.length;
      _reviewRequire(decisionCount <= limits.maxTotalDecisions,
          'review.decisions.quota', 'Decision history budget exceeded');
      for (final candidate in frame.candidates) {
        knownCandidates[candidate.canonicalHash] = candidate;
        _reviewRequire(
            !candidate.exampleOnly &&
                candidate.logicalProjectNamespace == logicalProjectNamespace &&
                candidate.sourceSnapshotHash == sourceSnapshotHash &&
                candidate.outputMode == frame.outputMode,
            'review.candidate.context',
            'Candidate context differs from its review frame');
        if (versions.add(candidate.canonicalHash)) {
          partCount += candidate.parts.length;
          _reviewRequire(
              versions.length <= limits.maxCandidateVersions &&
                  partCount <= limits.maxTotalParts,
              'review.versions.quota',
              'Unique candidate version budget exceeded');
        }
        final decision = frame.decisions[candidate.candidateId];
        if (candidate.state == CandidateState.approved) {
          _reviewRequire(
              candidate.integrationMode == IntegrationMode.libraryOnly,
              'review.replacement.uncertified',
              'Native placement replacement cannot carry an approval');
          _reviewRequire(
              decision != null &&
                  decision.action == ReviewAction.approve &&
                  decision.humanConfirmed &&
                  frame.approvedCandidateHashes[candidate.candidateId] ==
                      candidate.canonicalHash,
              'review.approval.receipt',
              'Approved candidate lacks its exact current receipt');
        } else {
          _reviewRequire(
              !frame.approvedCandidateHashes.containsKey(candidate.candidateId),
              'review.approval.stale',
              'Unapproved candidate carries an approval receipt');
        }
        if (candidate.state == CandidateState.keepLiteral ||
            candidate.state == CandidateState.superseded) {
          _reviewRequire(
              decision != null &&
                  decision.action ==
                      (candidate.state == CandidateState.keepLiteral
                          ? ReviewAction.keepLiteral
                          : ReviewAction.supersede),
              'review.state.decision',
              'Reviewed state lacks its current decision');
        }
      }
      _reviewRequire(frame.visionProposals.length <= 128,
          'vision.proposals.quota', 'Pending AI proposal budget exceeded');
      _unique(frame.visionProposals.map((p) => p.proposalId),
          r'$.frame.visionProposals');
      for (final proposal in frame.visionProposals) {
        _reviewRequire(
            proposal.sourceSnapshotHash == sourceSnapshotHash &&
                proposal.candidateHashes.entries.every((entry) =>
                    knownCandidates[entry.value]?.candidateId == entry.key),
            'vision.proposal.context',
            'Pending AI proposal references another snapshot or unknown candidate version');
      }
      _reviewRequire(
          frame.approvedCandidateHashes.keys.every(candidates.containsKey) &&
              frame.decisions.keys.every(candidates.containsKey) &&
              frame.placementClaims.keys.every(candidates.containsKey),
          'review.frame.reference',
          'Frame contains an unknown candidate reference');
      for (final entry in frame.decisions.entries) {
        final decision = entry.value;
        final candidate = candidates[entry.key]!;
        _reviewRequire(
            decision.candidateId == entry.key &&
                decision.candidateRevision == candidate.revision &&
                decision.replacementCandidateIds.every(candidates.containsKey),
            'review.decision.reference',
            'Decision is stale or references an unknown replacement');
        final expectedState = switch (decision.action) {
          ReviewAction.approve => CandidateState.approved,
          ReviewAction.keepLiteral => CandidateState.keepLiteral,
          ReviewAction.supersede => CandidateState.superseded,
          _ => CandidateState.needsReview,
        };
        _reviewRequire(
            decision.humanConfirmed && candidate.state == expectedState,
            'review.decision.state',
            'Human decision does not match the candidate state');
      }
      for (final entry in frame.placementClaims.entries) {
        claimCount += entry.value.length;
        _reviewRequire(claimCount <= limits.maxTotalClaims,
            'review.claims.quota', 'Placement claim history budget exceeded');
        _unique(entry.value.map((claim) => (claim.partId, claim.placementKey)),
            r'$.frame.placementClaims');
        for (final claim in entry.value) {
          claim._validateCandidate(candidates[entry.key]!);
        }
      }
    }
    final original = {
      for (final candidate in frames.first.candidates)
        candidate.candidateId: candidate.canonicalHash
    };
    _reviewRequire(
        original.length == baseProposalHashes.length &&
            original.entries
                .every((entry) => baseProposalHashes[entry.key] == entry.value),
        'review.proposals.context',
        'Original proposal hashes do not match the initial frame');
  }

  void validatePlacements(List<SourceMapIr> sourceMaps) {
    _unique(sourceMaps.map((map) => map.map.sourceMapId), r'$.sourceMaps');
    final maps = {for (final map in sourceMaps) map.map.sourceMapId: map};
    for (final candidate in frame.candidates) {
      for (final claim in frame.placementClaims[candidate.candidateId] ??
          <SourcePlacementClaim>[]) {
        final map = maps[claim.sourceMapId];
        _reviewRequire(map != null, 'review.claim.map',
            'Placement map is unavailable for validation');
        claim.validateAgainst(map!, candidate);
      }
    }
  }

  void _expect(Sha256Hash expected) => _reviewRequire(expected == canonicalHash,
      'review.session.stale', 'Review document changed before this command');
  AssetReviewSession importVisionSuggestions(
      {required VisionResponse response,
      required VisionRequest request,
      required VisionLiveContext live,
      required List<SourceImage> verifiedSources,
      required Sha256Hash expectedSessionHash}) {
    _expect(expectedSessionHash);
    validateVisionResult(response, request, live);
    _reviewRequire(
        request.material.expectedSessionHash == canonicalHash &&
            request.context.sourceSnapshotHash == sourceSnapshotHash &&
            request.context.inputRevision == revision,
        'vision.import.context',
        'Response belongs to another exact review revision');
    for (final entry in request.material.candidateHashes.entries) {
      _candidate(entry.key, entry.value);
    }
    final sources =
        _visionSelectedSources(request.material.toJson(), verifiedSources);
    _reviewRequire(
        frame.visionProposals.length + response.suggestions.length <=
            request.material.limits.maxProposals,
        'vision.proposals.quota',
        'Pending AI proposal budget exceeded');
    if (response.suggestions.isEmpty) return this;
    _canAppend();
    final proposals = [
      ...frame.visionProposals,
      for (final suggestion in response.suggestions)
        VisionReviewProposal._create(suggestion, request.material, sources),
    ];
    _unique(proposals.map((p) => p.proposalId), r'$.visionProposals');
    return _withVisionProposals(proposals);
  }

  AssetReviewSession applyVisionMetadata(
      {required ConverterId proposalId,
      required Sha256Hash expectedSessionHash,
      required bool humanConfirmed}) {
    _expect(expectedSessionHash);
    _reviewRequire(humanConfirmed, 'vision.application.human',
        'Metadata requires an explicit human decision');
    final proposal = _visionProposal(proposalId);
    final suggestion = proposal.suggestion;
    _reviewRequire(
        suggestion.candidateIds.length == 1,
        'vision.application.group',
        'Grouping proposals require a separate human union with explicit geometry');
    final id = suggestion.candidateIds.single;
    final candidate = _candidate(id, proposal.candidateHashes[id]!);
    _canAppend();
    final next = _changed(candidate, {
      'name': _reviewName(suggestion.proposedName),
      'category': suggestion.category.name,
      'evidence': [
        ...candidate.evidence.map((e) => e.toJson()),
        {
          'type': 'aiSuggestion',
          'summary': suggestion.evidenceSummary,
          'reference':
              'vision:${proposal.provider}:${proposal.model}:${proposal.materialHash.value}:${suggestion.suggestionId.value}'
        },
      ],
      'uncertainties': [
        ...{...candidate.uncertainties, ...suggestion.uncertainties}
      ],
    });
    return _replace(
        next,
        candidate.category == suggestion.category
            ? ReviewAction.rename
            : ReviewAction.reclassify,
        visionProposals: frame.visionProposals
            .where((p) => p.proposalId != proposalId)
            .toList());
  }

  AssetReviewSession removeVisionProposal(
      {required ConverterId proposalId,
      required Sha256Hash expectedSessionHash,
      required bool humanConfirmed}) {
    _expect(expectedSessionHash);
    _reviewRequire(humanConfirmed, 'vision.discard.human',
        'Discard requires an explicit human decision');
    _visionProposal(proposalId);
    return _withVisionProposals(frame.visionProposals
        .where((p) => p.proposalId != proposalId)
        .toList());
  }

  VisionReviewProposal _visionProposal(ConverterId id) {
    final matches = frame.visionProposals.where((p) => p.proposalId == id);
    _reviewRequire(matches.length == 1, 'vision.proposal.missing',
        'Pending proposal no longer exists');
    return matches.single;
  }

  AssetReviewSession _withVisionProposals(
          List<VisionReviewProposal> proposals) =>
      _append(AssetReviewFrame._(
        candidates: frame.candidates,
        visionProposals: proposals,
        outputMode: outputMode,
        decisions: frame.decisions,
        approvedCandidateHashes: frame.approvedCandidateHashes,
        placementClaims: frame.placementClaims,
      ));
  AssetCandidate _candidate(ConverterId id, Sha256Hash hash) {
    final matches = activeCandidates.where((c) => c.candidateId == id);
    _reviewRequire(matches.length == 1 && matches.single.canonicalHash == hash,
        'review.candidate.stale', 'Candidate changed or is no longer active');
    return matches.single;
  }

  void _newIdentity(ConverterId id) => _reviewRequire(
      !frames.any((frame) => frame.candidates.any((c) => c.candidateId == id)),
      'review.identity.used',
      'Candidate identity already exists in review history');
  void _canAppend() => _reviewRequire(
      cursor + 2 <= limits.maxFrames && revision < 2147483647,
      'review.history.quota',
      'Review history or revision budget exceeded');

  AssetReviewSession _append(AssetReviewFrame next) {
    _canAppend();
    return _withHistory([...frames.take(cursor + 1), next], cursor + 1);
  }

  AssetReviewSession _withHistory(
          List<AssetReviewFrame> nextFrames, int nextCursor) =>
      AssetReviewSession._(
        sessionId: sessionId,
        logicalProjectNamespace: logicalProjectNamespace,
        sourceSnapshotHash: sourceSnapshotHash,
        selectedSourceMapIds: selectedSourceMapIds,
        proposalGenerationHash: proposalGenerationHash,
        baseProposalHashes: baseProposalHashes,
        frames: nextFrames,
        cursor: nextCursor,
        revision: revision + 1,
        limits: limits,
      );

  AssetCandidate _changed(
          AssetCandidate candidate, Map<String, Object?> fields) =>
      AssetCandidate.fromJson({
        ...candidate.toJson(),
        'revision': candidate.revision + 1,
        'state': 'needsReview',
        'approvedRevision': null,
        ...fields
      }, limits: limits.jsonLimits);

  ReviewDecision _decision(AssetCandidate candidate, ReviewAction action,
      {List<ConverterId> replacements = const []}) {
    final record = {
      'decisionId': 'review-${canonicalHashOf({
            'sessionId': sessionId.value,
            'revision': revision + 1,
            'candidateHash': candidate.canonicalHash.value,
            'action': action.name,
            'replacements': replacements.map((id) => id.value).toList()
          }).value}',
      'candidateId': candidate.candidateId.value,
      'candidateRevision': candidate.revision,
      'action': action.name,
      'humanConfirmed': true,
      'replacementCandidateIds': replacements.map((id) => id.value).toList(),
      'note': 'Explicit local human review; source project unchanged.',
    };
    return ReviewDecisions.fromJson({
      'schemaVersion': '1.0',
      'kind': 'reviewDecisions',
      'exampleOnly': false,
      'sessionId': sessionId.value,
      'sourceSnapshotHash': sourceSnapshotHash.value,
      'revision': revision + 1,
      'decisions': [record]
    }).decisions.single;
  }

  AssetReviewSession _replace(AssetCandidate candidate, ReviewAction action,
      {List<SourcePlacementClaim>? claims,
      List<VisionReviewProposal>? visionProposals}) {
    final approved = {...frame.approvedCandidateHashes}
      ..remove(candidate.candidateId);
    if (candidate.state == CandidateState.approved) {
      approved[candidate.candidateId] = candidate.canonicalHash;
    }
    final placementClaims = {...frame.placementClaims};
    if (claims != null) {
      placementClaims[candidate.candidateId] = claims;
    }
    return _append(AssetReviewFrame._(
      candidates: [
        for (final old in frame.candidates)
          old.candidateId == candidate.candidateId ? candidate : old
      ],
      visionProposals: visionProposals ?? frame.visionProposals,
      outputMode: outputMode,
      decisions: {
        ...frame.decisions,
        candidate.candidateId: _decision(candidate, action)
      },
      approvedCandidateHashes: approved,
      placementClaims: placementClaims,
    ));
  }

  AssetReviewSession decide(
      {required ConverterId candidateId,
      required Sha256Hash expectedCandidateHash,
      required Sha256Hash expectedSessionHash,
      required ReviewAction action,
      required bool humanConfirmed}) {
    _expect(expectedSessionHash);
    final candidate = _candidate(candidateId, expectedCandidateHash);
    _canAppend();
    _reviewRequire(
        humanConfirmed &&
            (action == ReviewAction.approve ||
                action == ReviewAction.keepLiteral),
        'review.decision.human',
        'Review requires an explicit approval or keep-literal decision');
    if (action == ReviewAction.approve) {
      _reviewRequire(
          candidate.integrationMode == IntegrationMode.libraryOnly,
          'review.replacement.uncertified',
          'Native placement replacement is not certified');
      _reviewRequire(
          candidate.category != AssetCategory.unclassified &&
              candidate.name.trim().isNotEmpty,
          'review.approval.metadata',
          'Approval requires an explicit name and category');
    }
    final next = _changed(candidate, {
      'state': action == ReviewAction.approve ? 'approved' : 'keepLiteral',
      'approvedRevision':
          action == ReviewAction.approve ? candidate.revision + 1 : null,
      'integrationMode': 'libraryOnly',
    });
    return _replace(next, action);
  }

  AssetReviewSession editMetadata(
      {required ConverterId candidateId,
      required Sha256Hash expectedCandidateHash,
      required Sha256Hash expectedSessionHash,
      String? name,
      AssetCategory? category}) {
    _expect(expectedSessionHash);
    final candidate = _candidate(candidateId, expectedCandidateHash);
    final nextName = name == null ? candidate.name : _reviewName(name);
    final nextCategory = category ?? candidate.category;
    if (nextName == candidate.name && nextCategory == candidate.category) {
      return this;
    }
    _canAppend();
    return _replace(
        _changed(candidate, {'name': nextName, 'category': nextCategory.name}),
        name != null ? ReviewAction.rename : ReviewAction.reclassify);
  }

  AssetReviewSession changeGeometry(
      {required ConverterId candidateId,
      required Sha256Hash expectedCandidateHash,
      required Sha256Hash expectedSessionHash,
      required AssetReviewGeometry geometry}) {
    _expect(expectedSessionHash);
    final candidate = _candidate(candidateId, expectedCandidateHash);
    _canAppend();
    final next = _changed(candidate, geometry._fields());
    final previousParts = {for (final p in candidate.parts) p.partId: p};
    final nextParts = {for (final p in next.parts) p.partId: p};
    final claims = <SourcePlacementClaim>[];
    for (final claim
        in frame.placementClaims[candidateId] ?? <SourcePlacementClaim>[]) {
      final previousPart = previousParts[claim.partId];
      final nextPart = nextParts[claim.partId];
      if (previousPart == null ||
          nextPart == null ||
          !_samePartProvenance(previousPart, nextPart)) {
        continue;
      }
      try {
        claim._validateCandidate(next);
        claims.add(claim);
      } on ContractError {
        continue;
      }
    }
    return _replace(next, ReviewAction.changeGeometry, claims: claims);
  }

  bool _samePartProvenance(AssetPart previous, AssetPart next) =>
      previous.sourceFileId == next.sourceFileId &&
      previous.sourceRect.x == next.sourceRect.x &&
      previous.sourceRect.y == next.sourceRect.y &&
      previous.sourceRect.width == next.sourceRect.width &&
      previous.sourceRect.height == next.sourceRect.height &&
      previous.quarterTurns == next.quarterTurns &&
      previous.reflected == next.reflected &&
      previous.sourceLayer == next.sourceLayer &&
      previous.sourcePriority == next.sourcePriority &&
      canonicalJsonOf(previous.locator.toJson()) ==
          canonicalJsonOf(next.locator.toJson());

  AssetReviewSession setIntegrationMode(
      {required ConverterId candidateId,
      required Sha256Hash expectedCandidateHash,
      required Sha256Hash expectedSessionHash,
      required IntegrationMode integrationMode,
      required List<SourcePlacementClaim> placementClaims,
      required List<SourceMapIr> sourceMaps}) {
    _expect(expectedSessionHash);
    final candidate = _candidate(candidateId, expectedCandidateHash);
    _canAppend();
    _reviewRequire(
        placementClaims.length <= limits.maxTotalClaims &&
            (integrationMode != IntegrationMode.replacePlacements ||
                placementClaims.isNotEmpty),
        'review.claims.required',
        'Replacement intention requires bounded exact placement claims');
    final next = _changed(candidate, {'integrationMode': integrationMode.name});
    _validateReviewClaims(next, placementClaims, sourceMaps);
    return _replace(next, ReviewAction.changeGeometry, claims: placementClaims);
  }

  AssetReviewSession createManualCandidate(
      {required AssetCandidate candidate,
      required Sha256Hash expectedSessionHash,
      List<SourcePlacementClaim> placementClaims = const [],
      List<SourceMapIr> sourceMaps = const []}) {
    _expect(expectedSessionHash);
    _newIdentity(candidate.candidateId);
    _canAppend();
    _reviewRequire(
        frame.candidates.length < limits.maxCandidates &&
            candidate.revision == 1 &&
            candidate.state == CandidateState.needsReview &&
            candidate.integrationMode == IntegrationMode.libraryOnly,
        'review.manual.state',
        'Manual proposal must be a new unapproved library candidate');
    _validateReviewClaims(candidate, placementClaims, sourceMaps);
    return _append(AssetReviewFrame._(
        candidates: [...frame.candidates, candidate],
        visionProposals: frame.visionProposals,
        outputMode: outputMode,
        decisions: frame.decisions,
        approvedCandidateHashes: frame.approvedCandidateHashes,
        placementClaims: {
          ...frame.placementClaims,
          candidate.candidateId: placementClaims
        }));
  }

  AssetReviewSession changeOutputMode(
      {required AssetOutputMode outputMode,
      required Sha256Hash expectedSessionHash}) {
    _expect(expectedSessionHash);
    if (outputMode == this.outputMode) return this;
    _canAppend();
    final candidates = [
      for (final candidate in frame.candidates)
        _changed(candidate, {
          'outputMode': outputMode.name,
          if (candidate.state == CandidateState.superseded)
            'state': 'superseded',
          if (candidate.state == CandidateState.keepLiteral)
            'state': 'keepLiteral'
        })
    ];
    final decisions = <ConverterId, ReviewDecision>{};
    for (final candidate in candidates) {
      final old = frame.decisions[candidate.candidateId];
      decisions[candidate.candidateId] = _decision(
          candidate,
          candidate.state == CandidateState.superseded
              ? ReviewAction.supersede
              : candidate.state == CandidateState.keepLiteral
                  ? ReviewAction.keepLiteral
                  : ReviewAction.changeGeometry,
          replacements: old?.replacementCandidateIds ?? const []);
    }
    return _append(AssetReviewFrame._(
        candidates: candidates,
        visionProposals: frame.visionProposals,
        outputMode: outputMode,
        decisions: decisions,
        approvedCandidateHashes: const {},
        placementClaims: frame.placementClaims));
  }

  AssetReviewSession undo({required Sha256Hash expectedSessionHash}) {
    _expect(expectedSessionHash);
    _reviewRequire(canUndo && revision < 2147483647, 'review.undo.unavailable',
        'No earlier review frame');
    return _withHistory(frames, cursor - 1);
  }

  AssetReviewSession redo({required Sha256Hash expectedSessionHash}) {
    _expect(expectedSessionHash);
    _reviewRequire(canRedo && revision < 2147483647, 'review.redo.unavailable',
        'No later review frame');
    return _withHistory(frames, cursor + 1);
  }

  AssetReviewSession unionCandidates(
      {required ConverterId candidateId,
      required Sha256Hash expectedSessionHash,
      required List<AssetUnionInput> inputs,
      required String name,
      required AssetCategory category,
      ({int x, int y, AnchorConvention convention})? anchor}) {
    _expect(expectedSessionHash);
    _canAppend();
    _newIdentity(candidateId);
    _reviewRequire(
        inputs.length >= 2 &&
            inputs.length <= 64 &&
            frame.candidates.length < limits.maxCandidates,
        'review.union.inputs',
        'Union requires two or more bounded active candidates');
    _unique(inputs.map((input) => input.candidateId), r'$.union.inputs');
    final parents = <AssetCandidate>[];
    final parts = <Map<String, Object?>>[];
    final claims = <SourcePlacementClaim>[];
    final sources = <ConverterId, Map<String, Object?>>{};
    var width = 0;
    var height = 0;
    for (final input in inputs) {
      _reviewRequire(
          input.offsetX >= 0 &&
              input.offsetY >= 0 &&
              input.offsetX <= 2147483647 &&
              input.offsetY <= 2147483647,
          'review.union.offset',
          'Union requires explicit nonnegative canvas offsets');
      final parent = _candidate(input.candidateId, input.expectedCandidateHash);
      parents.add(parent);
      width = math.max(width, input.offsetX + parent.canvasSize.width);
      height = math.max(height, input.offsetY + parent.canvasSize.height);
      _reviewRequire(
          width <= 2147483647 &&
              height <= 2147483647 &&
              parts.length + parent.parts.length <= 4096,
          'review.union.quota',
          'Union geometry budget exceeded');
      for (final source in parent.sources) {
        final existing = sources[source.fileId];
        _reviewRequire(
            existing == null ||
                canonicalHashOf(existing) == canonicalHashOf(source.toJson()),
            'review.union.source',
            'Shared source image identity has contradictory metadata');
        sources[source.fileId] = source.toJson();
      }
      final partIds = <ConverterId, ConverterId>{};
      for (final part in parent.parts) {
        final id = ConverterId('union-part-${parts.length}');
        partIds[part.partId] = id;
        parts.add({
          ...part.toJson(),
          'partId': id.value,
          'destinationOffset': {
            'x': part.destinationOffset.x + input.offsetX,
            'y': part.destinationOffset.y + input.offsetY
          }
        });
      }
      for (final claim in frame.placementClaims[parent.candidateId] ??
          <SourcePlacementClaim>[]) {
        claims.add(claim.withPartId(partIds[claim.partId]!));
      }
    }
    final nextAnchor = anchor ??
        (
          x: width ~/ 2,
          y: height,
          convention: width.isEven
              ? AnchorConvention.bottomCenter
              : AnchorConvention.explicit
        );
    final child = _compositionCandidate(candidateId, parents.first,
        name: name,
        category: category,
        parts: parts,
        sources: sources.values.toList(),
        width: width,
        height: height,
        anchor: nextAnchor,
        evidenceReference:
            'review-union-sha256:${canonicalHashOf(parents.map((p) => p.canonicalHash.value).toList()).value}');
    _reviewPartsDisjoint(child.parts);
    return _supersede(parents, [child], {candidateId: claims});
  }

  AssetReviewSession splitCandidate(
      {required ConverterId candidateId,
      required Sha256Hash expectedCandidateHash,
      required Sha256Hash expectedSessionHash,
      required List<AssetSplitGroup> groups}) {
    _expect(expectedSessionHash);
    _canAppend();
    final parent = _candidate(candidateId, expectedCandidateHash);
    _reviewRequire(
        groups.length >= 2 &&
            groups.length <= 64 &&
            frame.candidates.length + groups.length <= limits.maxCandidates,
        'review.split.groups',
        'Split requires bounded distinct child groups');
    _unique(groups.map((group) => group.candidateId), r'$.split.groups');
    final assignment = <ConverterId, ConverterId>{};
    for (final group in groups) {
      _newIdentity(group.candidateId);
      for (final id in group.partIds) {
        _reviewRequire(!assignment.containsKey(id), 'review.split.duplicate',
            'A parent part cannot be assigned to two children');
        assignment[id] = group.candidateId;
      }
    }
    _reviewRequire(
        assignment.length == parent.parts.length &&
            parent.parts.every((part) => assignment.containsKey(part.partId)),
        'review.split.coverage',
        'Split must cover every parent part exactly once');
    final children = <AssetCandidate>[];
    final claims = <ConverterId, List<SourcePlacementClaim>>{};
    for (final group in groups) {
      final selected = parent.parts
          .where((part) => assignment[part.partId] == group.candidateId)
          .toList();
      var minX = selected.first.destinationOffset.x;
      var minY = selected.first.destinationOffset.y;
      var maxX = minX;
      var maxY = minY;
      final sourceIds = <ConverterId>{};
      for (final part in selected) {
        minX = math.min(minX, part.destinationOffset.x);
        minY = math.min(minY, part.destinationOffset.y);
        maxX = math.max(
            maxX,
            part.destinationOffset.x +
                (part.quarterTurns.isOdd
                    ? part.sourceRect.height
                    : part.sourceRect.width));
        maxY = math.max(
            maxY,
            part.destinationOffset.y +
                (part.quarterTurns.isOdd
                    ? part.sourceRect.width
                    : part.sourceRect.height));
        sourceIds.add(part.sourceFileId);
      }
      final width = maxX - minX;
      final height = maxY - minY;
      final childAnchor = group.anchor ??
          (
            x: (parent.anchor.x - minX).clamp(0, width).toInt(),
            y: (parent.anchor.y - minY).clamp(0, height).toInt(),
            convention: AnchorConvention.explicit
          );
      final parts = [
        for (final part in selected)
          {
            ...part.toJson(),
            'destinationOffset': {
              'x': part.destinationOffset.x - minX,
              'y': part.destinationOffset.y - minY
            }
          }
      ];
      final child = _compositionCandidate(group.candidateId, parent,
          name: group.name,
          category: group.category,
          parts: parts,
          sources: parent.sources
              .where((source) => sourceIds.contains(source.fileId))
              .map((source) => source.toJson())
              .toList(),
          width: width,
          height: height,
          anchor: childAnchor,
          evidenceReference:
              'review-split-sha256:${parent.canonicalHash.value}');
      children.add(child);
      claims[group.candidateId] = [
        for (final claim in frame.placementClaims[parent.candidateId] ??
            <SourcePlacementClaim>[])
          if (assignment[claim.partId] == group.candidateId) claim
      ];
    }
    return _supersede([parent], children, claims);
  }

  AssetCandidate _compositionCandidate(ConverterId id, AssetCandidate source,
          {required String name,
          required AssetCategory category,
          required List<Map<String, Object?>> parts,
          required List<Map<String, Object?>> sources,
          required int width,
          required int height,
          required ({int x, int y, AnchorConvention convention}) anchor,
          required String evidenceReference}) =>
      AssetCandidate.fromJson({
        ...source.toJson(),
        'candidateId': id.value,
        'revision': 1,
        'name': _reviewName(name),
        'category': category.name,
        'state': 'needsReview',
        'approvedRevision': null,
        'integrationMode': 'libraryOnly',
        'sources': sources,
        'parts': parts,
        'canvasSize': {'width': width, 'height': height},
        'anchor': {
          'unit': 'pixel',
          'x': anchor.x,
          'y': anchor.y,
          'convention': anchor.convention.name
        },
        'evidence': [
          {
            'type': 'human',
            'summary':
                'Explicit local composition; new geometry and anchor require approval.',
            'reference': evidenceReference
          }
        ],
        'uncertainties': [
          'Composition identity, geometry and rebased anchor require fresh human review.',
          'Native placement replacement is not certified.'
        ],
      }, limits: limits.jsonLimits);

  AssetReviewSession _supersede(
      List<AssetCandidate> parents,
      List<AssetCandidate> children,
      Map<ConverterId, List<SourcePlacementClaim>> childClaims) {
    final parentIds = parents.map((parent) => parent.candidateId).toSet();
    final replacements = children.map((child) => child.candidateId).toList();
    final decisions = {...frame.decisions};
    final approvals = {...frame.approvedCandidateHashes};
    final candidates = <AssetCandidate>[];
    for (final candidate in frame.candidates) {
      if (!parentIds.contains(candidate.candidateId)) {
        candidates.add(candidate);
        continue;
      }
      final next = _changed(candidate, {'state': 'superseded'});
      candidates.add(next);
      decisions[next.candidateId] =
          _decision(next, ReviewAction.supersede, replacements: replacements);
      approvals.remove(next.candidateId);
    }
    candidates.addAll(children);
    return _append(AssetReviewFrame._(
        candidates: candidates,
        visionProposals: frame.visionProposals,
        outputMode: outputMode,
        decisions: decisions,
        approvedCandidateHashes: approvals,
        placementClaims: {...frame.placementClaims, ...childClaims}));
  }
}

void _validateReviewClaims(AssetCandidate candidate,
    List<SourcePlacementClaim> claims, List<SourceMapIr> sourceMaps) {
  _unique(sourceMaps.map((map) => map.map.sourceMapId), r'$.sourceMaps');
  final maps = {for (final map in sourceMaps) map.map.sourceMapId: map};
  for (final claim in claims) {
    final map = maps[claim.sourceMapId];
    _reviewRequire(map != null, 'review.claim.map',
        'Placement map is unavailable for validation');
    claim.validateAgainst(map!, candidate);
  }
}

void _reviewRequire(bool condition, String code, String message) =>
    _require(condition, code, r'$', message);

void _reviewPartsDisjoint(List<AssetPart> parts) {
  for (var i = 0; i < parts.length; i++) {
    final a = parts[i];
    final width =
        a.quarterTurns.isOdd ? a.sourceRect.height : a.sourceRect.width;
    final height =
        a.quarterTurns.isOdd ? a.sourceRect.width : a.sourceRect.height;
    for (var j = i + 1; j < parts.length; j++) {
      final b = parts[j];
      final otherWidth =
          b.quarterTurns.isOdd ? b.sourceRect.height : b.sourceRect.width;
      final otherHeight =
          b.quarterTurns.isOdd ? b.sourceRect.width : b.sourceRect.height;
      _reviewRequire(
          a.destinationOffset.x >= b.destinationOffset.x + otherWidth ||
              b.destinationOffset.x >= a.destinationOffset.x + width ||
              a.destinationOffset.y >= b.destinationOffset.y + otherHeight ||
              b.destinationOffset.y >= a.destinationOffset.y + height,
          'review.union.overlap',
          'Union cannot silently overlap explicit source parts');
    }
  }
}

Map<String, Object?> _reviewObject(Object? input) {
  _reviewRequire(input is Map<String, Object?>, 'review.document.object',
      'Expected an inert JSON object');
  return input as Map<String, Object?>;
}

List<Object?> _reviewList(Object? input) {
  _reviewRequire(
      input is List, 'review.document.list', 'Expected an inert JSON array');
  return (input as List).cast<Object?>();
}

String _reviewString(Object? input) {
  _reviewRequire(
      input is String, 'review.document.string', 'Expected a string');
  return input as String;
}

int _reviewInt(Object? input) {
  _reviewRequire(
      input is int, 'review.document.integer', 'Expected an integer');
  return input as int;
}

void _reviewKeys(Map<String, Object?> json, Set<String> keys) => _reviewRequire(
    json.length == keys.length && json.keys.every(keys.contains),
    'review.document.keys',
    'Unknown or missing review document fields');
Map<ConverterId, Sha256Hash> _reviewHashMap(Object? input) => {
      for (final entry in _reviewObject(input).entries)
        ConverterId(entry.key): Sha256Hash(_reviewString(entry.value)),
    };
AssetOutputMode _reviewOutputMode(Object? input) {
  final name = _reviewString(input);
  _reviewRequire(AssetOutputMode.values.any((mode) => mode.name == name),
      'review.output.mode', 'Unknown output mode');
  return AssetOutputMode.values.byName(name);
}

String _reviewName(String name) {
  _reviewRequire(
      name.trim().isNotEmpty && name.length <= 256 && !name.contains('\u0000'),
      'review.name',
      'Candidate name must be nonempty and bounded');
  return name.trim();
}
