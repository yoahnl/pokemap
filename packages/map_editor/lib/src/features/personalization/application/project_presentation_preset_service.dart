import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../application/authoring_api/editor_receipt_presenter.dart';

final class ProjectPresentationPresetService {
  const ProjectPresentationPresetService({
    required this.mutations,
    required this.queries,
  });

  final AuthoringMutationAdapter mutations;
  final AuthoringQueryAdapter queries;

  Future<void> exportCurrent({
    required String projectRootPath,
    required String presetId,
    required String label,
    required String description,
    required String destinationPath,
    Map<String, String> licenses = const <String, String>{},
    String? redistributionLicenseSourcePath,
    ProjectPresentationPresetScope scope =
        ProjectPresentationPresetScope.complete,
    List<String> replacedSections = const <String>[],
  }) async {
    final effectiveLicenses = await _catalogPresentationAssets(
      projectRootPath,
      licenses,
      redistributionLicenseSourcePath: redistributionLicenseSourcePath,
    );
    final identity = _identity('preset_export');
    final plan = await mutations.plan(
      projectRootPath,
      actionId: 'presentation.preset.export',
      parameters: <String, Object?>{
        'presetId': presetId,
        'label': label,
        'description': description,
        'licenses': effectiveLicenses,
        'scope': scope.name,
        'replacedSections': replacedSections,
      },
      idempotencyKey: identity,
      requestId: identity,
    );
    final artifact = plan.receipt.artifacts.single;
    await mutations.apply(plan, operationId: identity);
    final bytes = await mutations.readArtifact(
      projectRootPath,
      handle: artifact.uri,
    );
    await _writeAtomically(destinationPath, bytes);
  }

  Future<Map<String, String>> _catalogPresentationAssets(
    String projectRootPath,
    Map<String, String> licenses, {
    String? redistributionLicenseSourcePath,
  }) async {
    final session = await queries.open(projectRootPath);
    final profile = session.manifest.presentation;
    if (profile == null) return licenses;
    final references = presentationPresetAssetReferences(profile);
    if (references.isEmpty) return licenses;
    final effectiveLicenses = <String, String>{};
    final staged = <String, EditorStagedArtifact>{};
    String? sharedLicensePath;
    if (redistributionLicenseSourcePath != null) {
      final sharedLicense = await _stageLicense(
        projectRootPath,
        sourcePath: redistributionLicenseSourcePath,
      );
      sharedLicensePath =
          'assets/presentation/licenses/${sharedLicense.reference.hexDigest}.txt';
      staged[sharedLicensePath] = sharedLicense;
    }
    for (final reference in references) {
      final licensePath =
          reference.licenseProjectPath ??
          licenses[reference.projectPath] ??
          sharedLicensePath;
      if (licensePath == null) {
        throw const ProjectPresentationPresetExportException(
          'presentation.preset.license_required',
          'Choose a redistribution license for every exported preset asset.',
        );
      }
      effectiveLicenses[reference.projectPath] = licensePath;
    }
    final requiredPaths = <String>{
      for (final reference in references) reference.projectPath,
      for (final reference in references) ?reference.licenseProjectPath,
      for (final path in effectiveLicenses.values) path,
    };
    final licensePaths = <String>{
      for (final reference in references) ?reference.licenseProjectPath,
      ...effectiveLicenses.values,
    };
    for (final logicalPath in requiredPaths) {
      if (staged.containsKey(logicalPath)) continue;
      final sourcePath = await _resolveProjectFile(
        projectRootPath,
        logicalPath,
      );
      staged[logicalPath] = licensePaths.contains(logicalPath)
          ? await _stageLicense(projectRootPath, sourcePath: sourcePath)
          : await mutations.stageArtifact(
              projectRootPath,
              sourcePath: sourcePath,
            );
    }
    final records = await _assetRecords(session);
    final knownIds = records.values.map((record) => record.id).toSet();
    for (final logicalPath in requiredPaths.toList()..sort()) {
      final artifact = staged[logicalPath]!.reference;
      final current = records[logicalPath];
      if (current?.artifact.digest == artifact.digest) continue;
      final identity = _identity('preset_asset');
      final actionId = current == null ? 'asset.import' : 'asset.replace';
      final parameters = current == null
          ? <String, Object?>{
              'artifactHandle': artifact.handle,
              'assetId': _assetId(artifact, knownIds),
              'logicalPath': logicalPath,
              'tags': <String>[
                licensePaths.contains(logicalPath)
                    ? 'presentation-license'
                    : 'presentation-media',
              ],
              'usages': const <String>['personalization-studio'],
            }
          : <String, Object?>{
              'artifactHandle': artifact.handle,
              'assetId': current.id,
            };
      final plan = await mutations.plan(
        projectRootPath,
        actionId: actionId,
        parameters: parameters,
        idempotencyKey: identity,
        requestId: identity,
      );
      await mutations.apply(plan, operationId: identity);
      records[logicalPath] = current == null
          ? AssetRecord(
              id: parameters['assetId']! as String,
              logicalPath: logicalPath,
              artifact: artifact,
              tags: parameters['tags']! as List<String>,
              usages: parameters['usages']! as List<String>,
            )
          : current.copyWith(artifact: artifact);
    }
    return effectiveLicenses;
  }

  Future<EditorStagedArtifact> _stageLicense(
    String projectRootPath, {
    required String sourcePath,
  }) async {
    try {
      final staged = await mutations.stageArtifact(
        projectRootPath,
        sourcePath: sourcePath,
        declaredMediaType: 'text/plain',
      );
      final bytes = await mutations.readArtifact(
        projectRootPath,
        handle: staged.reference.handle,
      );
      if (utf8.decode(bytes).trim().isEmpty) {
        throw const ProjectPresentationPresetExportException(
          'presentation.preset.license_invalid',
          'Choose a non-empty UTF-8 text redistribution license.',
        );
      }
      return staged;
    } on ProjectPresentationPresetExportException {
      rethrow;
    } on FormatException {
      throw const ProjectPresentationPresetExportException(
        'presentation.preset.license_invalid',
        'Choose a non-empty UTF-8 text redistribution license.',
      );
    } on EditorAuthoringMutationFailure catch (error) {
      if (error.message.contains('artifact.mime_mismatch')) {
        throw const ProjectPresentationPresetExportException(
          'presentation.preset.license_invalid',
          'Choose a non-empty UTF-8 text redistribution license.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, AssetRecord>> _assetRecords(
    EditorAuthoringReadSession session,
  ) async {
    final records = <String, AssetRecord>{};
    String? cursor;
    do {
      final page = AuthoringQueryPage.fromJson(
        session.query(
          AuthoringQueryRequest(
            resourceKind: 'asset',
            operation: AuthoringQueryOperation.list,
            view: AuthoringQueryView.detail,
            pageSize: 200,
            cursor: cursor,
          ),
        ),
      );
      for (final item in page.items) {
        final rawArtifact = item['artifact']! as Map;
        final record = AssetRecord(
          id: item['id']! as String,
          logicalPath: item['logicalPath']! as String,
          artifact: ContentArtifactRef.fromJson(
            Map<String, dynamic>.from(rawArtifact),
          ),
          usages: (item['usages']! as List).cast<String>(),
          tags: (item['tags']! as List).cast<String>(),
        );
        records[record.logicalPath] = record;
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return records;
  }

  Future<String> _resolveProjectFile(
    String projectRootPath,
    String logicalPath,
  ) async {
    final normalized = p.posix.normalize(logicalPath);
    if (logicalPath.isEmpty ||
        logicalPath.contains('\\') ||
        p.posix.isAbsolute(logicalPath) ||
        p.windows.isAbsolute(logicalPath) ||
        normalized != logicalPath ||
        normalized == '.' ||
        normalized.startsWith('../')) {
      throw ArgumentError.value(logicalPath, 'logicalPath');
    }
    final root = await Directory(projectRootPath).resolveSymbolicLinks();
    final source = await File(
      p.joinAll(<String>[root, ...logicalPath.split('/')]),
    ).resolveSymbolicLinks();
    if (!p.isWithin(root, source)) {
      throw ArgumentError.value(logicalPath, 'logicalPath');
    }
    return source;
  }

  String _assetId(ContentArtifactRef artifact, Set<String> knownIds) {
    final prefix = 'presentation-${artifact.hexDigest.substring(0, 16)}';
    var candidate = prefix;
    var suffix = 1;
    while (!knownIds.add(candidate)) {
      candidate = '$prefix-${suffix++}';
    }
    return candidate;
  }

  Future<void> importAndApply({
    required String projectRootPath,
    required String sourcePath,
  }) async {
    final staged = await mutations.stageArtifact(
      projectRootPath,
      sourcePath: sourcePath,
      declaredMediaType: 'application/vnd.pokemap.presentation-preset+zip',
    );
    final identity = _identity('preset_import');
    final plan = await mutations.plan(
      projectRootPath,
      actionId: 'presentation.preset.import_apply',
      parameters: <String, Object?>{'artifactHandle': staged.reference.handle},
      idempotencyKey: identity,
      requestId: identity,
    );
    await mutations.apply(plan, operationId: identity);
  }

  Future<void> delete({
    required String projectRootPath,
    required String presetId,
  }) async {
    final identity = _identity('preset_delete');
    final plan = await mutations.plan(
      projectRootPath,
      actionId: 'presentation.preset.delete_apply',
      parameters: <String, Object?>{'presetId': presetId},
      idempotencyKey: identity,
      requestId: identity,
    );
    final confirmation = await mutations.confirm(plan);
    await mutations.apply(
      plan,
      operationId: identity,
      confirmationToken: confirmation,
    );
  }

  Future<void> _writeAtomically(String destinationPath, List<int> bytes) async {
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    final staging = File(
      '$destinationPath.pokemap-${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    final backup = File('$staging.bak');
    try {
      await staging.writeAsBytes(bytes, flush: true);
      try {
        await staging.rename(destination.path);
      } on FileSystemException {
        if (!await destination.exists()) rethrow;
        await destination.rename(backup.path);
        try {
          await staging.rename(destination.path);
        } on Object {
          if (!await destination.exists() && await backup.exists()) {
            await backup.rename(destination.path);
          }
          rethrow;
        }
        await backup.delete();
      }
    } finally {
      if (await staging.exists()) await staging.delete();
      if (await backup.exists() && await destination.exists()) {
        await backup.delete();
      }
    }
  }
}

final class ProjectPresentationPresetExportException implements Exception {
  const ProjectPresentationPresetExportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'ProjectPresentationPresetExportException($code): $message';
}

String _identity(String prefix) =>
    '${prefix}_${DateTime.now().toUtc().microsecondsSinceEpoch}';
