import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart'
    show MapAuthoringException, AssetCatalog;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../dialogues/data/local_dialogue_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/resource_port.dart';
import '../domain/resource_mutation_preparation.dart';
import '../domain/resource_usage_port.dart';
import 'local_resource_usage_adapter.dart';
import 'border_resource_sources.dart';
import 'resource_no_change.dart';

part 'local_border_resource_adapter.dart';
part 'local_resource_character_operations.dart';
part 'local_resource_mutation.dart';
part 'local_resource_preparation.dart';
part 'local_resource_receipt.dart';
part 'local_resource_reconciliation.dart';

final class LocalResourceAdapter
    implements
        ResourcePort,
        ResourceMutationPreparationPort,
        ResourceUsageProvider {
  LocalResourceAdapter({
    required this.session,
    required this.mapAdapter,
    this.beforeTransactionPrecondition,
    this.beforeReconciliation,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  bool _disposed = false;
  final Future<void> Function()? beforeTransactionPrecondition;
  final Future<void> Function()? beforeReconciliation;
  final Set<ResourceMutationPreparation> _appliedPreparations = {};
  @override
  late final ResourceUsagePort usages = LocalResourceUsageAdapter(
    session: session,
  );

  static final _actions = {
    'asset.move',
    'asset.delete',
    'asset.replace',
    'element.delete',
    ...ResourceManagementActions.actionIds,
    'tileset.import_image',
    'element.upsert',
    'smart_tile.preset.draft.upsert',
    'smart_tile.preset.publish',
    'border.blueprint.draft.upsert',
    'border.blueprint.publish',
    'map.library.reorganize',
    'characterStudio.character.create',
    'characterStudio.character.update',
    'characterStudio.animationClip.upsert',
    'characterStudio.animationClip.delete',
    'characterStudio.portraitState.create',
    'characterStudio.character.portrait.clear',
    'characterStudio.asset.import',
  };

  @override
  Future<ResourceMutationReceipt> createBorder(BorderCreationRequest request) =>
      _createBorder(this, request);

  @override
  Future<ResourceMutationReceipt> importCharacterPortrait(
    CharacterPortraitImport request,
  ) => _importCharacterPortrait(this, request);

  @override
  Future<ResourceMutationReceipt> importCharacterAnimation(
    CharacterAnimationImport request,
  ) => _importCharacterAnimation(this, request);

  @override
  Future<Uint8List?> readCharacterPortrait(
    String characterId,
    String stateId,
  ) => _readCharacterPortrait(this, characterId, stateId);

  @override
  Future<ResourceMutationReceipt> importImage(ResourceImageImport request) =>
      _importResourceImage(this, request);

  @override
  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  ) => _run(actionId, (_) => parameters);

  Future<ResourceMutationReceipt> replaceAsset(
    String assetId,
    String sourcePath,
  ) => _run(
    'asset.replace',
    (_) => {'assetId': assetId},
    sourcePath: sourcePath,
  );

  Future<ResourceMutationReceipt> removeUnusedElement(
    String id, {
    required bool confirm,
  }) => _run(
    'element.delete',
    (_) => {'elementId': id},
    confirmDestructive: confirm,
  );

  @override
  Future<ResourceMutationReceipt> saveElement(ProjectElementEntry element) =>
      _saveResourceElement(this, element);

  void _requireAvailable() {
    if (_disposed) throw const ResourceFailure('Le projet a été fermé.');
  }

  @override
  Future<String> captureResourceRevision() =>
      _readResourceSnapshot(this, (snapshot, _) => snapshot.revision);

  @override
  Future<String?> resourceFingerprint(String tilesetId, String revision) =>
      _readResourceFingerprint(this, tilesetId, revision);

  @override
  Future<void> reconcileReceipt(ResourceMutationReceipt receipt) =>
      _reconcileResourceReceipt(this, receipt);

  @override
  Future<ResourceMutationPreparation> prepareOperation(
    String actionId,
    Map<String, Object?> parameters, {
    String? expectedSnapshotRevision,
  }) => _prepareResourceOperation(
    this,
    actionId,
    parameters,
    expectedSnapshotRevision,
  );

  @override
  Future<ResourceMutationReceipt> applyPrepared(
    ResourceMutationPreparation preparation, {
    bool confirmDestructive = false,
    String? Function()? validateBeforeApply,
  }) async {
    _requireAvailable();
    if (preparation.sessionId != session.sessionId ||
        !_appliedPreparations.add(preparation)) {
      throw const ResourceFailure(
        'Cette préparation est déjà appliquée ou appartient à un autre projet.',
      );
    }
    try {
      return await _run(
        preparation.actionId,
        (_) => preparation.parameters,
        expectedBeforeRevision: preparation.manifestRevision,
        expectedSnapshotRevision: preparation.snapshotRevision,
        confirmDestructive: confirmDestructive,
        validateBeforeApply: validateBeforeApply,
      );
    } on ResourceFailure catch (failure) {
      if (failure.partialReceipt == null) {
        _appliedPreparations.remove(preparation);
      }
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await usages.dispose();
  }

  String _identity(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
}
