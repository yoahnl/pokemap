import 'dart:convert';

import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector, NarrativeAuthoringException;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/cinematic_port.dart';

class LocalCinematicAdapter implements CinematicPort {
  const LocalCinematicAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  @override
  Future<CinematicSourceSnapshot> load(String id) =>
      mapAdapter.withResourceMutation(() async {
        final baseline = await mapAdapter.resourceBaseline(
          session,
          refreshCatalog: true,
        );
        return _snapshot(baseline.manifest, id, baseline.revision) ??
            (throw const CinematicFailure(
              'Cette cinématique est absente du projet.',
            ));
      });

  @override
  Future<CinematicPublicationReceipt> publish({
    required String id,
    required CinematicSourceSnapshot? base,
    required CinematicAsset asset,
    String? folderId,
  }) async {
    if (asset.id != id || (base != null && base.asset.id != id)) {
      throw const CinematicFailure(
        'La publication ne correspond pas à la cinématique.',
      );
    }
    return _run(
      id: id,
      base: base,
      actionId: 'cinematic.upsert',
      parameters: (project) => {
        'cinematic': asset.toJson(),
        if (base == null)
          'libraryPlacement': {
            'folderId': folderId,
            'index': project.cinematicLibraryCatalog.entries
                .where(
                  (entry) =>
                      entry.family == CinematicLibraryFamily.world &&
                      entry.folderId == folderId,
                )
                .length,
          },
      },
    );
  }

  @override
  Future<CinematicPublicationReceipt> delete({
    required CinematicSourceSnapshot base,
  }) => _run(
    id: base.asset.id,
    base: base,
    actionId: base.entry == null
        ? 'cinematic.delete'
        : 'cinematicLibraryAsset.delete',
    parameters: (_) => {
      if (base.entry != null) 'family': 'world',
      'cinematicId': base.asset.id,
    },
  );

  @override
  Future<CinematicPublicationReceipt> setArchived({
    required CinematicSourceSnapshot base,
    required bool archived,
  }) async {
    if (base.entry == null) {
      throw const CinematicFailure(
        'Cette cinématique n’est pas classée dans la bibliothèque.',
      );
    }
    return _run(
      id: base.asset.id,
      base: base,
      actionId: 'cinematicLibraryEntry.setArchived',
      parameters: (_) => {
        'family': 'world',
        'cinematicId': base.asset.id,
        'isArchived': archived,
      },
    );
  }

  Future<CinematicPublicationReceipt> _run({
    required String id,
    required CinematicSourceSnapshot? base,
    required String actionId,
    required Map<String, Object?> Function(ProjectManifest) parameters,
  }) async {
    try {
      final receipt =
          await LocalNarrativeCatalogTransaction(
            session: session,
            mapAdapter: mapAdapter,
            faultInjector: faultInjector,
          ).run(
            actionId: actionId,
            refreshCatalog: true,
            parameters: parameters,
            validate: (project, _) => _validateBase(project, id, base),
          );
      return CinematicPublicationReceipt(
        resources: receipt,
        snapshot: _snapshot(receipt.manifest, id, receipt.revision),
      );
    } on CinematicFailure {
      rethrow;
    } on NarrativeAuthoringException catch (error) {
      throw CinematicFailure(
        'La cinématique n’a pas été enregistrée : ${error.message}',
        details: {'code': error.code, ...error.details},
      );
    } on Object catch (error) {
      throw CinematicFailure(
        'La cinématique n’a pas été enregistrée. Le brouillon reste ouvert : $error',
      );
    }
  }

  void _validateBase(
    ProjectManifest project,
    String id,
    CinematicSourceSnapshot? base,
  ) {
    final current = _snapshot(project, id, '');
    if (jsonEncode(current?.asset.toJson()) !=
            jsonEncode(base?.asset.toJson()) ||
        current?.entry != base?.entry) {
      throw const CinematicFailure(
        'La cinématique ou son classement a changé sur le disque. '
        'Votre brouillon est conservé ; rechargez explicitement la version actuelle.',
      );
    }
  }

  CinematicSourceSnapshot? _snapshot(
    ProjectManifest project,
    String id,
    String revision,
  ) {
    final asset = project.cinematics
        .where((value) => value.id == id)
        .firstOrNull;
    if (asset == null) return null;
    return CinematicSourceSnapshot(
      asset: CinematicAsset.fromJson(asset.toJson()),
      revision: revision,
      entry: project.cinematicLibraryCatalog.entryFor(
        CinematicLibraryFamily.world,
        id,
      ),
    );
  }
}
