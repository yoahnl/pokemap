# PMCP-042 — Contenu intégral des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `packages/map_authoring/lib/src/domains/assets/presentation_actions.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'asset_store.dart';

final class PresentationAuthoringException implements Exception {
  PresentationAuthoringException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'PresentationAuthoringException($code): $message';
}

final class PresentationGateResult {
  PresentationGateResult(Iterable<ProjectPresentationDiagnostic> diagnostics)
      : diagnostics = List.unmodifiable(
          diagnostics.toList()
            ..sort((left, right) {
              final path = left.path.compareTo(right.path);
              return path != 0 ? path : left.code.compareTo(right.code);
            }),
        );

  final List<ProjectPresentationDiagnostic> diagnostics;

  bool get canPublish => diagnostics.every(
        (diagnostic) =>
            diagnostic.severity != ProjectPresentationDiagnosticSeverity.error,
      );
}

/// Combines the canonical presentation validator with asset existence and MIME
/// checks. This is the single gate used by API actions, previews, and adapters.
final class PresentationAuthoringGate {
  const PresentationAuthoringGate();

  PresentationGateResult inspect(
    ProjectPresentationProfile profile,
    AssetCatalog assets,
  ) {
    final diagnostics = <ProjectPresentationDiagnostic>[
      ...validateProjectPresentationProfile(profile),
    ];
    final byPath = {
      for (final asset in assets.records) asset.logicalPath: asset,
    };
    for (final reference in _presentationReferences(profile)) {
      final asset = byPath[reference.logicalPath];
      if (asset == null) {
        diagnostics.add(
          ProjectPresentationDiagnostic(
            code: 'presentationAssetMissing',
            category: reference.category,
            severity: ProjectPresentationDiagnosticSeverity.error,
            path: reference.profilePath,
            message: 'Import the referenced asset into the project library.',
          ),
        );
        continue;
      }
      if (!reference.accepts(asset.artifact.mediaType)) {
        diagnostics.add(
          ProjectPresentationDiagnostic(
            code: 'presentationAssetMediaTypeMismatch',
            category: reference.category,
            severity: ProjectPresentationDiagnosticSeverity.error,
            path: reference.profilePath,
            message: 'Choose an asset with a compatible media type.',
          ),
        );
      }
    }
    return PresentationGateResult(diagnostics);
  }
}

final class ProjectPresentationEditorAdapterResult {
  const ProjectPresentationEditorAdapterResult({
    required this.projectedManifest,
    required this.diagnostics,
  });

  final ProjectManifest projectedManifest;
  final List<ProjectPresentationDiagnostic> diagnostics;

  bool get canApply => diagnostics.every(
        (diagnostic) =>
            diagnostic.severity != ProjectPresentationDiagnosticSeverity.error,
      );
}

/// Thin characterization seam for the existing editor personalization flow.
/// It projects the exact canonical manifest that `presentation.update` writes.
final class ProjectPresentationEditorAdapter {
  const ProjectPresentationEditorAdapter({
    this.gate = const PresentationAuthoringGate(),
  });

  final PresentationAuthoringGate gate;

  ProjectPresentationEditorAdapterResult prepare({
    required ProjectManifest manifest,
    required ProjectPresentationProfile profile,
    required AssetCatalog assets,
  }) {
    final result = gate.inspect(profile, assets);
    return ProjectPresentationEditorAdapterResult(
      projectedManifest: manifest.copyWith(presentation: profile),
      diagnostics: result.diagnostics,
    );
  }
}

final class PresentationPreview {
  PresentationPreview({
    required String previewId,
    required String projectRevision,
    required Iterable<String> configuredCategories,
    required Iterable<String> assetHandles,
    required Map<String, Object?> profile,
  })  : previewId = _stablePreviewId(previewId),
        projectRevision = _revision(projectRevision),
        configuredCategories = normalizedContractStrings(
          configuredCategories,
          'configuredCategories',
        ),
        assetHandles = normalizedContractStrings(assetHandles, 'assetHandles'),
        profile = freezeContractJsonObject(profile, field: 'profile');

  final String previewId;
  final String projectRevision;
  final List<String> configuredCategories;
  final List<String> assetHandles;
  final Map<String, Object?> profile;

  void requireRevision(String currentRevision) {
    final current = _revision(currentRevision);
    if (current != projectRevision) {
      throw PresentationAuthoringException(
        'presentation.preview_stale',
        'The preview was produced from another project revision.',
        details: {
          'previewRevision': projectRevision,
          'currentRevision': current,
        },
      );
    }
  }

  Map<String, Object?> toJson() => {
        'previewId': previewId,
        'projectRevision': projectRevision,
        'configuredCategories': configuredCategories,
        'assetHandles': assetHandles,
        'profile': profile,
      };
}

final class PresentationPreviewService {
  const PresentationPreviewService({
    this.gate = const PresentationAuthoringGate(),
  });

  final PresentationAuthoringGate gate;

  PresentationPreview create({
    required ProjectPresentationProfile profile,
    required String projectRevision,
    required AssetCatalog assets,
  }) {
    final result = gate.inspect(profile, assets);
    if (!result.canPublish) {
      throw PresentationAuthoringException(
        'presentation.preview_invalid',
        'A preview cannot be produced from an invalid presentation profile.',
        details: {
          'diagnosticCodes': [
            for (final diagnostic in result.diagnostics) diagnostic.code,
          ],
        },
      );
    }
    final byPath = {
      for (final asset in assets.records) asset.logicalPath: asset,
    };
    final handles = <String>{};
    for (final reference in _presentationReferences(profile)) {
      final asset = byPath[reference.logicalPath];
      if (asset != null) handles.add(asset.artifact.handle);
    }
    final profileJson = Map<String, Object?>.from(profile.toJson());
    final identity = ContentArtifactRef.fromBytes(
      utf8.encode('$projectRevision\n${canonicalAuthoringJson(profileJson)}'),
      mediaType: 'application/vnd.pokemap.presentation-preview+json',
    );
    return PresentationPreview(
      previewId: 'presentation-preview:${identity.hexDigest}',
      projectRevision: projectRevision,
      configuredCategories:
          profile.configuredCategories.map((category) => category.name),
      assetHandles: handles,
      profile: profileJson,
    );
  }
}

final class PresentationActions {
  const PresentationActions({
    this.gate = const PresentationAuthoringGate(),
    this.previewService = const PresentationPreviewService(),
  });

  final PresentationAuthoringGate gate;
  final PresentationPreviewService previewService;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor(
      'presentation.update',
      'Update the validated project presentation profile',
      AuthoringRiskLevel.medium,
    ),
    _descriptor(
      'presentation.delete',
      'Remove the project presentation profile',
      AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = _PresentationParameters(context.request.parameters);
    final assets = _assetCatalog(context.snapshot);
    switch (context.request.actionId) {
      case 'presentation.update':
        parameters.allow(const {'profile'});
        final profile = parameters.profile();
        final projected = update(
          context.snapshot.manifest,
          profile: profile,
          assets: assets,
        );
        final preview = previewService.create(
          profile: profile,
          projectRevision: context.snapshot.revision,
          assets: assets,
        );
        return _draft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          before: context.snapshot.manifest.presentation?.toJson(),
          after: profile.toJson(),
          preview: preview.toJson(),
        );
      case 'presentation.delete':
        parameters.allow(const {});
        final projected = delete(context.snapshot.manifest);
        return _draft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          before: context.snapshot.manifest.presentation?.toJson(),
          preview: const {'configuredCategories': <String>[]},
        );
      default:
        throw PresentationAuthoringException(
          'presentation.action_unsupported',
          'The requested presentation action is unsupported.',
          details: {'actionId': context.request.actionId},
        );
    }
  }

  ProjectManifest update(
    ProjectManifest manifest, {
    required ProjectPresentationProfile profile,
    required AssetCatalog assets,
  }) {
    final result = gate.inspect(profile, assets);
    if (!result.canPublish) {
      throw PresentationAuthoringException(
        'presentation.validation_failed',
        'The presentation profile has blocking diagnostics.',
        details: {
          'diagnostics': [
            for (final diagnostic in result.diagnostics)
              {
                'code': diagnostic.code,
                'path': diagnostic.path,
                'severity': diagnostic.severity.name,
              },
          ],
        },
      );
    }
    if (manifest.presentation == profile) {
      throw PresentationAuthoringException(
        'presentation.no_change',
        'The presentation profile is already current.',
      );
    }
    return manifest.copyWith(presentation: profile);
  }

  ProjectManifest delete(ProjectManifest manifest) {
    if (manifest.presentation == null) {
      throw PresentationAuthoringException(
        'presentation.not_configured',
        'The project has no presentation profile to remove.',
      );
    }
    return manifest.copyWith(presentation: null);
  }
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary,
  AuthoringRiskLevel risk,
) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring/$id.input.v1',
      outputSchemaId: 'pokemap.authoring/$id.output.v1',
      riskLevel: risk,
      resourceKinds: const ['project', 'asset'],
      capabilityIds: const ['authoring.presentation'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringMutationDraft _draft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  Object? before,
  Object? after,
  required Map<String, Object?> preview,
}) {
  try {
    ProjectValidator.validate(projected);
  } on Object catch (error) {
    throw PresentationAuthoringException(
      'presentation.projected_state_invalid',
      'The presentation mutation would invalidate the project.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
  final project = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
          resource: project,
          storageKey: 'project.json',
          beforeBytes: snapshot.resourceBytes('project'),
          afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : AuthoringDiffOperation.replace,
          resource: project,
          path: '/presentation',
          before: before,
          after: after,
        ),
      ]),
    ),
    preview: preview,
  );
}

AssetCatalog _assetCatalog(ProjectSnapshot snapshot) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) return AssetCatalog();
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException('catalog must be object');
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw PresentationAuthoringException(
      'presentation.asset_catalog_invalid',
      'The presentation asset catalog cannot be decoded.',
    );
  }
}

Iterable<_PresentationReference> _presentationReferences(
  ProjectPresentationProfile profile,
) sync* {
  final branding = profile.branding;
  for (final item in <({String field, String? value})>[
    (field: 'iconPath', value: branding.iconPath),
    (field: 'coverPath', value: branding.coverPath),
    (field: 'heroPath', value: branding.heroPath),
  ]) {
    if (item.value case final value?) {
      yield _PresentationReference.image(
        value,
        ProjectPresentationCategory.branding,
        '\$.presentation.branding.${item.field}',
      );
    }
  }
  if (branding.titleMusicPath case final value?) {
    yield _PresentationReference.audio(
      value,
      ProjectPresentationCategory.branding,
      r'$.presentation.branding.titleMusicPath',
    );
  }
  if (profile.intro case final intro?) {
    yield _PresentationReference.video(
      intro.videoPath,
      ProjectPresentationCategory.intro,
      r'$.presentation.intro.videoPath',
    );
    if (intro.posterPath case final value?) {
      yield _PresentationReference.image(
        value,
        ProjectPresentationCategory.intro,
        r'$.presentation.intro.posterPath',
      );
    }
    if (intro.captionsPath case final value?) {
      yield _PresentationReference.captions(
        value,
        ProjectPresentationCategory.intro,
        r'$.presentation.intro.captionsPath',
      );
    }
  }
  if (profile.typography case final typography?) {
    final roles = <String, ProjectTypographyRoleProfile>{
      'display': typography.display,
      'body': typography.body,
      'dialogue': typography.dialogue,
      'numbers': typography.numbers,
    };
    for (final entry in roles.entries) {
      if (entry.value.fontPath case final value?) {
        yield _PresentationReference.font(
          value,
          ProjectPresentationCategory.typography,
          '\$.presentation.typography.${entry.key}.fontPath',
        );
      }
      if (entry.value.licensePath case final value?) {
        yield _PresentationReference.license(
          value,
          ProjectPresentationCategory.typography,
          '\$.presentation.typography.${entry.key}.licensePath',
        );
      }
    }
  }
}

typedef _MediaTypePredicate = bool Function(String mediaType);

final class _PresentationReference {
  const _PresentationReference(
    this.logicalPath,
    this.category,
    this.profilePath,
    this.accepts,
  );

  factory _PresentationReference.image(
    String path,
    ProjectPresentationCategory category,
    String profilePath,
  ) =>
      _PresentationReference(
        path,
        category,
        profilePath,
        (value) => value.startsWith('image/'),
      );

  factory _PresentationReference.audio(
    String path,
    ProjectPresentationCategory category,
    String profilePath,
  ) =>
      _PresentationReference(
        path,
        category,
        profilePath,
        (value) => value.startsWith('audio/'),
      );

  factory _PresentationReference.video(
    String path,
    ProjectPresentationCategory category,
    String profilePath,
  ) =>
      _PresentationReference(
        path,
        category,
        profilePath,
        (value) => value.startsWith('video/'),
      );

  factory _PresentationReference.captions(
    String path,
    ProjectPresentationCategory category,
    String profilePath,
  ) =>
      _PresentationReference(
        path,
        category,
        profilePath,
        (value) => const {'text/vtt', 'application/x-subrip'}.contains(value),
      );

  factory _PresentationReference.font(
    String path,
    ProjectPresentationCategory category,
    String profilePath,
  ) =>
      _PresentationReference(
        path,
        category,
        profilePath,
        (value) =>
            value.startsWith('font/') || value.startsWith('application/font-'),
      );

  factory _PresentationReference.license(
    String path,
    ProjectPresentationCategory category,
    String profilePath,
  ) =>
      _PresentationReference(
        path,
        category,
        profilePath,
        (value) => const {'text/plain', 'application/pdf'}.contains(value),
      );

  final String logicalPath;
  final ProjectPresentationCategory category;
  final String profilePath;
  final _MediaTypePredicate accepts;
}

final class _PresentationParameters {
  _PresentationParameters(Map<String, Object?> values) : _values = values;

  final Map<String, Object?> _values;

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw PresentationAuthoringException(
        'presentation.parameters_unknown',
        'The request contains unsupported presentation parameters.',
        details: {'unknown': unknown},
      );
    }
  }

  ProjectPresentationProfile profile() {
    final raw = _values['profile'];
    if (raw is! Map) {
      throw PresentationAuthoringException(
        'presentation.profile_required',
        'A presentation profile object is required.',
      );
    }
    try {
      return ProjectPresentationProfile.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on Object {
      throw PresentationAuthoringException(
        'presentation.profile_invalid',
        'The presentation profile cannot be decoded.',
      );
    }
  }
}

String _stablePreviewId(String value) {
  if (!RegExp(r'^presentation-preview:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'previewId', 'must be content-addressed');
  }
  return value;
}

String _revision(String value) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'projectRevision', 'must be SHA-256');
  }
  return value;
}
```

## `packages/map_authoring/lib/src/ports/media_processing_port.dart`

```dart
import 'dart:async';

import '../contracts/artifact_ref.dart';
import '../contracts/json_contract_support.dart';
import '../support/authoring_fingerprint.dart';

enum MediaProcessingKind {
  transcodeVideo('transcode_video'),
  extractPoster('extract_poster'),
  normalizeAudio('normalize_audio'),
  subsetFont('subset_font');

  const MediaProcessingKind(this.wireName);

  final String wireName;
}

enum MediaProcessingStatus { queued, running, succeeded, failed }

final class MediaProcessingException implements Exception {
  MediaProcessingException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'MediaProcessingException($code): $message';
}

/// Path-free request for one potentially long-running media transformation.
final class MediaProcessingRequest {
  MediaProcessingRequest({
    required String idempotencyKey,
    required this.kind,
    required this.source,
    required String expectedProjectRevision,
    required String targetMediaType,
    Map<String, Object?> options = const {},
  })  : idempotencyKey = _stableKey(idempotencyKey, 'idempotencyKey'),
        expectedProjectRevision =
            _revision(expectedProjectRevision, 'expectedProjectRevision'),
        targetMediaType = _mediaType(targetMediaType),
        options = freezeContractJsonObject(options, field: 'options');

  final String idempotencyKey;
  final MediaProcessingKind kind;
  final ContentArtifactRef source;
  final String expectedProjectRevision;
  final String targetMediaType;
  final Map<String, Object?> options;

  Map<String, Object?> toJson() => {
        'idempotencyKey': idempotencyKey,
        'kind': kind.wireName,
        'source': source.toJson(),
        'expectedProjectRevision': expectedProjectRevision,
        'targetMediaType': targetMediaType,
        'options': options,
      };
}

final class MediaProcessingResult {
  MediaProcessingResult({
    required this.output,
    Map<String, Object?> metadata = const {},
  }) : metadata = freezeContractJsonObject(metadata, field: 'metadata');

  final ContentArtifactRef output;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => {
        'output': output.toJson(),
        'metadata': metadata,
      };
}

final class MediaProcessingJob {
  const MediaProcessingJob({
    required this.jobId,
    required this.request,
    required this.status,
    required this.createdAtUtc,
    this.result,
    this.failureCode,
  });

  final String jobId;
  final MediaProcessingRequest request;
  final MediaProcessingStatus status;
  final DateTime createdAtUtc;
  final MediaProcessingResult? result;
  final String? failureCode;

  bool get isTerminal =>
      status == MediaProcessingStatus.succeeded ||
      status == MediaProcessingStatus.failed;

  Map<String, Object?> toJson() => {
        'jobId': jobId,
        'request': request.toJson(),
        'status': status.name,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
        if (result != null) 'result': result!.toJson(),
        if (failureCode != null) 'failureCode': failureCode,
      };
}

abstract interface class MediaProcessingPort {
  Future<MediaProcessingJob> submit(MediaProcessingRequest request);

  Future<MediaProcessingJob> status(String jobId);

  Future<MediaProcessingJob> wait(String jobId);
}

typedef MediaProcessor = Future<MediaProcessingResult> Function(
  MediaProcessingRequest request,
);

/// Deterministic in-process adapter used by hosts and contract tests.
///
/// A production host can implement [MediaProcessingPort] with an isolated
/// worker or service without giving the authoring API process or filesystem
/// authority. Submission is idempotent and always returns before processing
/// completion.
final class InMemoryMediaProcessingPort implements MediaProcessingPort {
  InMemoryMediaProcessingPort({
    required MediaProcessor processor,
    DateTime Function()? clock,
  })  : _processor = processor,
        _clock = clock ?? (() => DateTime.now().toUtc());

  final MediaProcessor _processor;
  final DateTime Function() _clock;
  final Map<String, MediaProcessingJob> _jobs = {};
  final Map<String, Completer<MediaProcessingJob>> _completions = {};

  @override
  Future<MediaProcessingJob> submit(MediaProcessingRequest request) async {
    final jobId = 'media-job:${request.idempotencyKey}';
    final existing = _jobs[jobId];
    if (existing != null) {
      if (!_sameRequest(existing.request, request)) {
        throw MediaProcessingException(
          'media.idempotency_conflict',
          'The idempotency key is already bound to another media request.',
          details: {'idempotencyKey': request.idempotencyKey},
        );
      }
      return existing;
    }
    final queued = MediaProcessingJob(
      jobId: jobId,
      request: request,
      status: MediaProcessingStatus.queued,
      createdAtUtc: _clock().toUtc(),
    );
    _jobs[jobId] = queued;
    _completions[jobId] = Completer<MediaProcessingJob>();
    scheduleMicrotask(() => _run(jobId));
    return queued;
  }

  @override
  Future<MediaProcessingJob> status(String jobId) async => _require(jobId);

  @override
  Future<MediaProcessingJob> wait(String jobId) {
    final job = _require(jobId);
    if (job.isTerminal) return Future.value(job);
    return _completions[jobId]!.future;
  }

  Future<void> _run(String jobId) async {
    final queued = _require(jobId);
    _jobs[jobId] = MediaProcessingJob(
      jobId: jobId,
      request: queued.request,
      status: MediaProcessingStatus.running,
      createdAtUtc: queued.createdAtUtc,
    );
    late final MediaProcessingJob terminal;
    try {
      final result = await _processor(queued.request);
      if (result.output.mediaType != queued.request.targetMediaType) {
        throw MediaProcessingException(
          'media.output_type_mismatch',
          'The processor output does not match the requested media type.',
          details: {
            'expected': queued.request.targetMediaType,
            'actual': result.output.mediaType,
          },
        );
      }
      terminal = MediaProcessingJob(
        jobId: jobId,
        request: queued.request,
        status: MediaProcessingStatus.succeeded,
        createdAtUtc: queued.createdAtUtc,
        result: result,
      );
    } on Object catch (error) {
      terminal = MediaProcessingJob(
        jobId: jobId,
        request: queued.request,
        status: MediaProcessingStatus.failed,
        createdAtUtc: queued.createdAtUtc,
        failureCode: error is MediaProcessingException
            ? error.code
            : 'media.processor_failed',
      );
    }
    _jobs[jobId] = terminal;
    _completions.remove(jobId)!.complete(terminal);
  }

  MediaProcessingJob _require(String jobId) {
    final normalized = _stableKey(jobId, 'jobId');
    final job = _jobs[normalized];
    if (job == null) {
      throw MediaProcessingException(
        'media.job_unknown',
        'The media processing job does not exist.',
        details: {'jobId': normalized},
      );
    }
    return job;
  }
}

bool _sameRequest(MediaProcessingRequest left, MediaProcessingRequest right) =>
    canonicalAuthoringJson(left.toJson()) ==
    canonicalAuthoringJson(right.toJson());

String _stableKey(String value, String field) {
  final normalized = value.trim();
  if (normalized != value ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a stable key');
  }
  return normalized;
}

String _revision(String value, String field) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 revision');
  }
  return value;
}

String _mediaType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized != value ||
      !RegExp(r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$')
          .hasMatch(normalized)) {
    throw ArgumentError.value(value, 'targetMediaType', 'must be a MIME type');
  }
  return normalized;
}
```

## `packages/map_authoring/test/domains/assets/presentation_authoring_test.dart`

```dart
import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentation authoring', () {
    test('validates every media reference against the canonical asset catalog',
        () {
      final profile = _profile(
        branding: const ProjectBrandingProfile(
          iconPath: 'presentation/icon.png',
          titleMusicPath: 'presentation/title.png',
        ),
      );
      final result = const PresentationAuthoringGate().inspect(
        profile,
        _catalog(),
      );

      expect(result.canPublish, isFalse);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('presentationAssetMediaTypeMismatch'),
      );
      expect(
        result.diagnostics
            .where(
                (diagnostic) => diagnostic.code == 'presentationAssetMissing')
            .map((diagnostic) => diagnostic.path),
        contains(r'$.presentation.typography.body.licensePath'),
      );
    });

    test('editor adapter and mutation gate share the same projected state', () {
      final profile = _profile();
      final manifest = ProjectManifest(
        name: 'Presentation fixture',
        maps: const [],
        tilesets: const [],
      );
      final result = const ProjectPresentationEditorAdapter().prepare(
        manifest: manifest,
        profile: profile,
        assets: _catalog(includeLicense: true),
      );

      expect(result.canApply, isTrue);
      expect(result.projectedManifest.presentation, profile);
      expect(
        result.diagnostics,
        const PresentationAuthoringGate()
            .inspect(profile, _catalog(includeLicense: true))
            .diagnostics,
      );
    });

    test('preview handles are revision-bound and reject stale consumption', () {
      final preview = const PresentationPreviewService().create(
        profile: _profile(),
        projectRevision: _revision('a'),
        assets: _catalog(includeLicense: true),
      );

      expect(preview.assetHandles, hasLength(6));
      expect(preview.previewId, startsWith('presentation-preview:'));
      preview.requireRevision(_revision('a'));
      expect(
        () => preview.requireRevision(_revision('b')),
        throwsA(
          isA<PresentationAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation.preview_stale',
          ),
        ),
      );
    });

    test('media processing jobs are asynchronous and idempotent', () async {
      final processing = Completer<MediaProcessingResult>();
      final port = InMemoryMediaProcessingPort(
        processor: (request) => processing.future,
      );
      final request = MediaProcessingRequest(
        idempotencyKey: 'intro-transcode-1',
        kind: MediaProcessingKind.transcodeVideo,
        source: _artifact('video/mp4', 42),
        expectedProjectRevision: _revision('c'),
        targetMediaType: 'video/webm',
      );

      final first = await port.submit(request);
      final duplicate = await port.submit(request);
      expect(first.status, MediaProcessingStatus.queued);
      expect(duplicate.jobId, first.jobId);

      processing.complete(
        MediaProcessingResult(
          output: _artifact('video/webm', 43),
          metadata: const {'videoCodec': 'vp9'},
        ),
      );
      final completed = await port.wait(first.jobId);
      expect(completed.status, MediaProcessingStatus.succeeded);
      expect(completed.result?.output.mediaType, 'video/webm');
    });

    test('dispatcher exposes canonical presentation mutations', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(ids, containsAll({'presentation.update', 'presentation.delete'}));
    });
  });
}

ProjectPresentationProfile _profile({ProjectBrandingProfile? branding}) =>
    ProjectPresentationProfile(
      branding: branding ??
          const ProjectBrandingProfile(
            iconPath: 'presentation/icon.png',
            titleMusicPath: 'presentation/title.ogg',
          ),
      intro: const ProjectIntroVideoProfile(
        videoPath: 'presentation/intro.mp4',
        posterPath: 'presentation/poster.png',
        durationMilliseconds: 3000,
        width: 1280,
        height: 720,
        bitrateKbps: 4000,
        sizeBytes: 42,
        videoCodec: 'h264',
        audioCodec: 'aac',
      ),
      typography: const ProjectTypographyProfile(
        body: ProjectTypographyRoleProfile(
          fontPath: 'presentation/body.ttf',
          family: 'Fixture Sans',
          licensePath: 'presentation/body-license.txt',
          redistributable: true,
          fallbackFamilies: ['sans-serif'],
          glyphCoverage: ['latin', 'latinExtended', 'digits', 'punctuation'],
        ),
      ),
      theme: safeProjectSemanticTheme,
    );

AssetCatalog _catalog({bool includeLicense = false}) => AssetCatalog(records: [
      _asset('icon', 'presentation/icon.png', 'image/png', 1),
      _asset('wrong-music', 'presentation/title.png', 'image/png', 7),
      _asset('music', 'presentation/title.ogg', 'audio/ogg', 2),
      _asset('intro', 'presentation/intro.mp4', 'video/mp4', 3),
      _asset('poster', 'presentation/poster.png', 'image/png', 4),
      _asset('font', 'presentation/body.ttf', 'font/ttf', 5),
      if (includeLicense)
        _asset(
          'font-license',
          'presentation/body-license.txt',
          'text/plain',
          6,
        ),
    ]);

AssetRecord _asset(String id, String path, String mediaType, int byte) =>
    AssetRecord(
      id: id,
      logicalPath: path,
      artifact: _artifact(mediaType, byte),
    );

ContentArtifactRef _artifact(String mediaType, int byte) =>
    ContentArtifactRef.fromBytes([byte], mediaType: mediaType);

String _revision(String digit) => 'sha256:${List.filled(64, digit).join()}';
```
