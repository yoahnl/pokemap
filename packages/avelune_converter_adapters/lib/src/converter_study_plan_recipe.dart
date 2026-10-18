import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'converter_workflow.dart';
import 'converter_asset_review_set.dart';
import 'literal_tile_composer.dart';
import 'native_project_writer.dart';
import 'supplemented_source_tree.dart';

final class ConverterStudyPlanRecipe {
  factory ConverterStudyPlanRecipe({
    required ConverterId sessionId,
    required int sessionRevision,
    required ConverterSourceSelection sourceSelection,
    List<ConverterSharedSourceFile> sharedSourceFiles = const [],
    required ConverterStudySettings settings,
    required Sha256Hash sourceSnapshotHash,
    required Sha256Hash profileEvidenceHash,
    required Sha256Hash settingsHash,
    required Sha256Hash nativeDraftHash,
    required Sha256Hash preparationHash,
    required Sha256Hash previewPlanHash,
    required Sha256Hash approvedPlanHash,
    required Sha256Hash targetCapabilitiesHash,
    required Sha256Hash rulesHash,
    required String converterVersion,
  }) {
    if (sessionRevision < 3 ||
        sessionRevision > 2147483647 ||
        converterVersion.isEmpty ||
        converterVersion.length > 256 ||
        converterVersion.contains('\u0000') ||
        settingsHash != settings.canonicalHash ||
        settings.profileAcknowledgement.sourceSnapshotHash !=
            sourceSnapshotHash ||
        settings.profileAcknowledgement.profileEvidenceHash !=
            profileEvidenceHash) {
      throw _invalid();
    }
    final references = validateSupplementalProvenance(
        sharedSourceFiles, sourceSelection.supplementalRootPaths);
    final recipe = ConverterStudyPlanRecipe._(
        sessionId,
        sessionRevision,
        sourceSelection,
        List.unmodifiable(references),
        settings,
        sourceSnapshotHash,
        profileEvidenceHash,
        settingsHash,
        nativeDraftHash,
        preparationHash,
        previewPlanHash,
        approvedPlanHash,
        targetCapabilitiesHash,
        rulesHash,
        converterVersion);
    recipe.encode();
    return recipe;
  }

  const ConverterStudyPlanRecipe._(
      this.sessionId,
      this.sessionRevision,
      this.sourceSelection,
      this.sharedSourceFiles,
      this.settings,
      this.sourceSnapshotHash,
      this.profileEvidenceHash,
      this.settingsHash,
      this.nativeDraftHash,
      this.preparationHash,
      this.previewPlanHash,
      this.approvedPlanHash,
      this.targetCapabilitiesHash,
      this.rulesHash,
      this.converterVersion);

  static const maxFileBytes = 4194304;
  static const jsonLimits =
      ContractLimits(maxNodes: 250000, maxTextCodeUnits: 4194304);

  factory ConverterStudyPlanRecipe.fromJson(Object? input) {
    try {
      final canonical = canonicalJsonOf(input, limits: jsonLimits);
      if (utf8.encode(canonical).length > maxFileBytes) throw _quota();
      final json = _object(jsonDecode(canonical));
      if (json['kind'] != 'converterStudyPlanRecipe' || json['version'] != 9) {
        throw _invalid();
      }
      final source = _object(json['sourceSelection']);
      final policy = _object(source['policy']);
      final scan = _object(policy['limits']);
      final settings = _object(json['settings']);
      final acknowledgement = _object(settings['profileAcknowledgement']);
      final normalization = _object(settings['normalizationLimits']);
      final write = _object(settings['writeLimits']);
      final contract = _object(write['jsonLimits']);
      final planContract = _object(write['planJsonLimits']);
      if (settings['version'] != 6) throw _invalid();
      final writeLimits = NativeWriteLimits(
          maxArtifacts: _int(write['maxArtifacts']),
          maxMutations: _int(write['maxMutations']),
          maxArtifactBytes: _int(write['maxArtifactBytes']),
          maxTotalArtifactBytes: _int(write['maxTotalArtifactBytes']),
          maxTotalDraftJsonBytes: _int(write['maxTotalDraftJsonBytes']),
          maxImagePixels: _int(write['maxImagePixels']),
          maxTotalImagePixels: _int(write['maxTotalImagePixels']),
          maxMapCells: _int(write['maxMapCells']),
          planJsonLimits: ContractLimits(
              maxDepth: _int(planContract['maxDepth']),
              maxNodes: _int(planContract['maxNodes']),
              maxStringCodeUnits: _int(planContract['maxStringCodeUnits']),
              maxTextCodeUnits: _int(planContract['maxTextCodeUnits'])),
          jsonLimits: ContractLimits(
              maxDepth: _int(contract['maxDepth']),
              maxNodes: _int(contract['maxNodes']),
              maxStringCodeUnits: _int(contract['maxStringCodeUnits']),
              maxTextCodeUnits: _int(contract['maxTextCodeUnits'])));
      writeLimits.validate();
      final decoded = ConverterStudyPlanRecipe(
          sessionId: ConverterId(_string(json['sessionId'])),
          sessionRevision: _int(json['sessionRevision']),
          sourceSelection: ConverterSourceSelection(
              rootPath: _string(source['rootPath']),
              supplementalRootPaths:
                  _list(source['supplementalRootPaths']).map(_string).toList(),
              logicalProjectNamespace:
                  ConverterId(_string(source['logicalProjectNamespace'])),
              policy: SourceScanPolicy(
                  excludedSegments:
                      _list(policy['excludedSegments']).map(_string).toList(),
                  limits: SourceScanLimits(
                      maxEntries: _int(scan['maxEntries']),
                      maxDepth: _int(scan['maxDepth']),
                      maxFileBytes: _int(scan['maxFileBytes']),
                      maxTotalBytes: _int(scan['maxTotalBytes']),
                      maxPathCodeUnits: _int(scan['maxPathCodeUnits']),
                      maxProbeBytes: _int(scan['maxProbeBytes']),
                      maxDiagnostics: _int(scan['maxDiagnostics']),
                      maxProfileEvidence: _int(scan['maxProfileEvidence']),
                      maxTotalPathCodeUnits:
                          _int(scan['maxTotalPathCodeUnits'])))),
          sharedSourceFiles: _list(json['sharedSourceFiles'])
              .map(ConverterSharedSourceFile.fromJson)
              .toList(),
          settings: ConverterStudySettings(
              interpretationProfile: settings['interpretationProfile'] == null ? null :
                SourceInterpretationProfile.fromJson(settings['interpretationProfile']),
              imageBindings: _list(settings['imageBindings'])
                  .map(SourceImageBinding.fromJson)
                  .toList(),
              projectName: _string(settings['projectName']),
              parentPath: _string(settings['parentPath']),
              folderName: _string(settings['folderName']),
              selectedSourceMapIds:
                  _list(settings['selectedSourceMapIds']).map(_int).toList(),
              profileAcknowledgement: SourceStudyAcknowledgement(
                  sourceSnapshotHash: Sha256Hash(
                      _string(acknowledgement['sourceSnapshotHash'])),
                  profileEvidenceHash: Sha256Hash(
                      _string(acknowledgement['profileEvidenceHash'])),
                  humanConfirmed: _bool(acknowledgement['humanConfirmed']),
                  reason: _string(acknowledgement['reason'])),
              allowFirstFrameAutotiles:
                  _bool(settings['allowFirstFrameAutotiles']),
              assetOutputMode: AssetOutputMode.values
                  .byName(_string(settings['assetOutputMode'])),
              reviewSet: settings['reviewSet'] == null
                  ? null
                  : ConverterAssetReviewSet.fromJson(settings['reviewSet'],
                      admissionLimits:
                          converterAssetReviewSetLimitsFor(writeLimits)),
              dependencyDecisions:
                  _list(settings['dependencyDecisions']).map((value) {
                final decision = _object(value);
                return LiteralDependencyDecision(
                    sourceSnapshotHash:
                        Sha256Hash(_string(decision['sourceSnapshotHash'])),
                    selectionHash:
                        Sha256Hash(_string(decision['selectionHash'])),
                    locator: SourceLocator.fromJson(decision['locator']),
                    targetSourceMapId: decision['targetSourceMapId'] == null
                        ? null
                        : _int(decision['targetSourceMapId']),
                    decision: LiteralDependencyDisposition.values
                        .byName(_string(decision['decision'])));
              }).toList(),
              normalizationLimits: SourceNormalizationLimits(
                  maxMaps: _int(normalization['maxMaps']),
                  maxConnections: _int(normalization['maxConnections']),
                  maxTotalCells: _int(normalization['maxTotalCells']),
                  maxEvents: _int(normalization['maxEvents']),
                  maxCommands: _int(normalization['maxCommands']),
                  maxParameterNodes: _int(normalization['maxParameterNodes']),
                  maxDiagnostics: _int(normalization['maxDiagnostics']),
                  maxTotalBytes: _int(normalization['maxTotalBytes']),
                  maxMetadataCells: _int(normalization['maxMetadataCells']),
                  maxTotalIrNodes: _int(normalization['maxTotalIrNodes']),
                  maxTotalTextCodeUnits:
                      _int(normalization['maxTotalTextCodeUnits']),
                  maxDiagnosticTextCodeUnits:
                      _int(normalization['maxDiagnosticTextCodeUnits'])),
              writeLimits: writeLimits),
          sourceSnapshotHash: Sha256Hash(_string(json['sourceSnapshotHash'])),
          profileEvidenceHash: Sha256Hash(_string(json['profileEvidenceHash'])),
          settingsHash: Sha256Hash(_string(json['settingsHash'])),
          nativeDraftHash: Sha256Hash(_string(json['nativeDraftHash'])),
          preparationHash: Sha256Hash(_string(json['preparationHash'])),
          previewPlanHash: Sha256Hash(_string(json['previewPlanHash'])),
          approvedPlanHash: Sha256Hash(_string(json['approvedPlanHash'])),
          targetCapabilitiesHash:
              Sha256Hash(_string(json['targetCapabilitiesHash'])),
          rulesHash: Sha256Hash(_string(json['rulesHash'])),
          converterVersion: _string(json['converterVersion']));
      if (canonical != canonicalJsonOf(decoded.toJson(), limits: jsonLimits)) {
        throw _invalid();
      }
      return decoded;
    } on ConverterWorkflowFailure {
      rethrow;
    } on ContractError catch (error) {
      throw ConverterWorkflowFailure(
          'workflow.recipe.invalid', error.toString());
    } on Object {
      throw _invalid();
    }
  }

  factory ConverterStudyPlanRecipe.decode(String text) {
    if (text.length > maxFileBytes || utf8.encode(text).length > maxFileBytes) {
      throw _quota();
    }
    try {
      return ConverterStudyPlanRecipe.fromJson(jsonDecode(text));
    } on FormatException {
      throw _invalid();
    }
  }

  final ConverterId sessionId;
  final int sessionRevision;
  final ConverterSourceSelection sourceSelection;
  final List<ConverterSharedSourceFile> sharedSourceFiles;
  final ConverterStudySettings settings;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash profileEvidenceHash;
  final Sha256Hash settingsHash;
  final Sha256Hash nativeDraftHash;
  final Sha256Hash preparationHash;
  final Sha256Hash previewPlanHash;
  final Sha256Hash approvedPlanHash;
  final Sha256Hash targetCapabilitiesHash;
  final Sha256Hash rulesHash;
  final String converterVersion;

  Map<String, Object?> _body() => {
        'kind': 'converterStudyPlanRecipe',
        'version': 9,
        'sessionId': sessionId.value,
        'sessionRevision': sessionRevision,
        'sourceSelection': {
          'rootPath': sourceSelection.rootPath,
          'supplementalRootPaths': sourceSelection.supplementalRootPaths,
          'logicalProjectNamespace':
              sourceSelection.logicalProjectNamespace.value,
          'policy': {
            'limits': sourceSelection.policy.limits.toJson(),
            'excludedSegments': sourceSelection.policy.excludedSegments
          }
        },
        'sharedSourceFiles':
            sharedSourceFiles.map((file) => file.toJson()).toList(),
        'settings': settings.toJson(),
        'sourceSelectionHash': sourceSelection.canonicalHash.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileEvidenceHash': profileEvidenceHash.value,
        'settingsHash': settingsHash.value,
        'nativeDraftHash': nativeDraftHash.value,
        'preparationHash': preparationHash.value,
        'previewPlanHash': previewPlanHash.value,
        'approvedPlanHash': approvedPlanHash.value,
        'targetCapabilitiesHash': targetCapabilitiesHash.value,
        'rulesHash': rulesHash.value,
        'converterVersion': converterVersion,
      };

  Sha256Hash get canonicalHash => canonicalHashOf(_body(), limits: jsonLimits);
  Map<String, Object?> toJson() =>
      {..._body(), 'canonicalHash': canonicalHash.value};
  String encode() {
    final text = canonicalJsonOf(toJson(), limits: jsonLimits);
    if (utf8.encode(text).length > maxFileBytes) throw _quota();
    return text;
  }
}

ConverterWorkflowFailure _invalid() => const ConverterWorkflowFailure(
    'workflow.recipe.invalid',
    'A closed, unchanged, bounded study plan recipe is required.');
ConverterWorkflowFailure _quota() => const ConverterWorkflowFailure(
    'workflow.recipe.quota',
    'Study plan recipe exceeds its 4 MiB byte budget.');
Map<String, Object?> _object(Object? value) =>
    value is Map<String, Object?> ? value : throw _invalid();
List<Object?> _list(Object? value) =>
    value is List<Object?> ? value : throw _invalid();
String _string(Object? value) => value is String ? value : throw _invalid();
int _int(Object? value) => value is int ? value : throw _invalid();
bool _bool(Object? value) => value is bool ? value : throw _invalid();
