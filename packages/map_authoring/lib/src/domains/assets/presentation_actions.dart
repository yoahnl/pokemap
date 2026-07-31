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
