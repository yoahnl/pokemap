import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core_domain.dart';
import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/event_port.dart';
import '../domain/event_record_view.dart';

class LocalEventAdapter implements EventPort, EventRegistryModePort {
  const LocalEventAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  @override
  Future<ResourceMutationReceipt> changeMode({
    required NarrativeEventRegistry? base,
    required EventSystemMode mode,
  }) =>
      LocalNarrativeCatalogTransaction(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
      ).run(
        actionId: 'event_v2.registry_mode.set',
        parameters: (project) {
          if (project.eventRegistry != base) {
            throw const EventFailure(
              'Le registre a changé sur le disque. Rechargez-le avant de changer son mode.',
            );
          }
          return {'mode': mode.name};
        },
      );

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) =>
      LocalNarrativeCatalogTransaction(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
      ).run(
        actionId: current == null
            ? 'event_v2.delete'
            : 'event_v2.record_upsert',
        validate: (project, maps) {
          final source = current?.source;
          if (source != null && source != base?.source) {
            final catalog = buildNarrativeEventProjectCatalog(
              project: project,
              maps: maps,
            );
            if (catalog.resolveSource(source).status !=
                NarrativeEventProjectResolutionStatus.found) {
              throw const EventFailure(
                'La source choisie n’est pas disponible dans le projet enregistré. Enregistrez d’abord sa carte ou son producteur.',
              );
            }
          }
          final sceneId = current?.sceneId;
          if (sceneId != null &&
              sceneId != base?.sceneId &&
              !project.scenes.any((s) => s.id == sceneId)) {
            throw const EventFailure(
              'Enregistrez d’abord la scène liée dans son éditeur.',
            );
          }
        },
        parameters: (project) {
          if ((base != null && base.id != id) ||
              (current != null && current.id != id)) {
            throw const EventFailure('L’identité de l’événement a changé.');
          }
          final existing = project.eventRegistry?.records
              .where((r) => r.id == id)
              .firstOrNull;
          if (existing != base) {
            throw const EventFailure(
              'Cet événement a changé sur le disque. Le brouillon est conservé ; rechargez la version enregistrée pour résoudre le conflit.',
            );
          }
          return current == null
              ? {'eventId': id}
              : {'record': current.toJson()};
        },
      );
}
