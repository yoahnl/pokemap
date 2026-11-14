import 'dart:math';

import 'package:map_authoring/map_authoring.dart' show MapAuthoringException;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../../project_session/data/studio_project_document_revision.dart';
import '../domain/map_catalog_port.dart';
import '../domain/map_workspace_port.dart';
import 'local_map_workspace_adapter.dart';
import 'local_map_catalog_preparation.dart';
import 'local_map_catalog_receipt.dart';

part 'local_map_catalog_mutation.dart';
part 'local_map_catalog_spatial_creation.dart';

final class LocalMapCatalogAdapter
    implements MapCatalogPort, MapCatalogPreparationPort {
  LocalMapCatalogAdapter(
    this.mapAdapter, {
    this.profileSink,
    this.beforeTransactionPrecondition,
    this.fileReader = const LocalProjectFileReader(),
  });

  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader fileReader;
  final ProjectSnapshotLoadProfileSink? profileSink;
  final Future<void> Function()? beforeTransactionPrecondition;
  final snapshotCache = ProjectSnapshotCache();
  final fingerprintCache = ProjectSnapshotFingerprintCache();

  @override
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  }) => _mutate(
    session,
    actionId,
    parameters,
    expectedMapRevisions: expectedMapRevisions,
    confirmDestructive: confirmDestructive,
    expectedManifest: expectedManifest,
  );

  @override
  Future<void> reconcile(ProjectSession session, MapCatalogReceipt receipt) =>
      mapAdapter.withResourceMutation(
        () => mapAdapter.acceptCatalogMutation(session, receipt),
      );

  @override
  Future<MapCatalogPreparation> prepare(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    ProjectManifest? expectedManifest,
  }) => prepareLocalMapCatalog(
    this,
    session,
    actionId,
    parameters,
    expectedMapRevisions: expectedMapRevisions,
    expectedManifest: expectedManifest,
  );

  @override
  Future<MapCatalogReceipt> applyPrepared(
    ProjectSession session,
    MapCatalogPreparation preparation, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
    String? Function()? validateBeforeApply,
  }) {
    final requestedTarget =
        preparation.parameters[preparation.actionId == 'map.duplicate'
            ? 'sourceMapId'
            : 'mapId'];
    if (preparation.sessionId != session.sessionId ||
        preparation.sourceMap.id != preparation.targetMapId ||
        requestedTarget != preparation.targetMapId ||
        (!preparation.canApply && !preparation.noChange)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Cette analyse appartient à une autre session ou refuse la publication.',
      );
    }
    return _mutate(
      session,
      preparation.actionId,
      preparation.parameters,
      expectedMapRevisions: expectedMapRevisions,
      confirmDestructive: confirmDestructive,
      expectedManifest: expectedManifest,
      expectedSnapshotRevision: preparation.snapshotRevision,
      validateBeforeApply: validateBeforeApply,
      expectNoChange: preparation.noChange,
    );
  }
}
