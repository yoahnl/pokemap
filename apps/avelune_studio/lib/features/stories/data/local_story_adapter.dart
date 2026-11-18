import 'package:map_authoring/map_authoring.dart'
    show
        AuthoringTransactionFaultInjector,
        LocalProjectFileReader,
        ProjectFileReader;
import 'package:map_authoring/map_authoring_local.dart'
    show CatalogNarrativeOwnerDocuments;
import 'package:map_core/map_core_domain.dart';

import '../../game_memory/data/local_narrative_read.dart';
import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/story_port.dart';

class LocalStoryAdapter implements StoryPort {
  const LocalStoryAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
    this.reader = const LocalProjectFileReader(),
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;
  final ProjectFileReader reader;

  LocalNarrativeCatalogTransaction get _transaction =>
      LocalNarrativeCatalogTransaction(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
        reader: reader,
      );

  @override
  Future<ResourceMutationReceipt> publishStory({
    required String id,
    required StorylineAsset? base,
    required StorylineAsset? current,
    Set<String> requiredStoryIds = const {},
    Set<String> requiredFactIds = const {},
    Set<String> requiredSceneIds = const {},
  }) => _transaction.run(
    actionId: current == null ? 'storyline.delete' : 'storyline.upsert',
    parameters: (_) {
      if ((base != null && base.id != id) ||
          (current != null && current.id != id)) {
        throw const StoryFailure('L’identité de l’histoire a changé.');
      }
      return current == null
          ? {'storylineId': id}
          : {'storyline': current.toJson()};
    },
    validateSnapshot: (snapshot) async {
      final project = snapshot.manifest;
      final existing = project.storylines.where((s) => s.id == id).firstOrNull;
      if (existing != base) {
        throw const StoryFailure(
          'Cette histoire a changé sur le disque. Votre brouillon est conservé ; rechargez sa version enregistrée avant de réappliquer vos changements.',
        );
      }
      if (requiredStoryIds.isEmpty &&
          requiredFactIds.isEmpty &&
          requiredSceneIds.isEmpty) {
        return;
      }
      final dependenciesExist =
          session.storage == ProjectSessionStorage.workingCatalog
          ? await readNarrativeCatalog(
              session,
              reader,
              (catalog) => CatalogNarrativeOwnerDocuments.containsDependencies(
                catalog,
                storylineIds: requiredStoryIds,
                factIds: requiredFactIds,
                sceneIds: requiredSceneIds,
              ),
            )
          : requiredStoryIds.every((id) => project.storylines.any((s) => s.id == id)) &&
                requiredFactIds.every((id) => project.facts.any((f) => f.id == id)) &&
                requiredSceneIds.every((id) => project.scenes.any((s) => s.id == id));
      if (!dependenciesExist) {
        throw const StoryFailure(
          'Une histoire, un état ou une scène liés a disparu. Le brouillon est conservé.',
        );
      }
    },
  );

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) => _transaction.run(
    actionId: base == null ? 'fact.create' : 'fact.update',
    parameters: (project) {
      final existing = project.facts
          .where((fact) => fact.id == current.id)
          .firstOrNull;
      if (existing != base) {
        throw const StoryFailure(
          'Cet état a changé sur le disque. Votre brouillon est conservé.',
        );
      }
      return {'fact': current.toJson()};
    },
  );
}
