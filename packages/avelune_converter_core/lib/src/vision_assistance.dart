part of '../avelune_converter_core.dart';

final class VisionLimits {
  const VisionLimits(
      {this.maxCrops = 8,
      this.maxImageBytes = 2097152,
      this.maxTotalImageBytes = 8388608,
      this.maxPixels = 4194304,
      this.maxSuggestions = 32,
      this.maxProposals = 128,
      this.jsonLimits = const ContractLimits()});
  final int maxCrops;
  final int maxImageBytes;
  final int maxTotalImageBytes;
  final int maxPixels;
  final int maxSuggestions;
  final int maxProposals;
  final ContractLimits jsonLimits;
}

final class VisionCrop {
  factory VisionCrop(
      {required ConverterId regionId,
      required ConverterId fileId,
      required Sha256Hash sourceHash,
      required Map<String, Object?> sourceRect,
      required List<int> pngBytes,
      required int transmittedWidth,
      required int transmittedHeight,
      int quarterTurns = 0,
      bool reflected = false,
      String transformVersion = '1'}) {
    _reviewRequire(pngBytes.length >= 33 && pngBytes.length <= 2097152,
        'vision.crop.bytes', 'PNG byte budget exceeded or header missing');
    _reviewRequire(pngBytes.every((b) => b >= 0 && b <= 255),
        'vision.crop.bytes', 'PNG must contain bytes');
    final bytes = List<int>.unmodifiable(pngBytes);
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    _reviewRequire(
        List.generate(8, (i) => bytes[i] == signature[i]).every((v) => v) &&
            bytes[8] == 0 &&
            bytes[9] == 0 &&
            bytes[10] == 0 &&
            bytes[11] == 13 &&
            ascii.decode(bytes.sublist(12, 16), allowInvalid: true) == 'IHDR',
        'vision.crop.png',
        'Expected a PNG with an IHDR header');
    int dimension(int offset) =>
        bytes[offset] * 16777216 +
        bytes[offset + 1] * 65536 +
        bytes[offset + 2] * 256 +
        bytes[offset + 3];
    _reviewRequire(
        dimension(16) == transmittedWidth && dimension(20) == transmittedHeight,
        'vision.crop.dimensions',
        'PNG header differs from transmitted dimensions');
    final rect = _reviewObject(_freezeJson(sourceRect, const ContractLimits()));
    final value = VisionCrop._(
        regionId: regionId,
        fileId: fileId,
        sourceHash: sourceHash,
        sourceRect: rect,
        pngBytes: bytes,
        transmittedWidth: transmittedWidth,
        transmittedHeight: transmittedHeight,
        quarterTurns: quarterTurns,
        reflected: reflected,
        transformVersion: transformVersion);
    _visionCropMetadata(value.toJson(), const VisionLimits());
    return value;
  }
  VisionCrop._(
      {required this.regionId,
      required this.fileId,
      required this.sourceHash,
      required this.sourceRect,
      required this.pngBytes,
      required this.transmittedWidth,
      required this.transmittedHeight,
      required this.quarterTurns,
      required this.reflected,
      required this.transformVersion});
  final ConverterId regionId;
  final ConverterId fileId;
  final Sha256Hash sourceHash;
  final Map<String, Object?> sourceRect;
  final List<int> pngBytes;
  final int transmittedWidth;
  final int transmittedHeight;
  final int quarterTurns;
  final bool reflected;
  final String transformVersion;
  late final Sha256Hash byteHash =
      Sha256Hash(sha256.convert(pngBytes).toString());
  Map<String, Object?> toJson() => {
        'regionId': regionId.value,
        'fileId': fileId.value,
        'sourceHash': sourceHash.value,
        'sourceRect': sourceRect,
        'byteHash': byteHash.value,
        'byteLength': pngBytes.length,
        'transmittedWidth': transmittedWidth,
        'transmittedHeight': transmittedHeight,
        'quarterTurns': quarterTurns,
        'reflected': reflected,
        'transformVersion': transformVersion,
      };
}

void _visionCropMetadata(Map<String, Object?> value, VisionLimits limits) {
  _reviewKeys(value, const {
    'regionId',
    'fileId',
    'sourceHash',
    'sourceRect',
    'byteHash',
    'byteLength',
    'transmittedWidth',
    'transmittedHeight',
    'quarterTurns',
    'reflected',
    'transformVersion'
  });
  ConverterId(_reviewString(value['regionId']));
  ConverterId(_reviewString(value['fileId']));
  Sha256Hash(_reviewString(value['sourceHash']));
  Sha256Hash(_reviewString(value['byteHash']));
  final rect = _reviewObject(value['sourceRect']);
  _reviewKeys(rect, const {'x', 'y', 'width', 'height'});
  final x = _reviewInt(rect['x']);
  final y = _reviewInt(rect['y']);
  final width = _reviewInt(rect['width']);
  final height = _reviewInt(rect['height']);
  final turns = _reviewInt(value['quarterTurns']);
  final transmittedWidth = _reviewInt(value['transmittedWidth']);
  final transmittedHeight = _reviewInt(value['transmittedHeight']);
  _reviewRequire(
      x >= 0 &&
          y >= 0 &&
          x <= 2147483647 &&
          y <= 2147483647 &&
          width > 0 &&
          height > 0 &&
          width * height <= limits.maxPixels &&
          turns >= 0 &&
          turns <= 3 &&
          value['reflected'] is bool &&
          value['transformVersion'] == '1' &&
          transmittedWidth == (turns.isOdd ? height : width) &&
          transmittedHeight == (turns.isOdd ? width : height) &&
          _reviewInt(value['byteLength']) >= 33 &&
          _reviewInt(value['byteLength']) <= limits.maxImageBytes,
      'vision.crop.geometry',
      'Crop geometry or transform is unsupported or exceeds its budget');
}

final class VisionMaterial {
  VisionMaterial(
      {required this.context,
      required this.expectedSessionHash,
      required Map<ConverterId, Sha256Hash> candidateHashes,
      required List<VisionCrop> crops,
      this.provider = 'openai',
      required this.model,
      required this.promptVersion,
      this.schemaVersion = '1.0',
      Map<String, Object?> options = const {},
      this.limits = const VisionLimits()})
      : candidateHashes = Map.unmodifiable(candidateHashes),
        crops = List.unmodifiable(crops),
        options = _visionOptions(options) {
    _visionLimits(_visionLimitsJson(limits));
    _reviewRequire(provider == 'openai' && schemaVersion == '1.0',
        'vision.provider', 'Unsupported vision provider or response schema');
    ConverterId(model);
    ConverterId(promptVersion);
    _reviewRequire(crops.isNotEmpty && crops.length <= limits.maxCrops,
        'vision.crops.quota', 'Crop selection exceeds its budget');
    _unique(crops.map((c) => c.regionId), r'$.crops');
    var bytes = 0;
    var pixels = 0;
    for (final crop in crops) {
      _visionCropMetadata(crop.toJson(), limits);
      bytes += crop.pngBytes.length;
      pixels += crop.transmittedWidth * crop.transmittedHeight;
    }
    _reviewRequire(
        bytes <= limits.maxTotalImageBytes && pixels <= limits.maxPixels,
        'vision.material.quota',
        'Image byte or pixel budget exceeded');
    _visionMaterialMetadata(toJson());
    _freezeJson(toJson(), limits.jsonLimits);
  }
  final VisionRequestContext context;
  final Sha256Hash expectedSessionHash;
  final Map<ConverterId, Sha256Hash> candidateHashes;
  final List<VisionCrop> crops;
  final String provider;
  final String model;
  final String promptVersion;
  final String schemaVersion;
  final Map<String, Object?> options;
  final VisionLimits limits;
  late final Sha256Hash canonicalHash =
      canonicalHashOf(toJson(), limits: limits.jsonLimits);
  late final Sha256Hash selectionHash = canonicalHashOf({
    'sourceSnapshotHash': context.sourceSnapshotHash.value,
    'candidateHashes': {
      for (final entry in candidateHashes.entries)
        entry.key.value: entry.value.value
    },
    'crops': crops.map((c) => c.toJson()).toList(),
  }, limits: limits.jsonLimits);
  Map<String, Object?> toJson() => {
        'context': _visionContextJson(context),
        'expectedSessionHash': expectedSessionHash.value,
        'candidateHashes': {
          for (final entry in candidateHashes.entries)
            entry.key.value: entry.value.value
        },
        'crops': crops.map((c) => c.toJson()).toList(),
        'provider': provider,
        'model': model,
        'promptVersion': promptVersion,
        'schemaVersion': schemaVersion,
        'options': options,
        'limits': _visionLimitsJson(limits),
      };
}

Map<String, Object?> _visionContextJson(VisionRequestContext context) => {
      'requestId': context.requestId.value,
      'sourceSnapshotHash': context.sourceSnapshotHash.value,
      'inputRevision': context.inputRevision,
      'candidateIds': context.candidateIds.map((id) => id.value).toList()
        ..sort(),
      'sourceRegionIds': context.sourceRegionIds.map((id) => id.value).toList()
        ..sort(),
    };

VisionRequestContext _visionContext(Object? input) {
  final json = _reviewObject(input);
  _reviewKeys(json, const {
    'requestId',
    'sourceSnapshotHash',
    'inputRevision',
    'candidateIds',
    'sourceRegionIds'
  });
  final candidates = _reviewList(json['candidateIds'])
      .map((id) => ConverterId(_reviewString(id)))
      .toList();
  final regions = _reviewList(json['sourceRegionIds'])
      .map((id) => ConverterId(_reviewString(id)))
      .toList();
  _unique(candidates, r'$.candidateIds');
  _unique(regions, r'$.sourceRegionIds');
  _reviewRequire(
      candidates.length <= 64 && regions.isNotEmpty && regions.length <= 8,
      'vision.context.quota',
      'Selection must be explicit and bounded');
  return VisionRequestContext(
      requestId: ConverterId(_reviewString(json['requestId'])),
      sourceSnapshotHash: Sha256Hash(_reviewString(json['sourceSnapshotHash'])),
      inputRevision: _reviewInt(json['inputRevision']),
      candidateIds: candidates.toSet(),
      sourceRegionIds: regions.toSet());
}

Map<String, Object?> _visionOptions(Map<String, Object?> input) {
  _reviewRequire(input.keys.every(const {'maxOutputTokens', 'detail'}.contains),
      'vision.options', 'Unknown provider option');
  final tokens = _reviewInt(input['maxOutputTokens'] ?? 2048);
  final detail = _reviewString(input['detail'] ?? 'high');
  _reviewRequire(
      tokens >= 1 &&
          tokens <= 8192 &&
          const {'low', 'high', 'original', 'auto'}.contains(detail),
      'vision.options',
      'Unsupported output token limit or image detail');
  return Map.unmodifiable({'maxOutputTokens': tokens, 'detail': detail});
}

Map<String, Object?> _visionLimitsJson(VisionLimits limits) => {
      'maxCrops': limits.maxCrops,
      'maxImageBytes': limits.maxImageBytes,
      'maxTotalImageBytes': limits.maxTotalImageBytes,
      'maxPixels': limits.maxPixels,
      'maxSuggestions': limits.maxSuggestions,
      'maxProposals': limits.maxProposals,
    };

VisionLimits _visionLimits(Object? input) {
  final json = _reviewObject(input);
  _reviewKeys(json, const {
    'maxCrops',
    'maxImageBytes',
    'maxTotalImageBytes',
    'maxPixels',
    'maxSuggestions',
    'maxProposals'
  });
  final defaults = _visionLimitsJson(const VisionLimits());
  for (final entry in json.entries) {
    final value = _reviewInt(entry.value);
    _reviewRequire(value > 0 && value <= _reviewInt(defaults[entry.key]),
        'vision.limits', 'Vision limits must be positive and bounded');
  }
  return VisionLimits(
      maxCrops: _reviewInt(json['maxCrops']),
      maxImageBytes: _reviewInt(json['maxImageBytes']),
      maxTotalImageBytes: _reviewInt(json['maxTotalImageBytes']),
      maxPixels: _reviewInt(json['maxPixels']),
      maxSuggestions: _reviewInt(json['maxSuggestions']),
      maxProposals: _reviewInt(json['maxProposals']));
}

void _visionMaterialMetadata(Map<String, Object?> json) {
  _reviewKeys(json, const {
    'context',
    'expectedSessionHash',
    'candidateHashes',
    'crops',
    'provider',
    'model',
    'promptVersion',
    'schemaVersion',
    'options',
    'limits'
  });
  final context = _visionContext(json['context']);
  Sha256Hash(_reviewString(json['expectedSessionHash']));
  _reviewRequire(json['provider'] == 'openai' && json['schemaVersion'] == '1.0',
      'vision.provider', 'Unsupported vision provider or response schema');
  ConverterId(_reviewString(json['model']));
  ConverterId(_reviewString(json['promptVersion']));
  final options = _reviewObject(json['options']);
  _reviewRequire(
      canonicalHashOf(options) == canonicalHashOf(_visionOptions(options)),
      'vision.options',
      'Material must declare its effective options');
  final limits = _visionLimits(json['limits']);
  final candidates = _reviewHashMap(json['candidateHashes']);
  final crops = _reviewList(json['crops']).map(_reviewObject).toList();
  _reviewRequire(
      crops.isNotEmpty &&
          crops.length <= limits.maxCrops &&
          candidates.length == context.candidateIds.length &&
          candidates.keys.every(context.candidateIds.contains),
      'vision.context.selection',
      'Candidate hashes differ from the exact requested selection');
  _unique(crops.map((c) => c['regionId']), r'$.crops');
  final regionIds =
      crops.map((c) => ConverterId(_reviewString(c['regionId']))).toSet();
  _reviewRequire(
      regionIds.length == context.sourceRegionIds.length &&
          regionIds.every(context.sourceRegionIds.contains),
      'vision.context.regions',
      'Crops differ from the exact requested regions');
  var bytes = 0;
  var pixels = 0;
  for (final crop in crops) {
    _visionCropMetadata(crop, limits);
    bytes += _reviewInt(crop['byteLength']);
    pixels += _reviewInt(crop['transmittedWidth']) *
        _reviewInt(crop['transmittedHeight']);
  }
  _reviewRequire(
      bytes <= limits.maxTotalImageBytes && pixels <= limits.maxPixels,
      'vision.material.quota',
      'Image byte or pixel budget exceeded');
}

List<SourceImage> _visionSelectedSources(
    Map<String, Object?> metadata, List<SourceImage> verifiedSources) {
  _reviewRequire(verifiedSources.length <= 4096, 'vision.sources.quota',
      'Source catalog exceeds its budget');
  final catalog = <ConverterId, SourceImage>{};
  for (final source in verifiedSources) {
    final previous = catalog[source.fileId];
    _reviewRequire(
        previous == null ||
            canonicalHashOf(previous.toJson()) ==
                canonicalHashOf(source.toJson()),
        'vision.sources.conflict',
        'Source catalog has contradictory definitions');
    catalog[source.fileId] = source;
  }
  final selected = <ConverterId, SourceImage>{};
  for (final raw in _reviewList(metadata['crops'])) {
    final crop = _reviewObject(raw);
    final id = ConverterId(_reviewString(crop['fileId']));
    final source = catalog[id];
    final rect = _reviewObject(crop['sourceRect']);
    _reviewRequire(
        source != null &&
            source.contentHash.value == crop['sourceHash'] &&
            _reviewInt(rect['x']) + _reviewInt(rect['width']) <=
                source.pixelWidth &&
            _reviewInt(rect['y']) + _reviewInt(rect['height']) <=
                source.pixelHeight,
        'vision.crop.source',
        'Crop differs from its verified source hash or bounds');
    selected[id] = source!;
  }
  return List.unmodifiable(selected.values);
}

final class VisionConsent {
  VisionConsent.grant(
      {required this.materialHash,
      required this.accountRevision,
      required bool humanConfirmed}) {
    _reviewRequire(humanConfirmed, 'vision.consent.required',
        'Exact material requires explicit human consent');
  }
  final Sha256Hash materialHash;
  final ConverterId accountRevision;
}

final class VisionRequest {
  VisionRequest(
      {required this.context, required this.material, required this.consent}) {
    _reviewRequire(
        consent.materialHash == material.canonicalHash &&
            canonicalHashOf(_visionContextJson(context)) ==
                canonicalHashOf(_visionContextJson(material.context)),
        'vision.consent.material',
        'Consent or context belongs to another exact material');
  }
  final VisionRequestContext context;
  final VisionMaterial material;
  final VisionConsent consent;
}

final class VisionLiveContext {
  const VisionLiveContext(
      {required this.sourceVerified,
      required this.sourceSnapshotHash,
      required this.sessionHash,
      required this.selectionHash,
      required this.inputRevision,
      required this.accountRevision});
  final bool sourceVerified;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash sessionHash;
  final Sha256Hash selectionHash;
  final int inputRevision;
  final ConverterId accountRevision;
}

void validateVisionDispatch(VisionRequest request, VisionLiveContext live) {
  _reviewRequire(
      live.sourceVerified &&
          live.sourceSnapshotHash == request.context.sourceSnapshotHash &&
          live.sessionHash == request.material.expectedSessionHash &&
          live.selectionHash == request.material.selectionHash &&
          live.inputRevision == request.context.inputRevision &&
          live.accountRevision == request.consent.accountRevision &&
          request.consent.materialHash == request.material.canonicalHash,
      'vision.live.changed',
      'Source, selection, review or account changed before this operation');
}

void validateVisionResult(
    VisionResponse response, VisionRequest request, VisionLiveContext live) {
  validateVisionDispatch(request, live);
  validateVisionResponse(response, request.context);
  _reviewRequire(
      response.suggestions.length <= request.material.limits.maxSuggestions,
      'vision.result.quota',
      'Suggestion budget exceeded');
}

final class FakeVisionPort implements VisionPort {
  FakeVisionPort({this.response, this.error, this.gate});
  final VisionResponse? response;
  final Object? error;
  final Future<void>? gate;
  final List<VisionRequest> _requests = [];
  List<VisionRequest> get requests => List.unmodifiable(_requests);
  @override
  Future<VisionResponse> suggest(VisionRequest request,
      {ScanCancellation? cancellation}) async {
    cancellation?.check();
    _requests.add(request);
    await gate;
    cancellation?.check();
    if (error case final failure?) throw failure;
    return response ??
        (throw StateError('A fake response or error must be configured'));
  }
}

final class VisionReviewProposal {
  VisionReviewProposal._(
      {required this.proposalId,
      required this.suggestion,
      required this.materialHash,
      required this.materialMetadata,
      required this.verifiedSources});

  factory VisionReviewProposal._create(VisionSuggestion suggestion,
          VisionMaterial material, List<SourceImage> sources) =>
      VisionReviewProposal._fromJson({
        'proposalId':
            _visionProposalId(material.canonicalHash, suggestion).value,
        'state': 'needsReview',
        'materialHash': material.canonicalHash.value,
        'materialMetadata': material.toJson(),
        'verifiedSources': sources.map((s) => s.toJson()).toList(),
        'suggestion': suggestion.toJson(),
      });

  factory VisionReviewProposal._fromJson(Object? input) {
    final json = _reviewObject(_freezeJson(input, const ContractLimits()));
    _reviewKeys(json, const {
      'proposalId',
      'state',
      'materialHash',
      'materialMetadata',
      'verifiedSources',
      'suggestion'
    });
    _reviewRequire(json['state'] == 'needsReview', 'vision.proposal.state',
        'An AI suggestion cannot carry an approval');
    final metadata = _reviewObject(json['materialMetadata']);
    _visionMaterialMetadata(metadata);
    final hash = Sha256Hash(_reviewString(json['materialHash']));
    _reviewRequire(hash == canonicalHashOf(metadata), 'vision.proposal.hash',
        'Material provenance differs from its exact hash');
    final context = _visionContext(metadata['context']);
    final response = VisionResponse.fromJson({
      'schemaVersion': '1.0',
      'kind': 'visionResponse',
      'exampleOnly': false,
      'requestId': context.requestId.value,
      'sourceSnapshotHash': context.sourceSnapshotHash.value,
      'inputRevision': context.inputRevision,
      'suggestions': [json['suggestion']],
    });
    validateVisionResponse(response, context);
    final suggestion = response.suggestions.single;
    final id = ConverterId(_reviewString(json['proposalId']));
    _reviewRequire(
        id == _visionProposalId(hash, suggestion),
        'vision.proposal.identity',
        'Proposal identity differs from its material and suggestion');
    final sourceJson = _reviewList(json['verifiedSources']);
    _reviewRequire(
        sourceJson.isNotEmpty && sourceJson.length <= 8,
        'vision.sources.quota',
        'Persisted proposal source catalog exceeds its budget');
    final sources = sourceJson.map(SourceImage.fromJson).toList();
    _unique(sources.map((s) => s.fileId), r'$.verifiedSources');
    final selected = _visionSelectedSources(metadata, sources);
    _reviewRequire(
        selected.length == sources.length,
        'vision.sources.reference',
        'Persisted proposal contains unrequested source definitions');
    return VisionReviewProposal._(
        proposalId: id,
        suggestion: suggestion,
        materialHash: hash,
        materialMetadata: metadata,
        verifiedSources: List.unmodifiable(sources));
  }

  final ConverterId proposalId;
  final VisionSuggestion suggestion;
  final Sha256Hash materialHash;
  final Map<String, Object?> materialMetadata;
  final List<SourceImage> verifiedSources;
  CandidateState get state => CandidateState.needsReview;
  String get provider => materialMetadata['provider'] as String;
  String get model => materialMetadata['model'] as String;
  String get promptVersion => materialMetadata['promptVersion'] as String;
  Sha256Hash get sourceSnapshotHash =>
      _visionContext(materialMetadata['context']).sourceSnapshotHash;
  Map<ConverterId, Sha256Hash> get candidateHashes =>
      Map.unmodifiable(_reviewHashMap(materialMetadata['candidateHashes']));
  List<Map<String, Object?>> get sourceRegions => List.unmodifiable(
      _reviewList(materialMetadata['crops']).map(_reviewObject));
  Map<String, Object?> toJson() => {
        'proposalId': proposalId.value,
        'state': state.name,
        'materialHash': materialHash.value,
        'materialMetadata': materialMetadata,
        'verifiedSources': verifiedSources.map((s) => s.toJson()).toList(),
        'suggestion': suggestion.toJson(),
      };
}

ConverterId _visionProposalId(
        Sha256Hash materialHash, VisionSuggestion suggestion) =>
    ConverterId('vision-${canonicalHashOf({
          'materialHash': materialHash.value,
          'suggestion': suggestion.toJson()
        }).value}');
