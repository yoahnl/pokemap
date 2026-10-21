import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/scene_port.dart';
import '../../resources/domain/resource_port.dart';

class LocalSceneAdapter implements ScenePort {
  const LocalSceneAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  Future<ResourceMutationReceipt> publishSceneBatch({
    required List<({SceneAsset? base, SceneAsset current})> scenes,
  }) async {
    if (scenes.isEmpty || scenes.length > 128) {
      throw const SceneFailure('Enregistrez entre 1 et 128 scènes à la fois.');
    }
    try {
      return await LocalNarrativeCatalogTransaction(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
      ).run(
        actionId: 'scene.upsert_batch',
        parameters: (manifest) {
          for (final publication in scenes) {
            if (publication.base != null &&
                publication.base!.id != publication.current.id) {
              throw const SceneFailure('L’identité de la scène a changé.');
            }
            final existing = manifest.scenes
                .where((scene) => scene.id == publication.current.id)
                .firstOrNull;
            if (existing != publication.base) {
              throw const SceneFailure(
                'Une scène a changé sur le disque. Vos brouillons sont conservés.',
              );
            }
          }
          return {
            'scenes': [
              for (final publication in scenes) publication.current.toJson(),
            ],
          };
        },
      );
    } on SceneFailure {
      rethrow;
    } on Object catch (failure) {
      throw SceneFailure(
        'Les scènes n’ont pas été enregistrées. Vos brouillons sont conservés : $failure',
      );
    }
  }

  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    try {
      final receipt =
          await LocalNarrativeCatalogTransaction(
            session: session,
            mapAdapter: mapAdapter,
            faultInjector: faultInjector,
          ).run(
            actionId: 'scene.upsert',
            parameters: (manifest) {
              if (base != null && base.id != current.id) {
                throw const SceneFailure('L’identité de la scène a changé.');
              }
              final existing = manifest.scenes
                  .where((scene) => scene.id == current.id)
                  .firstOrNull;
              if (existing != base) {
                throw const SceneFailure(
                  'Cette scène a changé depuis son ouverture. Votre brouillon est conservé ; rouvrez sa version enregistrée avant de réappliquer vos changements.',
                );
              }
              return {'scene': current.toJson()};
            },
          );
      return ScenePublicationReceipt(
        catalog: receipt,
        scene: receipt.manifest.scenes.singleWhere((s) => s.id == current.id),
      );
    } on SceneFailure {
      rethrow;
    } on Object catch (failure) {
      throw SceneFailure(
        'La scène n’a pas été enregistrée. Le brouillon reste ouvert. Vérifiez ses connexions et références : $failure',
      );
    }
  }
}
