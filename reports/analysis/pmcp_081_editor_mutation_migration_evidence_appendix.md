# Appendice PMCP-081 — Contenu intégral des fichiers créés

Cet appendice accompagne `pmcp_081_editor_mutation_migration_evidence.md` et reproduit les fichiers source/test créés par le lot.

## `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_query_adapter.dart';
import 'editor_receipt_presenter.dart';

abstract interface class EditorProjectRootLocator {
  Future<String> locateForResource(String resourcePath);
}

final class EditorAuthoringMutationPlan {
  const EditorAuthoringMutationPlan._({
    required this.projectRootPath,
    required this.planId,
    required this.snapshotRevision,
    required this.receipt,
  });

  final String projectRootPath;
  final String planId;
  final String snapshotRevision;
  final AuthoringReceipt receipt;
}

final class EditorAuthoringMutationResult {
  const EditorAuthoringMutationResult({
    required this.receipt,
    required this.snapshotRevision,
    this.resourceRevision,
  });

  final AuthoringReceipt receipt;
  final String snapshotRevision;
  final String? resourceRevision;
}

/// Direct-Dart bridge from editor gestures to canonical plan/apply/history.
///
/// The adapter owns only session composition and editor CAS translation. All
/// domain planning, authorization, confirmation, idempotency, transaction,
/// history, and recovery behavior remains inside `map_authoring`.
final class AuthoringMutationAdapter {
  AuthoringMutationAdapter({
    required ProjectFileReader fileReader,
    required AuthoringQueryAdapter queries,
    required EditorProjectRootLocator projectRoots,
  })  : _fileReader = fileReader,
        _queries = queries,
        _projectRoots = projectRoots;

  final ProjectFileReader _fileReader;
  final AuthoringQueryAdapter _queries;
  final EditorProjectRootLocator _projectRoots;
  final Map<String, Future<_EditorMutationSession>> _sessions = {};
  int _identityCounter = 0;
  AuthoringReceipt? _lastAppliedReceipt;

  AuthoringReceipt? get lastAppliedReceipt => _lastAppliedReceipt;

  Future<EditorAuthoringMutationPlan> plan(
    String projectRootPath, {
    required String actionId,
    required Map<String, Object?> parameters,
    required String idempotencyKey,
    String? requestId,
    String? expectedRevision,
  }) async {
    try {
      final session = await _open(projectRootPath);
      final snapshot = await session.snapshot();
      final response = await session.mutations.plan(
        session.projectHandle,
        AuthoringRequest(
          requestId: requestId ?? _identity('editor_request'),
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: session.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: expectedRevision ?? snapshot.revision,
          idempotencyKey: idempotencyKey,
          // `plan` is non-mutating regardless. `dryRun: true` deliberately
          // creates a preview-only plan that the canonical API refuses to
          // apply, so editor plans intended for confirmation use `false`.
          dryRun: false,
        ),
      );
      return EditorAuthoringMutationPlan._(
        projectRootPath: session.canonicalRoot,
        planId: response['planId']! as String,
        snapshotRevision: response['snapshotRevision']! as String,
        receipt: _receipt(response),
      );
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<String> confirm(EditorAuthoringMutationPlan plan) async {
    try {
      final session = await _open(plan.projectRootPath);
      final response = await session.mutations.confirm(
        session.projectHandle,
        planId: plan.planId,
      );
      return response['confirmationToken']! as String;
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<EditorAuthoringMutationResult> apply(
    EditorAuthoringMutationPlan plan, {
    required String operationId,
    String? confirmationToken,
  }) async {
    try {
      final session = await _open(plan.projectRootPath);
      final response = await session.mutations.apply(
        session.projectHandle,
        planId: plan.planId,
        operationId: operationId,
        confirmationToken: confirmationToken,
      );
      final result = EditorAuthoringMutationResult(
        receipt: _receipt(response),
        snapshotRevision: response['snapshotRevision']! as String,
      );
      _lastAppliedReceipt = result.receipt;
      await _queries.invalidate(session.canonicalRoot);
      return result;
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<EditorAuthoringMutationResult> undo(
    String projectRootPath, {
    required String entryId,
    required String idempotencyKey,
  }) async {
    try {
      final session = await _open(projectRootPath);
      final response = await session.mutations.undo(
        session.projectHandle,
        entryId: entryId,
        idempotencyKey: idempotencyKey,
      );
      final result = EditorAuthoringMutationResult(
        receipt: _receipt(response),
        snapshotRevision: response['snapshotRevision']! as String,
      );
      _lastAppliedReceipt = result.receipt;
      await _queries.invalidate(session.canonicalRoot);
      return result;
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  Future<EditorAuthoringMutationResult> recover(
    String projectRootPath, {
    required String operationId,
  }) async {
    try {
      final session = await _open(projectRootPath);
      final response = await session.mutations.recover(
        session.projectHandle,
        operationId: operationId,
      );
      final result = EditorAuthoringMutationResult(
        receipt: _receipt(response),
        snapshotRevision: response['snapshotRevision']! as String,
      );
      _lastAppliedReceipt = result.receipt;
      await _queries.invalidate(session.canonicalRoot);
      return result;
    } on Object catch (error) {
      throw EditorAuthoringMutationFailure.capture(error);
    }
  }

  /// Canonical product path for saving one already-declared map document.
  Future<EditorAuthoringMutationResult> saveMap(
    MapData map,
    String resourcePath, {
    required String expectedMapRevision,
  }) async {
    final root = await _projectRoots.locateForResource(resourcePath);
    try {
      final session = await _open(root);
      final before = await session.snapshot();
      final identity = 'map:${map.id}';
      if (!before.resourceFingerprints.containsKey(identity)) {
        throw const EditorConflictException(
          'The map is not declared by the current Authoring snapshot.',
        );
      }
      final liveMapRevision =
          narrativeEventBytesFingerprint(before.resourceBytes(identity));
      if (liveMapRevision != expectedMapRevision) {
        throw const EditorConflictException(
          'The map changed outside the editor.',
        );
      }
      final key = _identity('editor_map_save');
      final mutationPlan = await plan(
        session.canonicalRoot,
        actionId: 'map.save',
        parameters: {'map': map.toJson()},
        idempotencyKey: key,
        requestId: key,
        expectedRevision: before.revision,
      );
      final applied = await apply(mutationPlan, operationId: key);
      final after = await session.snapshot();
      final mapRevision =
          narrativeEventBytesFingerprint(after.resourceBytes(identity));
      return EditorAuthoringMutationResult(
        receipt: applied.receipt,
        snapshotRevision: after.revision,
        resourceRevision: mapRevision,
      );
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflictCode(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }

  Future<void> closeAll() async {
    final sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    for (final opening in sessions) {
      await (await opening).close();
    }
  }

  Future<_EditorMutationSession> _open(String projectRootPath) async {
    final canonicalRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    final current = _sessions[canonicalRoot];
    if (current != null) return current;
    final opening = _EditorMutationSession.open(
      canonicalRoot: canonicalRoot,
      fileReader: _fileReader,
    );
    _sessions[canonicalRoot] = opening;
    try {
      return await opening;
    } on Object {
      if (identical(_sessions[canonicalRoot], opening)) {
        _sessions.remove(canonicalRoot);
      }
      rethrow;
    }
  }

  String _identity(String prefix) {
    _identityCounter++;
    return '${prefix}_${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_identityCounter';
  }
}

final class _EditorMutationSession {
  const _EditorMutationSession._({
    required this.canonicalRoot,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.reads,
    required this.mutations,
    required ProjectSnapshotLoader snapshots,
  }) : _snapshots = snapshots;

  static Future<_EditorMutationSession> open({
    required String canonicalRoot,
    required ProjectFileReader fileReader,
  }) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [canonicalRoot],
      fileReader: fileReader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final reads = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: fileReader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final opened = await reads.open(canonicalRoot);
    final workspaceHandle =
        WorkspaceHandle(opened['workspaceHandle']! as String);
    final projectHandle = ProjectHandle(opened['projectHandle']! as String);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    try {
      await mutations.attachProject(
        projectRootPath: canonicalRoot,
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
      );
      return _EditorMutationSession._(
        canonicalRoot: canonicalRoot,
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
        reads: reads,
        mutations: mutations,
        snapshots: snapshots,
      );
    } on Object {
      await reads.close(workspaceHandle);
      rethrow;
    }
  }

  final String canonicalRoot;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader _snapshots;

  Future<ProjectSnapshot> snapshot() => _snapshots.load(projectHandle);

  Future<void> close() async {
    await mutations.detachWorkspace(workspaceHandle);
    await reads.close(workspaceHandle);
  }
}

AuthoringReceipt _receipt(Map<String, Object?> response) {
  final raw = response['receipt'];
  if (raw is! Map) {
    throw const FormatException('Authoring response receipt is missing.');
  }
  return AuthoringReceipt.fromJson(Map<String, dynamic>.from(raw));
}

bool _isConflictCode(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
```

## `packages/map_editor/lib/src/application/authoring_api/editor_receipt_presenter.dart`

```dart
import 'package:map_authoring/map_authoring.dart';

/// Stable editor-side failure envelope that retains the Authoring domain code.
///
/// The original exception is optional and never serialized into UI state. The
/// code, message, and remediation remain lossless so a panel can offer reload,
/// confirmation, or retry without reverse-engineering exception text.
final class EditorAuthoringMutationFailure implements Exception {
  const EditorAuthoringMutationFailure({
    required this.code,
    required this.message,
    this.remediation = const [],
    this.original,
  });

  factory EditorAuthoringMutationFailure.capture(Object error) {
    if (error is EditorAuthoringMutationFailure) return error;
    String code = 'authoring.unexpected_failure';
    String message = error.toString();
    List<String> remediation = const [];
    // Authoring exceptions deliberately share `code` and `message` semantics
    // without a common base class. Read those public fields dynamically at
    // this one adapter boundary so new domain failures keep their exact code.
    try {
      final dynamic domain = error;
      final rawCode = domain.code;
      final rawMessage = domain.message;
      final rawRemediation = domain.remediation;
      if (rawCode is String && rawCode.trim().isNotEmpty) code = rawCode;
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage;
      }
      if (rawRemediation is Iterable) {
        remediation = rawRemediation
            .whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false);
      }
    } on Object {
      // The original exception still remains attached and its text is kept.
    }
    return EditorAuthoringMutationFailure(
      code: code,
      message: message,
      remediation: remediation,
      original: error,
    );
  }

  final String code;
  final String message;
  final List<String> remediation;
  final Object? original;

  @override
  String toString() => 'EditorAuthoringMutationFailure($code): $message';
}

final class EditorReceiptPresentation {
  const EditorReceiptPresentation({
    required this.code,
    required this.message,
    required this.isSuccess,
    this.isConflict = false,
    this.requiresConfirmation = false,
    this.remediation = const [],
  });

  final String code;
  final String message;
  final bool isSuccess;
  final bool isConflict;
  final bool requiresConfirmation;
  final List<String> remediation;
}

/// Converts protocol-neutral receipts/failures into no-code editor feedback.
final class EditorReceiptPresenter {
  const EditorReceiptPresenter();

  EditorReceiptPresentation receipt(AuthoringReceipt receipt) {
    final affected = receipt.affectedResources.length;
    final verb = switch (receipt.status) {
      AuthoringReceiptStatus.planned => 'préparée',
      AuthoringReceiptStatus.applied => 'appliquée',
      AuthoringReceiptStatus.recovered => 'récupérée',
    };
    return EditorReceiptPresentation(
      code: 'receipt.${receipt.status.wireName}',
      message: 'Modification $verb : $affected ressource(s) concernée(s).',
      isSuccess: true,
    );
  }

  EditorReceiptPresentation failure(EditorAuthoringMutationFailure failure) {
    final code = failure.code;
    final isConflict = code.contains('conflict') ||
        code.contains('stale') ||
        code.contains('revision');
    final confirmation = code.startsWith('confirmation.');
    final message = isConflict
        ? 'Le projet a changé en dehors de cet éditeur. Rechargez le projet '
            'avant de réessayer. ${failure.message}'
        : confirmation
            ? 'Cette modification demande une confirmation explicite. '
                '${failure.message}'
            : failure.message;
    return EditorReceiptPresentation(
      code: code,
      message: message,
      isSuccess: false,
      isConflict: isConflict,
      requiresConfirmation: confirmation,
      remediation: failure.remediation,
    );
  }
}
```

## `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AuthoringMutationAdapter', () {
    test('plans without writing, applies once, and replays idempotently',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final before = await File(fixture.mapPath).readAsBytes();
      final updated = fixture.map.copyWith(name: 'Edited through Authoring');

      final plan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {'map': updated.toJson()},
        idempotencyKey: 'editor_save_plan_01',
      );

      expect(await File(fixture.mapPath).readAsBytes(), before);
      expect(plan.receipt.status, AuthoringReceiptStatus.planned);
      expect(plan.receipt.actionId, 'map.save');

      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'editor_save_apply_01',
      );
      final replay = await fixture.mutations.apply(
        plan,
        operationId: 'editor_save_apply_01',
      );

      expect(replay.receipt.toJson(), applied.receipt.toJson());
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      expect((await FileMapRepository().loadMap(fixture.mapPath)).name,
          'Edited through Authoring');
    });

    test('product SaveMapUseCase returns Authoring receipt parity', () async {
      final direct = await _MutationFixture.create();
      final product = await _MutationFixture.create();
      addTearDown(direct.dispose);
      addTearDown(product.dispose);
      final directMap = direct.map.copyWith(name: 'Receipt parity');
      final productMap = product.map.copyWith(name: 'Receipt parity');

      final directPlan = await direct.mutations.plan(
        direct.root.path,
        actionId: 'map.save',
        parameters: {'map': directMap.toJson()},
        idempotencyKey: 'direct_receipt_parity',
      );
      final directResult = await direct.mutations.apply(
        directPlan,
        operationId: 'direct_receipt_parity',
      );

      final legacyDocument =
          await FileMapRepository().loadMapDocument(product.mapPath);
      final useCase = SaveMapUseCase(
        FileMapRepository(),
        authoringMutations: product.mutations,
      );
      final productRevision = await useCase.executeRevisioned(
        productMap,
        product.mapPath,
        expectedRevision: legacyDocument.revision,
        projectDialogueContext: product.project,
      );
      final productReceipt = product.mutations.lastAppliedReceipt;

      expect(productRevision, isNotNull);
      expect(productReceipt, isNotNull);
      expect(
        _stableReceipt(productReceipt!),
        _stableReceipt(directResult.receipt),
      );
    });

    test('stale external bytes are visible and never overwritten', () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final baseline =
          await FileMapRepository().loadMapDocument(fixture.mapPath);
      final local = fixture.map.copyWith(name: 'Local edit');
      await FileMapRepository().saveMap(
        fixture.map.copyWith(name: 'External edit'),
        fixture.mapPath,
        projectDialogueContext: fixture.project,
      );
      final useCase = SaveMapUseCase(
        FileMapRepository(),
        authoringMutations: fixture.mutations,
      );

      await expectLater(
        () => useCase.executeRevisioned(
          local,
          fixture.mapPath,
          expectedRevision: baseline.revision,
          projectDialogueContext: fixture.project,
        ),
        throwsA(isA<EditorConflictException>()),
      );
      expect((await FileMapRepository().loadMap(fixture.mapPath)).name,
          'External edit');
    });

    test('undo is a forward history receipt and restores exact map semantics',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final plan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {
          'map': fixture.map.copyWith(name: 'Undo me').toJson(),
        },
        idempotencyKey: 'editor_history_apply_01',
      );
      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'editor_history_apply_01',
      );

      final undone = await fixture.mutations.undo(
        fixture.root.path,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'editor_history_undo_01',
      );

      expect(undone.receipt.actionId, 'history.undo');
      expect((await FileMapRepository().loadMap(fixture.mapPath)).toJson(),
          fixture.map.toJson());
    });

    test('receipt presenter keeps domain codes and confirmations actionable',
        () {
      const presenter = EditorReceiptPresenter();
      final conflict = presenter.failure(
        const EditorAuthoringMutationFailure(
          code: 'transaction.revision_conflict',
          message: 'The project changed.',
          remediation: ['Reload the project.'],
        ),
      );
      final confirmation = presenter.failure(
        const EditorAuthoringMutationFailure(
          code: 'confirmation.required',
          message: 'Confirmation required.',
        ),
      );

      expect(conflict.code, 'transaction.revision_conflict');
      expect(conflict.isConflict, isTrue);
      expect(conflict.message.toLowerCase(), contains('recharg'));
      expect(confirmation.requiresConfirmation, isTrue);
    });
  });
}

Map<String, Object?> _stableReceipt(AuthoringReceipt receipt) => {
      'actionId': receipt.actionId,
      'actionVersion': receipt.actionVersion,
      'status': receipt.status.wireName,
      'diff': receipt.diff.toJson(),
      'affectedResources': [
        for (final resource in receipt.affectedResources)
          {'kind': resource.kind, 'id': resource.id},
      ],
    };

final class _MutationFixture {
  _MutationFixture({
    required this.root,
    required this.project,
    required this.map,
    required this.queries,
    required this.mutations,
  });

  static Future<_MutationFixture> create() async {
    final root = await Directory.systemTemp.createTemp('pmcp081_editor_');
    const project = ProjectManifest(
      name: 'PMCP-081 editor fixture',
      maps: [
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
      ],
      tilesets: [],
    );
    const map = MapData(
      id: 'alpha',
      name: 'Alpha',
      size: GridSize(width: 2, height: 2),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tiles: [0, 0, 0, 0],
        ),
        MapLayer.terrain(
          id: 'l_terrain',
          name: 'Terrain',
          terrains: [
            TerrainType.none,
            TerrainType.none,
            TerrainType.none,
            TerrainType.none,
          ],
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: [false, false, false, false],
        ),
      ],
    );
    await FileProjectRepository()
        .saveProject(project, p.join(root.path, 'project.json'));
    await FileMapRepository().saveMap(
      map,
      p.join(root.path, 'maps', 'alpha.json'),
      projectDialogueContext: project,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    return _MutationFixture(
      root: root,
      project: project,
      map: map,
      queries: queries,
      mutations: mutations,
    );
  }

  final Directory root;
  final ProjectManifest project;
  final MapData map;
  final AuthoringQueryAdapter queries;
  final AuthoringMutationAdapter mutations;

  String get mapPath => p.join(root.path, 'maps', 'alpha.json');

  Future<void> dispose() async {
    await mutations.closeAll();
    await queries.closeAll();
    if (await root.exists()) await root.delete(recursive: true);
  }
}
```

## `packages/map_editor/test/authoring_api/editor_write_boundary_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('every direct filesystem writer is classified and new bypasses fail',
      () async {
    final sourceRoot = Directory(p.join(Directory.current.path, 'lib', 'src'));
    final actual = <String>{};
    await for (final entity in sourceRoot.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      if (_directWrite.hasMatch(source)) {
        actual.add(p.relative(entity.path, from: Directory.current.path));
      }
    }

    final classified = <String>{
      ..._platformAndAssetSinks,
      ..._transactionAndRecoverySinks,
      ..._legacyStructuredAuthoringDebt,
    };
    expect(
      actual.difference(classified),
      isEmpty,
      reason: 'A new direct writer must use AuthoringMutationAdapter or be '
          'classified here with an explicit architecture reason.',
    );
    expect(
      classified.difference(actual),
      isEmpty,
      reason: 'Remove stale exceptions so the guardrail cannot hide debt.',
    );
  });

  test('Authoring editor adapters stay Flutter-free and perform no raw writes',
      () async {
    final adapterRoot = Directory(
      p.join(
          Directory.current.path, 'lib', 'src', 'application', 'authoring_api'),
    );
    await for (final entity in adapterRoot.list()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      expect(source, isNot(contains("package:flutter/")), reason: entity.path);
      expect(source, isNot(contains("import 'dart:io'")), reason: entity.path);
      expect(_directWrite.hasMatch(source), isFalse, reason: entity.path);
    }
  });

  test('the product SaveMap provider injects canonical Authoring mutations',
      () async {
    final provider = await File(
      p.join(Directory.current.path, 'lib', 'src', 'app', 'providers', 'editor',
          'map_use_case_providers.dart'),
    ).readAsString();
    expect(provider, contains('authoringMutationAdapterProvider'));
    expect(provider, contains('authoringMutations:'));
  });
}

final RegExp _directWrite = RegExp(
  r'\.(?:writeAsBytes|writeAsString|rename|delete)\s*\(',
);

/// Packaging, settings, imported media and Border artifacts are not PokeMap
/// structured authoring documents. Their dedicated ports remain legitimate.
const _platformAndAssetSinks = <String>{
  'lib/src/application/tools/export_pokemon_sdk_studio_catalog_cli.dart',
  'lib/src/features/border_studio/infrastructure/filesystem/file_border_asset_snapshot_store.dart',
  'lib/src/features/border_studio/infrastructure/filesystem/file_border_publication_manifest_port.dart',
  'lib/src/features/game_export/application/game_package_export_service.dart',
  'lib/src/features/game_export/infrastructure/game_package_export_profile_store.dart',
  'lib/src/features/game_export/infrastructure/hub_install_request_publisher.dart',
  'lib/src/features/personalization/application/project_branding_image_import_service.dart',
  'lib/src/features/personalization/application/project_font_import_service.dart',
  'lib/src/features/personalization/application/project_intro_video_import_service.dart',
  'lib/src/features/personalization/application/project_presentation_asset_lifecycle.dart',
  'lib/src/features/personalization/application/project_title_music_import_service.dart',
  'lib/src/infrastructure/filesystem/project_filesystem.dart',
};

/// Atomic stores, journals and recovery gateways are infrastructure owned by
/// existing crash-safe protocols. They are not additional product commands.
const _transactionAndRecoverySinks = <String>{
  'lib/src/infrastructure/repositories/atomic_map_document_persistence.dart',
  'lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart',
  'lib/src/infrastructure/repositories/file_narrative_document_recovery_store.dart',
  'lib/src/infrastructure/repositories/file_repositories.dart',
  'lib/src/infrastructure/repositories/journaled_file_promotion_repository.dart',
  'lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart',
  'lib/src/infrastructure/repositories/narrative_activity_journal_repository.dart',
  'lib/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart',
  'lib/src/infrastructure/repositories/narrative_event_registry_persistence.dart',
  'lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart',
  'lib/src/infrastructure/repositories/narrative_template_transaction_file_gateway.dart',
};

/// Explicit PMCP-081 residual debt. Keeping this set exact prevents claiming
/// full migration while these specialized paths still perform direct I/O.
const _legacyStructuredAuthoringDebt = <String>{
  'lib/src/application/services/map_lifecycle_transaction_service.dart',
  'lib/src/application/use_cases/map_use_cases.dart',
  'lib/src/features/editor/state/editor_notifier.dart',
  'lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart',
  'lib/src/ui/canvas/storylines_workspace.dart',
};
```
