import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/world_port.dart';

class LocalWorldAdapter implements WorldPort {
  LocalWorldAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;
  final _maps = <String, MapData>{};
  String? _mapsRevision;

  LocalNarrativeCatalogTransaction get _transaction =>
      LocalNarrativeCatalogTransaction(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
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
        throw const WorldFailure(
          'Cet état a changé sur le disque. Votre brouillon est conservé.',
        );
      }
      return {'fact': current.toJson()};
    },
  );

  @override
  Future<ResourceMutationReceipt> deleteFact(NarrativeFactDefinition base) =>
      _transaction.run(
        actionId: 'fact.delete',
        parameters: (project) {
          final existing = project.facts
              .where((fact) => fact.id == base.id)
              .firstOrNull;
          if (existing != base) {
            throw const WorldFailure(
              'Cet état a changé sur le disque. Rien n’a été supprimé.',
            );
          }
          return {'factId': base.id};
        },
      );

  @override
  Future<ResourceMutationReceipt> publishRule({
    required WorldRuleDefinition? base,
    required WorldRuleDefinition current,
  }) => _transaction.run(
    actionId: base == null ? 'world_rule.create' : 'world_rule.update',
    parameters: (project) {
      final existing = project.worldRules
          .where((rule) => rule.id == current.id)
          .firstOrNull;
      if (existing != base) {
        throw const WorldFailure(
          'Cette règle a changé sur le disque. Votre brouillon est conservé.',
        );
      }
      if (current.source.kind == WorldRuleSourceKind.fact &&
          !project.facts.any((fact) => fact.id == current.source.sourceId)) {
        throw const WorldFailure(
          'L’état utilisé par cette règle n’est pas encore enregistré.',
        );
      }
      return {'rule': current.toJson()};
    },
  );

  @override
  Future<ResourceMutationReceipt> deleteRule(WorldRuleDefinition base) =>
      _transaction.run(
        actionId: 'world_rule.delete',
        parameters: (project) {
          final existing = project.worldRules
              .where((rule) => rule.id == base.id)
              .firstOrNull;
          if (existing != base) {
            throw const WorldFailure(
              'Cette règle a changé sur le disque. Rien n’a été supprimé.',
            );
          }
          return {'ruleId': base.id};
        },
      );

  @override
  Future<List<MapData>> loadMaps() async {
    final baseline = await mapAdapter.resourceBaseline(session);
    if (_mapsRevision != baseline.revision) {
      _maps.clear();
      _mapsRevision = baseline.revision;
    }
    for (final entry in baseline.manifest.maps) {
      if (_maps.containsKey(entry.id)) continue;
      _maps[entry.id] = (await mapAdapter.loadMap(session, entry)).map;
    }
    return _maps.values.toList(growable: false);
  }
}
