import 'package:map_authoring/map_authoring.dart'
    show
        AuthoringPlanException,
        AuthoringTransactionFaultInjector,
        NarrativeAuthoringException,
        ProjectSnapshot,
        StandardEventTemplateSpec,
        decodeProjectMediaCatalogBytes,
        projectMediaCatalogResourceIdentity,
        projectMediaCatalogStorageKey,
        WorkspaceAccessException;
import 'package:map_authoring/map_authoring_local.dart'
    show
        ProjectFileReader,
        LocalProjectFileReader,
        AuthoringPerformanceObserver;
import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../map_workspace/domain/map_workspace_port.dart';
import '../../narrative/data/local_narrative_adapter.dart';
import '../../narrative/domain/narrative_port.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../../presentations/data/local_presentation_adapter.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/event_port.dart';
import '../domain/event_record_view.dart';
import '../domain/event_template_port.dart';

class LocalEventAdapter
    implements
        EventPort,
        EventBatchPort,
        EventRegistryModePort,
        EventTemplatePort,
        EventPresentationCatalogPort {
  const LocalEventAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
    this.reader = const LocalProjectFileReader(),
    this.performanceObserver,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;
  final ProjectFileReader reader;
  final AuthoringPerformanceObserver? performanceObserver;

  @override
  Future<ProjectMediaCatalog> loadPresentationMediaCatalog(
    ProjectManifest project,
  ) async {
    if (project.settings.dimension != ProjectDimension.twoD) {
      try {
        return decodeProjectMediaCatalogBytes(
          await reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: projectMediaCatalogStorageKey,
          ),
        );
      } on WorkspaceAccessException catch (failure) {
        if (failure.code == 'workspace.file_unavailable') {
          return ProjectMediaCatalog();
        }
        rethrow;
      }
    }
    return (await LocalPresentationAdapter(
      session: session,
      mapAdapter: mapAdapter,
    ).prepare(project)).mediaCatalog;
  }

  @override
  Future<NarrativePublicationReceipt> publishTemplate({
    required MapWorkspaceDocument base,
    required StandardEventTemplateSpec spec,
    required ProjectManifest project,
    required List<MapData> maps,
  }) =>
      LocalNarrativeAdapter(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
        reader: reader,
        performanceObserver: performanceObserver,
      ).publishStandardEvent(
        NarrativePublication(base: base, current: base.map),
        spec,
      );

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
  }) => _publish(
    current == null ? 'event_v2.delete' : 'event_v2.record_upsert',
    [(id: id, base: base, current: current)],
  );

  @override
  Future<ResourceMutationReceipt> publishEvents(
    List<EventRecordChange> changes,
  ) {
    if (changes.isEmpty ||
        changes.length > EventBatchPort.maxRecords ||
        changes.any((change) => change.current == null)) {
      throw ArgumentError.value(changes.length, 'changes');
    }
    return _publish('event_v2.record_upsert_batch', changes);
  }

  Future<ResourceMutationReceipt> _publish(
    String actionId,
    List<EventRecordChange> changes,
  ) async {
    try {
      return await _run(actionId, changes);
    } on NarrativeAuthoringException catch (failure) {
      if (actionId != 'event_v2.delete' ||
          failure.code != 'eventReferenced') {
        rethrow;
      }
      throw EventDeletionRefused.inUse([
        for (final consumer
            in failure.details['consumers'] as List? ?? const [])
          if (consumer case {
            'kind': final String kind,
            'label': final String label,
          })
            (kind: kind, label: label),
      ]);
    } on AuthoringPlanException catch (failure) {
      if (actionId != 'event_v2.delete' ||
          failure.code !=
              'catalog.narrative_event_consumers.preparation_required') {
        rethrow;
      }
      throw EventDeletionRefused.coverageUnknown();
    }
  }

  Future<ResourceMutationReceipt> _run(
    String actionId,
    List<EventRecordChange> changes,
  ) =>
      LocalNarrativeCatalogTransaction(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
      ).run(
        actionId: actionId,
        validateSnapshot: (snapshot) => _validate(snapshot, changes),
        parameters: (project) {
          final records = {
            for (final record
                in project.eventRegistry?.records ??
                    const <NarrativeEventRecord>[])
              record.id: record,
          };
          for (final change in changes) {
            if ((change.base != null && change.base!.id != change.id) ||
                (change.current != null && change.current!.id != change.id)) {
              throw const EventFailure('L’identité de l’événement a changé.');
            }
            if (records[change.id] != change.base) {
              throw const EventFailure(
                'Cet événement a changé sur le disque. Le brouillon est conservé ; rechargez la version enregistrée pour résoudre le conflit.',
              );
            }
          }
          return switch (actionId) {
            'event_v2.delete' => {'eventId': changes.single.id},
            'event_v2.record_upsert' => {
              'record': changes.single.current!.toJson(),
            },
            _ => {
              'records': [for (final change in changes) change.current!.toJson()],
            },
          };
        },
      );

  void _validate(ProjectSnapshot snapshot, List<EventRecordChange> changes) {
    final project = snapshot.manifest;
    NarrativeEventProjectCatalog? catalog;
    for (final change in changes) {
      final source = change.current?.source;
      if (source != null && source != change.base?.source) {
        final bytes = snapshot.findResourceBytes(
          projectMediaCatalogResourceIdentity,
        );
        catalog ??= buildNarrativeEventProjectCatalog(
          project: project,
          maps: snapshot.maps,
          presentationMediaCatalog: bytes == null
              ? null
              : decodeProjectMediaCatalogBytes(bytes),
        );
        if (catalog.resolveSource(source).status !=
            NarrativeEventProjectResolutionStatus.found) {
          throw const EventFailure(
            'La source choisie n’est pas disponible dans le projet enregistré. Enregistrez d’abord sa carte ou son producteur.',
          );
        }
      }
      final sceneId = change.current?.sceneId;
      if (sceneId != null &&
          sceneId != change.base?.sceneId &&
          !project.scenes.any((s) => s.id == sceneId)) {
        throw const EventFailure(
          'Enregistrez d’abord la scène liée dans son éditeur.',
        );
      }
    }
  }
}
