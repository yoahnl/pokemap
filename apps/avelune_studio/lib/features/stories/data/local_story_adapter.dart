import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core_domain.dart';
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
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  LocalNarrativeCatalogTransaction get _transaction =>
      LocalNarrativeCatalogTransaction(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
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
    parameters: (project) {
      if ((base != null && base.id != id) ||
          (current != null && current.id != id)) {
        throw const StoryFailure('L’identité de l’histoire a changé.');
      }
      final existing = project.storylines.where((s) => s.id == id).firstOrNull;
      if (existing != base) {
        throw const StoryFailure(
          'Cette histoire a changé sur le disque. Votre brouillon est conservé ; rechargez sa version enregistrée avant de réappliquer vos changements.',
        );
      }
      if (requiredStoryIds.any(
            (id) => !project.storylines.any((s) => s.id == id),
          ) ||
          requiredFactIds.any((id) => !project.facts.any((f) => f.id == id)) ||
          requiredSceneIds.any(
            (id) => !project.scenes.any((s) => s.id == id),
          )) {
        throw const StoryFailure(
          'Une histoire, un état ou une scène liés a disparu. Le brouillon est conservé.',
        );
      }
      return current == null
          ? {'storylineId': id}
          : {'storyline': current.toJson()};
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
