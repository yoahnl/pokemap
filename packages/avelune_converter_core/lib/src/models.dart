part of '../avelune_converter_core.dart';

enum CapabilityStatus { unverified, supported, partial, unsupported }

enum EvidenceType {
  formatMetadata,
  alphaRegion,
  repeatedPlacement,
  human,
  aiSuggestion,
  test,
  codeRead
}

enum ReviewAction {
  approve,
  keepLiteral,
  rename,
  reclassify,
  changeGeometry,
  supersede
}

enum AssetCategory {
  building,
  nature,
  object,
  terrain,
  surface,
  character,
  animation,
  unclassified
}

enum CandidateState {
  proposed,
  needsReview,
  approved,
  keepLiteral,
  conflicted,
  superseded
}

enum AnchorConvention { topLeft, bottomLeft, bottomCenter, explicit }

enum IntegrationMode { libraryOnly, replacePlacements }

enum AssetOutputMode { sharedAtlas, standaloneObjects, packedObjects }

enum PlanState { draft, ready, stale, applied }

enum ConversionMode { study, playableSlice }

enum OperationDomain { project, assets, maps, events, catalogs }

enum OperationStatus { planned, blocked, excluded }

enum DiagnosticSeverity { info, warning, error }

enum DiagnosticCause {
  sourceInvalid,
  converterUnsupported,
  targetUnsupported,
  ambiguous,
  security,
  policy
}

enum DiagnosticFamily {
  files,
  maps,
  assets,
  animation,
  rendering,
  collision,
  events,
  catalogs,
  publication,
  ai
}

enum DiagnosticDisposition {
  unresolved,
  preservedOnly,
  excluded,
  adapted,
  acceptedStudyLoss,
  resolved
}

enum ConfidenceLabel { low, medium, high, unknown }

enum ReportScope { inventory, study, playableSlice }

enum ReportState {
  analyzed,
  planned,
  writing,
  verified,
  published,
  failed,
  cancelled
}

enum CheckStatus { notRun, passed, failed, notApplicable }

enum AiUsageStatus { notUsed, reported, estimated, unknown }

sealed class ConverterDocument extends _JsonRecord {
  ConverterDocument._(super.json);

  String get schemaVersion => _json['schemaVersion'] as String;
  String get kind => _json['kind'] as String;
  bool get exampleOnly => _json['exampleOnly'] as bool;
  Sha256Hash get canonicalHash => canonicalHashOf(_json);
}

final class TargetCapabilities extends ConverterDocument {
  TargetCapabilities._(super.json) : super._();

  factory TargetCapabilities.fromJson(Object? input,
          {ContractLimits limits = const ContractLimits()}) =>
      _readContract(input, 'targetCapabilities', limits) as TargetCapabilities;

  ConverterId get profileId => ConverterId(_json['profileId'] as String);

  String get repository => _json['repository'] as String;

  String get revision => _json['revision'] as String;

  List<TargetCapability> get capabilities =>
      List<TargetCapability>.unmodifiable((_json['capabilities'] as List)
          .map((value) => TargetCapability._(value as Map<String, Object?>)));
}

final class TargetCapability extends _JsonRecord {
  TargetCapability._(super.json);

  ConverterId get capabilityId => ConverterId(_json['capabilityId'] as String);

  CapabilityStatus get status =>
      CapabilityStatus.values.byName(_json['status'] as String);

  String get scope => _json['scope'] as String;

  List<ContractEvidence> get evidence =>
      List<ContractEvidence>.unmodifiable((_json['evidence'] as List)
          .map((value) => ContractEvidence._(value as Map<String, Object?>)));

  List<String> get limitations => List<String>.unmodifiable(
      (_json['limitations'] as List).map((value) => value as String));
}

final class ContractEvidence extends _JsonRecord {
  ContractEvidence._(super.json);

  EvidenceType get type => EvidenceType.values.byName(_json['type'] as String);

  String get summary => _json['summary'] as String;

  String get reference => _json['reference'] as String;
}

final class ReviewDecisions extends ConverterDocument {
  ReviewDecisions._(super.json) : super._();

  factory ReviewDecisions.fromJson(Object? input,
          {ContractLimits limits = const ContractLimits()}) =>
      _readContract(input, 'reviewDecisions', limits) as ReviewDecisions;

  ConverterId get sessionId => ConverterId(_json['sessionId'] as String);

  Sha256Hash get sourceSnapshotHash =>
      Sha256Hash(_json['sourceSnapshotHash'] as String);

  int get revision => _json['revision'] as int;

  List<ReviewDecision> get decisions =>
      List<ReviewDecision>.unmodifiable((_json['decisions'] as List)
          .map((value) => ReviewDecision._(value as Map<String, Object?>)));
}

final class ReviewDecision extends _JsonRecord {
  ReviewDecision._(super.json);

  ConverterId get decisionId => ConverterId(_json['decisionId'] as String);

  ConverterId get candidateId => ConverterId(_json['candidateId'] as String);

  int get candidateRevision => _json['candidateRevision'] as int;

  ReviewAction get action =>
      ReviewAction.values.byName(_json['action'] as String);

  bool get humanConfirmed => _json['humanConfirmed'] as bool;

  List<ConverterId> get replacementCandidateIds =>
      List<ConverterId>.unmodifiable((_json['replacementCandidateIds'] as List)
          .map((value) => ConverterId(value as String)));

  String get note => _json['note'] as String;
}

final class AssetCandidate extends ConverterDocument {
  AssetCandidate._(super.json) : super._();

  factory AssetCandidate.fromJson(Object? input,
          {ContractLimits limits = const ContractLimits()}) =>
      _readContract(input, 'assetCandidate', limits) as AssetCandidate;

  ConverterId get candidateId => ConverterId(_json['candidateId'] as String);

  int get revision => _json['revision'] as int;

  ConverterId get logicalProjectNamespace =>
      ConverterId(_json['logicalProjectNamespace'] as String);

  Sha256Hash get sourceSnapshotHash =>
      Sha256Hash(_json['sourceSnapshotHash'] as String);

  List<SourceImage> get sources =>
      List<SourceImage>.unmodifiable((_json['sources'] as List)
          .map((value) => SourceImage._(value as Map<String, Object?>)));

  String get name => _json['name'] as String;

  AssetCategory get category =>
      AssetCategory.values.byName(_json['category'] as String);

  CandidateState get state =>
      CandidateState.values.byName(_json['state'] as String);

  List<AssetPart> get parts =>
      List<AssetPart>.unmodifiable((_json['parts'] as List)
          .map((value) => AssetPart._(value as Map<String, Object?>)));

  PixelSize get canvasSize =>
      PixelSize._(_json['canvasSize'] as Map<String, Object?>);

  PixelAnchor get anchor =>
      PixelAnchor._(_json['anchor'] as Map<String, Object?>);

  IntegrationMode get integrationMode =>
      IntegrationMode.values.byName(_json['integrationMode'] as String);

  AssetOutputMode get outputMode =>
      AssetOutputMode.values.byName(_json['outputMode'] as String);

  List<ContractEvidence> get evidence =>
      List<ContractEvidence>.unmodifiable((_json['evidence'] as List)
          .map((value) => ContractEvidence._(value as Map<String, Object?>)));

  List<String> get uncertainties => List<String>.unmodifiable(
      (_json['uncertainties'] as List).map((value) => value as String));

  int? get approvedRevision => _json['approvedRevision'] == null
      ? null
      : _json['approvedRevision'] as int;
}

final class SourceImage extends _JsonRecord {
  SourceImage._(super.json);

  ConverterId get fileId => ConverterId(_json['fileId'] as String);

  Sha256Hash get contentHash => Sha256Hash(_json['contentHash'] as String);

  int get pixelWidth => _json['pixelWidth'] as int;

  int get pixelHeight => _json['pixelHeight'] as int;
}

final class AssetPart extends _JsonRecord {
  AssetPart._(super.json);

  ConverterId get partId => ConverterId(_json['partId'] as String);

  ConverterId get sourceFileId => ConverterId(_json['sourceFileId'] as String);

  PixelRect get sourceRect =>
      PixelRect._(_json['sourceRect'] as Map<String, Object?>);

  PixelOffset get destinationOffset =>
      PixelOffset._(_json['destinationOffset'] as Map<String, Object?>);

  int? get sourceLayer =>
      _json['sourceLayer'] == null ? null : _json['sourceLayer'] as int;

  int? get sourcePriority =>
      _json['sourcePriority'] == null ? null : _json['sourcePriority'] as int;

  int get quarterTurns => _json['quarterTurns'] as int;

  bool get reflected => _json['reflected'] as bool;

  SourceLocator get locator =>
      SourceLocator._(_json['locator'] as Map<String, Object?>);
}

final class PixelRect extends _JsonRecord {
  PixelRect._(super.json);

  int get x => _json['x'] as int;

  int get y => _json['y'] as int;

  int get width => _json['width'] as int;

  int get height => _json['height'] as int;
}

final class PixelOffset extends _JsonRecord {
  PixelOffset._(super.json);

  int get x => _json['x'] as int;

  int get y => _json['y'] as int;
}

final class SourceLocator extends _JsonRecord {
  SourceLocator._(super.json);

  String get file => _json['file'] as String;

  int? get mapId => _json['mapId'] == null ? null : _json['mapId'] as int;

  int? get eventId => _json['eventId'] == null ? null : _json['eventId'] as int;

  int? get pageIndex =>
      _json['pageIndex'] == null ? null : _json['pageIndex'] as int;

  int? get commandIndex =>
      _json['commandIndex'] == null ? null : _json['commandIndex'] as int;

  int? get tileId => _json['tileId'] == null ? null : _json['tileId'] as int;

  int? get line => _json['line'] == null ? null : _json['line'] as int;
}

final class PixelSize extends _JsonRecord {
  PixelSize._(super.json);

  int get width => _json['width'] as int;

  int get height => _json['height'] as int;
}

final class PixelAnchor extends _JsonRecord {
  PixelAnchor._(super.json);

  String get unit => _json['unit'] as String;

  int get x => _json['x'] as int;

  int get y => _json['y'] as int;

  AnchorConvention get convention =>
      AnchorConvention.values.byName(_json['convention'] as String);
}

final class SourceMapIr extends ConverterDocument {
  SourceMapIr._(super.json) : super._();

  factory SourceMapIr.fromJson(Object? input,
          {ContractLimits limits = const ContractLimits()}) =>
      _readContract(input, 'sourceMapIr', limits) as SourceMapIr;

  ConverterId get logicalProjectNamespace =>
      ConverterId(_json['logicalProjectNamespace'] as String);

  Sha256Hash get sourceSnapshotHash =>
      Sha256Hash(_json['sourceSnapshotHash'] as String);

  ConverterId get sourceProfileId =>
      ConverterId(_json['sourceProfileId'] as String);

  SourceMapData get map =>
      SourceMapData._(_json['map'] as Map<String, Object?>);
}

final class SourceMapData extends _JsonRecord {
  SourceMapData._(super.json);

  int get sourceMapId => _json['sourceMapId'] as int;

  ConverterId get sourceFileId => ConverterId(_json['sourceFileId'] as String);

  String get name => _json['name'] as String;

  int get width => _json['width'] as int;

  int get height => _json['height'] as int;

  int get tileWidth => _json['tileWidth'] as int;

  int get tileHeight => _json['tileHeight'] as int;

  int get sourceTilesetId => _json['sourceTilesetId'] as int;

  List<SourceTileLayer> get layers =>
      List<SourceTileLayer>.unmodifiable((_json['layers'] as List)
          .map((value) => SourceTileLayer._(value as Map<String, Object?>)));

  List<SourceEvent> get events =>
      List<SourceEvent>.unmodifiable((_json['events'] as List)
          .map((value) => SourceEvent._(value as Map<String, Object?>)));

  List<ConverterId> get unknownDataRefs =>
      List<ConverterId>.unmodifiable((_json['unknownDataRefs'] as List)
          .map((value) => ConverterId(value as String)));
}

final class SourceTileLayer extends _JsonRecord {
  SourceTileLayer._(super.json);

  int get sourceZ => _json['sourceZ'] as int;

  List<int> get cells => List<int>.unmodifiable(
      (_json['cells'] as List).map((value) => value as int));
}

final class SourceEvent extends _JsonRecord {
  SourceEvent._(super.json);

  int get sourceEventId => _json['sourceEventId'] as int;

  String get name => _json['name'] as String;

  int get x => _json['x'] as int;

  int get y => _json['y'] as int;

  List<SourceEventPage> get pages =>
      List<SourceEventPage>.unmodifiable((_json['pages'] as List)
          .map((value) => SourceEventPage._(value as Map<String, Object?>)));
}

final class SourceEventPage extends _JsonRecord {
  SourceEventPage._(super.json);

  int get originalPageIndex => _json['originalPageIndex'] as int;

  ConverterId? get conditionsDataRef => _json['conditionsDataRef'] == null
      ? null
      : ConverterId(_json['conditionsDataRef'] as String);

  int get triggerCode => _json['triggerCode'] as int;

  List<SourceCommand> get commands =>
      List<SourceCommand>.unmodifiable((_json['commands'] as List)
          .map((value) => SourceCommand._(value as Map<String, Object?>)));

  ConverterId? get rawDataRef => _json['rawDataRef'] == null
      ? null
      : ConverterId(_json['rawDataRef'] as String);
}

final class SourceCommand extends _JsonRecord {
  SourceCommand._(super.json);

  int get originalIndex => _json['originalIndex'] as int;

  int get code => _json['code'] as int;

  int get indent => _json['indent'] as int;

  List<Object?> get parameters => List<Object?>.unmodifiable(
      (_json['parameters'] as List).map((value) => value));

  SourceLocator get sourceLocator =>
      SourceLocator._(_json['sourceLocator'] as Map<String, Object?>);
}

final class ConversionPlan extends ConverterDocument {
  ConversionPlan._(super.json) : super._();

  factory ConversionPlan.fromJson(Object? input,
          {ContractLimits limits = const ContractLimits()}) =>
      _readContract(input, 'conversionPlan', limits) as ConversionPlan;

  ConverterId get planId => ConverterId(_json['planId'] as String);

  PlanState get state => PlanState.values.byName(_json['state'] as String);

  Sha256Hash get sourceSnapshotHash =>
      Sha256Hash(_json['sourceSnapshotHash'] as String);

  Sha256Hash get targetProfileHash =>
      Sha256Hash(_json['targetProfileHash'] as String);

  Sha256Hash get rulesHash => Sha256Hash(_json['rulesHash'] as String);

  Sha256Hash get decisionsHash => Sha256Hash(_json['decisionsHash'] as String);

  int get decisionRevision => _json['decisionRevision'] as int;

  String get converterVersion => _json['converterVersion'] as String;

  ConverterId get logicalProjectNamespace =>
      ConverterId(_json['logicalProjectNamespace'] as String);

  ConversionMode get requestedMode =>
      ConversionMode.values.byName(_json['requestedMode'] as String);

  List<int> get selectedSourceMapIds => List<int>.unmodifiable(
      (_json['selectedSourceMapIds'] as List).map((value) => value as int));

  List<int> get dependencySourceMapIds => List<int>.unmodifiable(
      (_json['dependencySourceMapIds'] as List).map((value) => value as int));

  OutputPolicy get outputPolicy =>
      OutputPolicy._(_json['outputPolicy'] as Map<String, Object?>);

  List<ConversionOperation> get operations =>
      List<ConversionOperation>.unmodifiable((_json['operations'] as List).map(
          (value) => ConversionOperation._(value as Map<String, Object?>)));

  List<ConversionDiagnostic> get findings =>
      List<ConversionDiagnostic>.unmodifiable((_json['findings'] as List).map(
          (value) => ConversionDiagnostic._(value as Map<String, Object?>)));

  bool get approvedByHuman => _json['approvedByHuman'] as bool;
}

final class OutputPolicy extends _JsonRecord {
  OutputPolicy._(super.json);

  String get destinationFolderName => _json['destinationFolderName'] as String;

  bool get destinationMustBeNew => _json['destinationMustBeNew'] as bool;

  bool get offline => _json['offline'] as bool;

  AssetOutputMode get assetOutputMode =>
      AssetOutputMode.values.byName(_json['assetOutputMode'] as String);
}

final class ConversionOperation extends _JsonRecord {
  ConversionOperation._(super.json);

  ConverterId get operationId => ConverterId(_json['operationId'] as String);

  OperationDomain get domain =>
      OperationDomain.values.byName(_json['domain'] as String);

  List<ConverterId> get sourceEntityIds =>
      List<ConverterId>.unmodifiable((_json['sourceEntityIds'] as List)
          .map((value) => ConverterId(value as String)));

  List<ConverterId> get targetEntityIds =>
      List<ConverterId>.unmodifiable((_json['targetEntityIds'] as List)
          .map((value) => ConverterId(value as String)));

  String? get targetActionId => _json['targetActionId'] == null
      ? null
      : _json['targetActionId'] as String;

  OperationStatus get status =>
      OperationStatus.values.byName(_json['status'] as String);

  List<String> get evidenceRefs => List<String>.unmodifiable(
      (_json['evidenceRefs'] as List).map((value) => value as String));
}

final class ConversionDiagnostic extends _JsonRecord {
  ConversionDiagnostic._(super.json);

  ConverterId get diagnosticId => ConverterId(_json['diagnosticId'] as String);

  ConverterId get code => ConverterId(_json['code'] as String);

  DiagnosticSeverity get severity =>
      DiagnosticSeverity.values.byName(_json['severity'] as String);

  DiagnosticCause get cause =>
      DiagnosticCause.values.byName(_json['cause'] as String);

  DiagnosticFamily get family =>
      DiagnosticFamily.values.byName(_json['family'] as String);

  SourceLocator? get sourceLocator => _json['sourceLocator'] == null
      ? null
      : SourceLocator._(_json['sourceLocator'] as Map<String, Object?>);

  String get message => _json['message'] as String;

  DiagnosticDisposition get disposition =>
      DiagnosticDisposition.values.byName(_json['disposition'] as String);

  bool get blocksStudy => _json['blocksStudy'] as bool;

  bool get blocksPlayableSlice => _json['blocksPlayableSlice'] as bool;

  ConverterId? get acceptedByDecisionId => _json['acceptedByDecisionId'] == null
      ? null
      : ConverterId(_json['acceptedByDecisionId'] as String);
}

final class VisionResponse extends ConverterDocument {
  VisionResponse._(super.json) : super._();

  factory VisionResponse.fromJson(Object? input,
          {ContractLimits limits = const ContractLimits()}) =>
      _readContract(input, 'visionResponse', limits) as VisionResponse;

  ConverterId get requestId => ConverterId(_json['requestId'] as String);

  Sha256Hash get sourceSnapshotHash =>
      Sha256Hash(_json['sourceSnapshotHash'] as String);

  int get inputRevision => _json['inputRevision'] as int;

  List<VisionSuggestion> get suggestions =>
      List<VisionSuggestion>.unmodifiable((_json['suggestions'] as List)
          .map((value) => VisionSuggestion._(value as Map<String, Object?>)));
}

final class VisionSuggestion extends _JsonRecord {
  VisionSuggestion._(super.json);

  ConverterId get suggestionId => ConverterId(_json['suggestionId'] as String);

  List<ConverterId> get candidateIds =>
      List<ConverterId>.unmodifiable((_json['candidateIds'] as List)
          .map((value) => ConverterId(value as String)));

  List<ConverterId> get sourceRegionIds =>
      List<ConverterId>.unmodifiable((_json['sourceRegionIds'] as List)
          .map((value) => ConverterId(value as String)));

  String get proposedName => _json['proposedName'] as String;

  AssetCategory get category =>
      AssetCategory.values.byName(_json['category'] as String);

  List<String> get tags => List<String>.unmodifiable(
      (_json['tags'] as List).map((value) => value as String));

  String get evidenceSummary => _json['evidenceSummary'] as String;

  List<String> get uncertainties => List<String>.unmodifiable(
      (_json['uncertainties'] as List).map((value) => value as String));

  ConfidenceLabel get confidenceLabel =>
      ConfidenceLabel.values.byName(_json['confidenceLabel'] as String);
}

final class ConversionReport extends ConverterDocument {
  ConversionReport._(super.json) : super._();

  factory ConversionReport.fromJson(Object? input,
          {ContractLimits limits = const ContractLimits()}) =>
      _readContract(input, 'conversionReport', limits) as ConversionReport;

  ConverterId get reportId => ConverterId(_json['reportId'] as String);

  Sha256Hash get sourceSnapshotHash =>
      Sha256Hash(_json['sourceSnapshotHash'] as String);

  ConverterId? get planId =>
      _json['planId'] == null ? null : ConverterId(_json['planId'] as String);

  ReportScope get scope => ReportScope.values.byName(_json['scope'] as String);

  ReportState get state => ReportState.values.byName(_json['state'] as String);

  ReportChecks get checks =>
      ReportChecks._(_json['checks'] as Map<String, Object?>);

  List<FamilyCoverage> get coverage =>
      List<FamilyCoverage>.unmodifiable((_json['coverage'] as List)
          .map((value) => FamilyCoverage._(value as Map<String, Object?>)));

  List<ConversionDiagnostic> get findings =>
      List<ConversionDiagnostic>.unmodifiable((_json['findings'] as List).map(
          (value) => ConversionDiagnostic._(value as Map<String, Object?>)));

  List<ArtifactReference> get artifacts =>
      List<ArtifactReference>.unmodifiable((_json['artifacts'] as List)
          .map((value) => ArtifactReference._(value as Map<String, Object?>)));

  AiUsage get aiUsage => AiUsage._(_json['aiUsage'] as Map<String, Object?>);
}

final class ReportChecks extends _JsonRecord {
  ReportChecks._(super.json);

  CheckStatus get nativeLoad =>
      CheckStatus.values.byName(_json['nativeLoad'] as String);

  CheckStatus get nativeSaveReload =>
      CheckStatus.values.byName(_json['nativeSaveReload'] as String);

  CheckStatus get visualParity =>
      CheckStatus.values.byName(_json['visualParity'] as String);

  CheckStatus get gameplayTrace =>
      CheckStatus.values.byName(_json['gameplayTrace'] as String);

  CheckStatus get sourceUnchanged =>
      CheckStatus.values.byName(_json['sourceUnchanged'] as String);
}

final class FamilyCoverage extends _JsonRecord {
  FamilyCoverage._(super.json);

  String get family => _json['family'] as String;

  int get observed => _json['observed'] as int;

  int get extracted => _json['extracted'] as int;

  int get adapted => _json['adapted'] as int;

  int get preservedOnly => _json['preservedOnly'] as int;

  int get excluded => _json['excluded'] as int;

  int get unverified => _json['unverified'] as int;
}

final class ArtifactReference extends _JsonRecord {
  ArtifactReference._(super.json);

  String get relativePath => _json['relativePath'] as String;

  Sha256Hash get sha256 => Sha256Hash(_json['sha256'] as String);

  String get role => _json['role'] as String;
}

final class AiUsage extends _JsonRecord {
  AiUsage._(super.json);

  int get requestCount => _json['requestCount'] as int;

  AiUsageStatus get usageStatus =>
      AiUsageStatus.values.byName(_json['usageStatus'] as String);

  num? get estimatedCost =>
      _json['estimatedCost'] == null ? null : _json['estimatedCost'] as num;

  String? get currency =>
      _json['currency'] == null ? null : _json['currency'] as String;
}

abstract class _JsonRecord {
  _JsonRecord(this._json);
  final Map<String, Object?> _json;
  Map<String, Object?> toJson() => _json;
}

ConverterDocument decodeContract(Object? input,
        {ContractLimits limits = const ContractLimits()}) =>
    _readContract(input, null, limits);

ConverterDocument _readContract(
    Object? input, String? expectedKind, ContractLimits limits) {
  final json = _freezeJson(input, limits);
  if (json is! Map<String, Object?>) {
    throw ContractError('shape.object', r'$', 'Expected an object');
  }
  final kind = json['kind'];
  if (kind is! String ||
      !_contractSchemas.containsKey(kind) ||
      (expectedKind != null && kind != expectedKind)) {
    throw ContractError(
        'shape.kind', r'$.kind', 'Unknown or unexpected contract kind');
  }
  _validateShape(json, _contractSchemas[kind] as Map<String, Object?>, r'$');
  final document = switch (kind) {
    'sourceMapIr' => SourceMapIr._(json),
    'assetCandidate' => AssetCandidate._(json),
    'reviewDecisions' => ReviewDecisions._(json),
    'visionResponse' => VisionResponse._(json),
    'targetCapabilities' => TargetCapabilities._(json),
    'conversionPlan' => ConversionPlan._(json),
    'conversionReport' => ConversionReport._(json),
    _ => throw StateError('Unreachable kind'),
  };
  _validateDomain(document);
  return document;
}
