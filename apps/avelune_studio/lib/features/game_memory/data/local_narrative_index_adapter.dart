import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../project_session/data/local_workshop_reader.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/narrative_index_port.dart';

const _usageBatch = 50;
const _factBatch = 50;

final class LocalNarrativeIndexAdapter implements NarrativeIndexPort {
  LocalNarrativeIndexAdapter(
    this.session, {
    this.reader = const LocalProjectFileReader(),
  });

  final ProjectSession session;
  final ProjectFileReader reader;

  @override
  Future<List<NarrativeTitle>> titles(NarrativeTitleKind kind) =>
      _read((reads, handle) async {
        final titles = <NarrativeTitle>[];
        String? cursor;
        do {
          final page = await reads.queryProject(
            handle,
            AuthoringQueryRequest(
              resourceKind: narrativeTitleResourceKind,
              operation: AuthoringQueryOperation.list,
              filters: {'kind': kind.wireName},
              pageSize: CatalogNarrativeTitles.pageSize,
              cursor: cursor,
            ),
          );
          for (final item in page.items) {
            titles.add(
              NarrativeTitle(
                id: item['id'] as String,
                title: item['title'] as String,
                category: item['category'] as String?,
              ),
            );
          }
          cursor = page.nextCursor;
        } while (cursor != null);
        return titles;
      });

  @override
  Future<List<NarrativeFactDefinition>> facts(List<String> ids) =>
      _read((reads, handle) async {
        final facts = <NarrativeFactDefinition>[];
        for (var start = 0; start < ids.length; start += _factBatch) {
          final batch = ids.skip(start).take(_factBatch).toList();
          final page = await reads.queryProject(
            handle,
            AuthoringQueryRequest(
              resourceKind: 'fact',
              operation: AuthoringQueryOperation.batchGet,
              view: AuthoringQueryView.detail,
              ids: batch,
              pageSize: batch.length,
            ),
          );
          for (final item in page.items) {
            facts.add(
              NarrativeFactDefinition.fromJson(
                Map<String, dynamic>.from(item)..remove('resourceKind'),
              ),
            );
          }
        }
        return facts;
      });

  @override
  Future<Map<String, NarrativeUsages>> factUsers(List<String> factIds) =>
      _read((reads, handle) async {
        final usages = <String, NarrativeUsages>{};
        for (var start = 0; start < factIds.length; start += _usageBatch) {
          final batch = factIds.skip(start).take(_usageBatch).toList();
          final page = await reads.queryProject(
            handle,
            AuthoringQueryRequest(
              resourceKind: narrativeFactUsersResourceKind,
              operation: AuthoringQueryOperation.batchGet,
              ids: batch,
              pageSize: batch.length,
            ),
          );
          for (final item in page.items) {
            usages[item['factId'] as String] = _usages(item, 'users');
          }
        }
        return usages;
      });

  @override
  Future<NarrativeUsages> elementOwners(String mapId, String elementId) =>
      _read((reads, handle) async {
        final page = await reads.queryProject(
          handle,
          AuthoringQueryRequest(
            resourceKind: narrativeMapElementOwnersResourceKind,
            operation: AuthoringQueryOperation.get,
            ids: [elementId],
            filters: {'mapId': mapId},
            pageSize: 1,
          ),
        );
        return _usages(page.items.single, 'owners');
      });

  @override
  Future<List<WorldRuleDefinition>> worldRules() =>
      LocalWorkshopReader(session, reader: reader).read(
        metadataFields: const {'worldRules'},
        operation: (project, _, _) async => project.worldRules,
      );

  NarrativeUsages _usages(Map<String, Object?> item, String field) {
    final coverage = item['coverage'] as Map?;
    return NarrativeUsages(
      owners: [
        for (final raw in item[field] as List? ?? const [])
          if (raw is Map)
            if (NarrativeOwnerKind.fromWireName('${raw['kind']}')
                case final kind?)
              NarrativeOwner(
                kind: kind,
                id: raw['id'] as String,
                role: switch (raw['role']) {
                  'write' => NarrativeFactRole.write,
                  'read' => NarrativeFactRole.read,
                  _ => null,
                },
              ),
      ],
      notCovered: [
        for (final source in coverage?['notCovered'] as List? ?? const [])
          if (source is String) source,
      ],
    );
  }

  Future<T> _read<T>(
    Future<T> Function(AuthoringReadApi reads, ProjectHandle handle) body,
  ) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: const {},
      workshopScope: true,
    );
    final opened = await opener.openProject(session.directoryPath);
    try {
      return await body(
        AuthoringReadApi(
          openService: opener,
          snapshotLoader: ProjectSnapshotLoader(handles: handles),
        ),
        opened.projectHandle,
      );
    } on AuthoringQueryException catch (failure) {
      throw switch (failure.code) {
        'query.narrative_titles_preparation_required' =>
          const NarrativeIndexPreparationRequired('narrativeTitles'),
        'query.narrative_usages_preparation_required' =>
          const NarrativeIndexPreparationRequired('narrativeUsages'),
        'query.narrative_titles_catalog_required' ||
        'query.narrative_usages_catalog_required' =>
          const NarrativeIndexUnavailable(),
        _ => failure,
      };
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }
}
