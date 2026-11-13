import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/scene_port.dart';
import '../../resources/domain/resource_port.dart';
import '../application/steps/scene_step_patch.dart';

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
    if (base != null) {
      final previous = {for (final node in base.graph.nodes) node.id: node};
      final changed = current.graph.nodes
          .where((node) => previous[node.id] != node)
          .toList();
      if (changed.length == 1 &&
          changed.single.payload is SceneConditionPayload &&
          (changed.single.payload as SceneConditionPayload).conditionSource !=
              null) {
        final source =
            (changed.single.payload as SceneConditionPayload).conditionSource!;
        final nodeId = changed.single.id;
        if (updateSceneConditionSource(
              base,
              nodeId: nodeId,
              source: source,
            ).updatedScene ==
            current) {
          final receipt =
              await LocalNarrativeCatalogTransaction(
                session: session,
                mapAdapter: mapAdapter,
                faultInjector: faultInjector,
              ).run(
                actionId: 'scene.condition.set',
                parameters: (manifest) {
                  if (manifest.scenes
                          .where((scene) => scene.id == base.id)
                          .firstOrNull !=
                      base) {
                    throw const SceneFailure(
                      'Cette scène a changé sur le disque. Votre brouillon est conservé.',
                    );
                  }
                  return {
                    'sceneId': base.id,
                    'nodeId': nodeId,
                    'conditionSource': source.toJson(),
                  };
                },
              );
          return ScenePublicationReceipt(
            catalog: receipt,
            scene: receipt.manifest.scenes.singleWhere(
              (scene) => scene.id == base.id,
            ),
          );
        }
      }
      if (sceneGraphPatchForScenes(base: base, current: current)
          case SceneGraphPatchReady(:final patch) when !patch.isEmpty) {
        return _publishPatch(base, patch);
      }
    }
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

  Future<ScenePublicationReceipt> _publishPatch(
    SceneAsset base,
    SceneGraphPatch patch,
  ) async {
    try {
      final receipt =
          await LocalNarrativeCatalogTransaction(
            session: session,
            mapAdapter: mapAdapter,
            faultInjector: faultInjector,
          ).run(
            actionId: sceneGraphPatchActionId,
            parameters: (manifest) {
              if (manifest.scenes
                      .where((scene) => scene.id == base.id)
                      .firstOrNull !=
                  base) {
                throw const SceneFailure(
                  'Cette scène a changé depuis son ouverture. Votre brouillon est conservé ; rouvrez sa version enregistrée avant de réappliquer vos changements.',
                );
              }
              return patch.toParameters();
            },
          );
      return ScenePublicationReceipt(
        catalog: receipt,
        scene: receipt.manifest.scenes.singleWhere(
          (scene) => scene.id == base.id,
        ),
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
