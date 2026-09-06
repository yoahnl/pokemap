import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_receipt.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'asset_store.dart';

final class PresentationPresetAuthoringException implements Exception {
  const PresentationPresetAuthoringException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PresentationPresetAuthoringException($code): $message';
}

final class PresentationPresetActions {
  PresentationPresetActions({
    required ArtifactStore artifactStore,
    this.codec = const PresentationPresetPackCodec(),
  }) : _artifactStore = artifactStore;

  final ArtifactStore _artifactStore;
  final PresentationPresetPackCodec codec;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      _descriptor(
        'presentation.preset.import_plan',
        'Inspect and stage a shareable presentation preset',
        AuthoringRiskLevel.low,
      ),
      _descriptor(
        'presentation.preset.import_apply',
        'Import and apply a staged presentation preset',
        AuthoringRiskLevel.medium,
      ),
      _descriptor(
        'presentation.preset.export',
        'Export the current presentation as a shareable preset',
        AuthoringRiskLevel.medium,
      ),
      _descriptor(
        'presentation.preset.delete_plan',
        'Inspect deletion of a project presentation preset',
        AuthoringRiskLevel.low,
      ),
      _descriptor(
        'presentation.preset.delete_apply',
        'Delete a project presentation preset',
        AuthoringRiskLevel.high,
      ),
    ],
  );

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    _requireMode(context.request.actionId, context.request.dryRun);
    final parameters = _Parameters(context.request.parameters);
    return switch (context.request.actionId) {
      'presentation.preset.export' => _export(context, parameters),
      'presentation.preset.import_plan' ||
      'presentation.preset.import_apply' =>
        _import(context, parameters),
      'presentation.preset.delete_plan' ||
      'presentation.preset.delete_apply' =>
        _delete(context, parameters),
      _ => throw const PresentationPresetAuthoringException(
          'presentation.preset.action_unsupported',
          'The requested presentation preset action is unsupported.',
        ),
    };
  }

  Future<AuthoringMutationDraft> _export(
    AuthoringPlanningContext context,
    _Parameters parameters,
  ) async {
    parameters.allow(
      const <String>{
        'presetId',
        'label',
        'description',
        'licenses',
        'scope',
        'replacedSections',
      },
    );
    final profile = context.snapshot.manifest.presentation;
    if (profile == null) {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.profile_missing',
        'Configure and save a presentation before exporting a preset.',
      );
    }
    final id = parameters.string('presetId');
    final label = parameters.string('label');
    final description = parameters.string('description');
    final licensePaths = parameters.stringMap('licenses');
    final scope = parameters.presetScope('scope');
    final replacedSections = parameters.stringList('replacedSections');
    if (scope != ProjectPresentationPresetScope.complete &&
        replacedSections.isEmpty) {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.sections_required',
        'Scoped presets must announce the sections they replace.',
      );
    }
    final scopedProfile = projectPresentationPresetProfileForScope(
      profile: profile,
      scope: scope,
    );
    if (!projectPresentationPresetScopeHasContent(scopedProfile, scope) ||
        !projectPresentationPresetSectionsAreValid(
          profile: scopedProfile,
          scope: scope,
          sections: replacedSections,
        )) {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.scope_invalid',
        'The announced sections must match the exported preset scope.',
      );
    }
    _ensurePresetAbsent(context.snapshot.manifest, id);
    final pack = _buildExportPack(
      context.snapshot,
      id: id,
      label: label,
      description: description,
      profile: scopedProfile,
      scope: scope,
      replacedSections: replacedSections,
      licensePaths: licensePaths,
    );
    final bytes = codec.encode(pack);
    final stored = await _artifactStore.put(bytes);
    final record = _recordFromPack(pack);
    final projected = context.snapshot.manifest.copyWith(
      presentationPresets: <ProjectPresentationPresetRecord>[
        ...context.snapshot.manifest.presentationPresets,
        record,
      ],
    );
    return _projectDraft(
      context.snapshot,
      projected,
      operation: 'presentation.preset.export',
      path: '/presentationPresets/${record.id}',
      after: record.toJson(),
      preview: <String, Object?>{
        'preset': record.toJson(),
        'archiveSha256': stored.reference.digest,
        'archiveBytes': stored.reference.byteLength,
      },
      artifacts: <AuthoringArtifactRef>[
        _artifactRef(stored.reference),
      ],
    );
  }

  Future<AuthoringMutationDraft> _import(
    AuthoringPlanningContext context,
    _Parameters parameters,
  ) async {
    parameters.allow(const <String>{'artifactHandle'});
    final handle = parameters.string('artifactHandle');
    final reference = _artifactStore.inspect(handle);
    if (reference == null) {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.artifact_unknown',
        'The staged preset artifact is unknown or expired.',
      );
    }
    late final ProjectPresentationPresetPack pack;
    try {
      pack = codec.decode(await _artifactStore.read(handle));
    } on PresentationPresetPackException catch (error) {
      throw PresentationPresetAuthoringException(error.code, error.message);
    }
    _ensurePresetAbsent(context.snapshot.manifest, pack.manifest.id);
    final record = _recordFromPack(pack);
    final projected = context.snapshot.manifest.copyWith(
      presentation: applyProjectPresentationPresetScope(
        current: context.snapshot.manifest.effectivePresentation,
        preset: pack.profile,
        scope: pack.manifest.scope,
      ),
      presentationPresets: <ProjectPresentationPresetRecord>[
        ...context.snapshot.manifest.presentationPresets,
        record,
      ],
    );
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    _addProjectChange(
      context.snapshot,
      projected,
      changes,
      diffs,
      operation: AuthoringDiffOperation.add,
      path: '/presentationPresets/${record.id}',
      after: <String, Object?>{
        'preset': record.toJson(),
        'presentation': projected.effectivePresentation.toJson(),
        'scope': pack.manifest.scope.name,
        'replacedSections': pack.manifest.replacedSections,
      },
    );
    _addImportedAssets(context.snapshot, pack, changes, diffs);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: changes,
        diff: AuthoringDiff(diffs),
      ),
      preview: <String, Object?>{
        'staged': true,
        'willApply': true,
        'preset': record.toJson(),
        'assetCount': record.assets.length,
      },
      artifacts: <AuthoringArtifactRef>[_artifactRef(reference)],
    );
  }

  Future<AuthoringMutationDraft> _delete(
    AuthoringPlanningContext context,
    _Parameters parameters,
  ) async {
    parameters.allow(const <String>{'presetId'});
    final id = parameters.string('presetId');
    final records = context.snapshot.manifest.presentationPresets;
    final index = records.indexWhere((preset) => preset.id == id);
    if (index < 0) {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.not_found',
        'The requested presentation preset does not exist.',
      );
    }
    final before = records[index];
    final projected = context.snapshot.manifest.copyWith(
      presentationPresets: <ProjectPresentationPresetRecord>[
        ...records.take(index),
        ...records.skip(index + 1),
      ],
    );
    return _projectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/presentationPresets/$id',
      before: before.toJson(),
      preview: <String, Object?>{
        'presetId': id,
        'assetCleanup': 'retained-shared-assets',
      },
    );
  }
}

ProjectPresentationPresetPack _buildExportPack(
  ProjectSnapshot snapshot, {
  required String id,
  required String label,
  required String description,
  required ProjectPresentationProfile profile,
  required ProjectPresentationPresetScope scope,
  required List<String> replacedSections,
  required Map<String, String> licensePaths,
}) {
  final catalog = _catalog(snapshot);
  final files = <String, Uint8List>{};
  final assets = <PresentationPresetAsset>[];
  final references = presentationPresetAssetReferences(profile);
  for (final reference in references) {
    final asset = catalog.findByLogicalPath(reference.projectPath);
    if (asset == null) {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.asset_unmanaged',
        'Every exported preset asset must belong to the project asset catalog.',
      );
    }
    final licensePath =
        reference.licenseProjectPath ?? licensePaths[reference.projectPath];
    if (licensePath == null) {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.license_required',
        'Choose a redistribution license for every exported preset asset.',
      );
    }
    final license = catalog.findByLogicalPath(licensePath);
    if (license == null || license.artifact.mediaType != 'text/plain') {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.license_invalid',
        'Preset licenses must be managed UTF-8 text assets.',
      );
    }
    final assetBytes = _blobBytes(snapshot, asset.artifact);
    final licenseBytes = _blobBytes(snapshot, license.artifact);
    final assetSha256 = presentationPresetFileSha256(assetBytes);
    final licenseSha256 = presentationPresetFileSha256(licenseBytes);
    final assetArchivePath =
        'assets/$assetSha256${_extension(reference.projectPath)}';
    final licenseArchivePath = 'licenses/$licenseSha256.txt';
    files[assetArchivePath] = Uint8List.fromList(assetBytes);
    files[licenseArchivePath] = Uint8List.fromList(licenseBytes);
    assets.add(
      PresentationPresetAsset(
        projectPath: reference.projectPath,
        archivePath: assetArchivePath,
        mediaType: asset.artifact.mediaType,
        sizeBytes: asset.artifact.byteLength,
        sha256: assetSha256,
        licenseProjectPath: licensePath,
        licenseArchivePath: licenseArchivePath,
        licenseSizeBytes: license.artifact.byteLength,
        licenseSha256: licenseSha256,
      ),
    );
  }
  return ProjectPresentationPresetPack(
    manifest: PresentationPresetPackManifest(
      id: id,
      label: label,
      description: description,
      compatibility: const PresentationPresetCompatibility(
        minimumProfileSchemaVersion:
            ProjectPresentationProfile.supportedSchemaVersion,
        maximumProfileSchemaVersion:
            ProjectPresentationProfile.supportedSchemaVersion,
      ),
      scope: scope,
      replacedSections: replacedSections,
      assets: assets,
    ),
    profile: profile,
    files: files,
  );
}

void _addImportedAssets(
  ProjectSnapshot snapshot,
  ProjectPresentationPresetPack pack,
  List<AuthoringResourceChange> changes,
  List<AuthoringDiffEntry> diffs,
) {
  final beforeBytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  final catalog = _catalog(snapshot);
  final records = <AssetRecord>[...catalog.records];
  final knownDigests = records.map((record) => record.artifact.digest).toSet();
  final additions = <({AssetRecord record, List<int> bytes})>[];
  var nextIndex = 0;

  void stage(String path, String mediaType, List<int> bytes) {
    final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: mediaType);
    final existing = records.where((record) => record.logicalPath == path);
    if (existing.isNotEmpty) {
      if (existing.single.artifact.digest != artifact.digest) {
        throw const PresentationPresetAuthoringException(
          'presentation.preset.asset_conflict',
          'A preset asset conflicts with an existing project path.',
        );
      }
      return;
    }
    String assetId;
    do {
      assetId = 'presentation-${pack.manifest.id}-${nextIndex++}';
    } while (records.any((record) => record.id == assetId));
    final record = AssetRecord(
      id: assetId,
      logicalPath: path,
      artifact: artifact,
      tags: <String>['presentation-preset', pack.manifest.id],
    );
    records.add(record);
    additions.add((record: record, bytes: bytes));
  }

  for (final asset in pack.manifest.assets) {
    stage(
      asset.projectPath,
      asset.mediaType,
      pack.files[asset.archivePath]!,
    );
    stage(
      asset.licenseProjectPath!,
      'text/plain',
      pack.files[asset.licenseArchivePath!]!,
    );
  }
  if (additions.isEmpty) return;
  final afterCatalog = AssetCatalog(records: records);
  final catalogResource = AuthoringResourceRef(
    kind: 'assetCatalog',
    id: 'project',
    revision: snapshot.resourceFingerprints[assetCatalogResourceIdentity],
  );
  changes.add(
    AuthoringResourceChange(
      resource: catalogResource,
      storageKey: assetCatalogStorageKey,
      beforeBytes: beforeBytes,
      afterBytes: _encodeCatalog(afterCatalog),
    ),
  );
  diffs.add(
    AuthoringDiffEntry(
      operation: beforeBytes == null
          ? AuthoringDiffOperation.add
          : AuthoringDiffOperation.replace,
      resource: catalogResource,
      path: '/records',
      before: beforeBytes == null ? null : catalog.toJson(),
      after: afterCatalog.toJson(),
    ),
  );
  for (final addition in additions) {
    final artifact = addition.record.artifact;
    if (!knownDigests.add(artifact.digest)) continue;
    final resource = AuthoringResourceRef(
      kind: 'assetBlob',
      id: artifact.digest,
    );
    changes.add(
      AuthoringResourceChange(
        resource: resource,
        storageKey: assetBlobStorageKey(artifact),
        beforeBytes: null,
        afterBytes: addition.bytes,
      ),
    );
    diffs.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.add,
        resource: resource,
        path: '/',
        after: artifact.toJson(),
      ),
    );
  }
}

AuthoringMutationDraft _projectDraft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
  required Map<String, Object?> preview,
  Iterable<AuthoringArtifactRef> artifacts = const <AuthoringArtifactRef>[],
}) {
  final changes = <AuthoringResourceChange>[];
  final diffs = <AuthoringDiffEntry>[];
  _addProjectChange(
    snapshot,
    projected,
    changes,
    diffs,
    operation: before == null
        ? AuthoringDiffOperation.add
        : after == null
            ? AuthoringDiffOperation.remove
            : AuthoringDiffOperation.replace,
    path: path,
    before: before,
    after: after,
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: changes,
      diff: AuthoringDiff(diffs),
    ),
    preview: <String, Object?>{'operation': operation, ...preview},
    artifacts: artifacts,
  );
}

void _addProjectChange(
  ProjectSnapshot snapshot,
  ProjectManifest projected,
  List<AuthoringResourceChange> changes,
  List<AuthoringDiffEntry> diffs, {
  required AuthoringDiffOperation operation,
  required String path,
  Object? before,
  Object? after,
}) {
  final resource = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  changes.add(
    AuthoringResourceChange(
      resource: resource,
      storageKey: 'project.json',
      beforeBytes: snapshot.resourceBytes('project'),
      afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
    ),
  );
  diffs.add(
    AuthoringDiffEntry(
      operation: operation,
      resource: resource,
      path: path,
      before: before,
      after: after,
    ),
  );
}

ProjectPresentationPresetRecord _recordFromPack(
  ProjectPresentationPresetPack pack,
) =>
    ProjectPresentationPresetRecord(
      id: pack.manifest.id,
      label: pack.manifest.label,
      description: pack.manifest.description,
      profile: pack.profile,
      scope: pack.manifest.scope,
      replacedSections: pack.manifest.replacedSections,
      assets: <ProjectPresentationPresetAssetReference>[
        for (final asset in pack.manifest.assets)
          ProjectPresentationPresetAssetReference(
            projectPath: asset.projectPath,
            mediaType: asset.mediaType,
            sizeBytes: asset.sizeBytes,
            sha256: asset.sha256,
            licenseProjectPath: asset.licenseProjectPath!,
          ),
      ],
    );

List<({String projectPath, String? licenseProjectPath})>
    presentationPresetAssetReferences(ProjectPresentationProfile profile) {
  final references = <({String projectPath, String? licenseProjectPath})>[];
  final seen = <String>{};
  void add(String? path, {String? licensePath}) {
    if (path != null && seen.add(path)) {
      references.add((projectPath: path, licenseProjectPath: licensePath));
    }
  }

  void addVideo(ProjectResponsiveVideoProfile? media) {
    if (media == null) return;
    for (final variant in <ProjectVideoVariantProfile>[
      media.landscape,
      if (media.portrait case final portrait?) portrait,
    ]) {
      add(variant.videoPath);
      add(variant.posterPath);
      add(variant.captionsPath);
    }
  }

  add(profile.branding.iconPath);
  add(profile.branding.coverPath);
  add(profile.branding.heroPath);
  add(profile.pause?.background?.imagePath);
  add(profile.branding.titleMusicPath);
  addVideo(profile.intro?.media);
  addVideo(profile.titleMotion?.promptLoop);
  addVideo(profile.titleMotion?.menuLoop);
  if (profile.typography case final typography?) {
    for (final role in <ProjectTypographyRoleProfile>[
      typography.display,
      typography.body,
      typography.dialogue,
      typography.numbers,
    ]) {
      add(role.fontPath, licensePath: role.licensePath);
    }
  }
  references
      .sort((left, right) => left.projectPath.compareTo(right.projectPath));
  return List.unmodifiable(references);
}

AssetCatalog _catalog(ProjectSnapshot snapshot) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) return AssetCatalog();
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw const PresentationPresetAuthoringException(
      'presentation.preset.asset_catalog_invalid',
      'The project asset catalog is invalid.',
    );
  }
}

List<int> _blobBytes(ProjectSnapshot snapshot, ContentArtifactRef artifact) {
  final bytes = snapshot.findResourceBytes(
    assetBlobResourceIdentity(artifact.digest),
  );
  if (bytes == null) {
    throw const PresentationPresetAuthoringException(
      'presentation.preset.asset_blob_missing',
      'A managed preset asset blob is unavailable.',
    );
  }
  return bytes;
}

List<int> _encodeCatalog(AssetCatalog catalog) => utf8.encode(
      '${const JsonEncoder.withIndent('  ').convert(catalog.toJson())}\n',
    );

String _extension(String path) {
  final slash = path.lastIndexOf('/');
  final dot = path.lastIndexOf('.');
  if (dot <= slash || dot == path.length - 1) return '.bin';
  return path.substring(dot).toLowerCase();
}

void _ensurePresetAbsent(ProjectManifest manifest, String id) {
  if (manifest.presentationPresets.any((preset) => preset.id == id)) {
    throw const PresentationPresetAuthoringException(
      'presentation.preset.already_exists',
      'A presentation preset already uses this identity.',
    );
  }
}

void _requireMode(String actionId, bool dryRun) {
  if (actionId.endsWith('_plan') && !dryRun) {
    throw const PresentationPresetAuthoringException(
      'presentation.preset.plan_requires_dry_run',
      'Preset plan actions require dryRun=true.',
    );
  }
  if (actionId.endsWith('_apply') && dryRun) {
    throw const PresentationPresetAuthoringException(
      'presentation.preset.apply_requires_commit',
      'Preset apply actions require dryRun=false.',
    );
  }
}

AuthoringArtifactRef _artifactRef(ContentArtifactRef reference) =>
    AuthoringArtifactRef(
      id: reference.digest,
      mediaType: reference.mediaType,
      uri: reference.handle,
      byteLength: reference.byteLength,
      sha256: reference.digest,
    );

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
      resourceKinds: const <String>[
        'project',
        'projectPresentationPreset',
        'projectPresentationProfile',
        'asset',
      ],
      capabilityIds: const <String>['authoring.presentation.presets'],
      requiredPermissions: const <AuthoringPermission>[
        AuthoringPermission.projectWrite,
        AuthoringPermission.assetWrite,
      ],
      guarantees: const <AuthoringGuarantee>[
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

final class _Parameters {
  _Parameters(this.values);

  final Map<String, Object?> values;

  void allow(Set<String> allowed) {
    if (values.keys.toSet().difference(allowed).isNotEmpty) {
      throw const PresentationPresetAuthoringException(
        'presentation.preset.parameter_unsupported',
        'Preset action parameters contain unsupported fields.',
      );
    }
  }

  String string(String key) {
    final value = values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw PresentationPresetAuthoringException(
        'presentation.preset.parameter_invalid',
        'Preset parameter $key must be a non-empty string.',
      );
    }
    return value;
  }

  Map<String, String> stringMap(String key) {
    final value = values[key];
    if (value is! Map || value.keys.any((item) => item is! String)) {
      throw PresentationPresetAuthoringException(
        'presentation.preset.parameter_invalid',
        'Preset parameter $key must be a string map.',
      );
    }
    final result = <String, String>{};
    for (final entry in value.entries) {
      if (entry.value is! String) {
        throw PresentationPresetAuthoringException(
          'presentation.preset.parameter_invalid',
          'Preset parameter $key must be a string map.',
        );
      }
      result[entry.key as String] = entry.value as String;
    }
    return result;
  }

  ProjectPresentationPresetScope presetScope(String key) {
    final value = values[key];
    if (value == null) return ProjectPresentationPresetScope.complete;
    if (value is! String) {
      throw PresentationPresetAuthoringException(
        'presentation.preset.parameter_invalid',
        'Preset parameter $key must be a supported scope.',
      );
    }
    return ProjectPresentationPresetScope.values.firstWhere(
      (scope) => scope.name == value,
      orElse: () => throw PresentationPresetAuthoringException(
        'presentation.preset.parameter_invalid',
        'Preset parameter $key must be a supported scope.',
      ),
    );
  }

  List<String> stringList(String key) {
    final value = values[key];
    if (value == null) return const <String>[];
    if (value is! List || value.any((entry) => entry is! String)) {
      throw PresentationPresetAuthoringException(
        'presentation.preset.parameter_invalid',
        'Preset parameter $key must be a string list.',
      );
    }
    final result = value.cast<String>();
    if (result.toSet().length != result.length ||
        result.any((entry) => entry.trim().isEmpty || entry != entry.trim())) {
      throw PresentationPresetAuthoringException(
        'presentation.preset.parameter_invalid',
        'Preset parameter $key must contain unique section paths.',
      );
    }
    return List<String>.unmodifiable(result);
  }
}
