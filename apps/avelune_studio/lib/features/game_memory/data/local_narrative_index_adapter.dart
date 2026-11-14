import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../project_session/data/local_workshop_reader.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/narrative_index_port.dart';
import '../../scenes/domain/scene_document.dart';
import '../domain/map_directory.dart';
import 'local_map_directory_codec.dart';
import 'local_scene_document_codec.dart' as codec;
import 'local_narrative_read.dart';

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
                value: switch (item['valueKind']) {
                  final String kind => NarrativeValue.fromJson(
                    item['initialValue'],
                    declaredKind: NarrativeValueKind.fromWireName(kind),
                  ),
                  _ => null,
                },
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

  @override
  Future<Map<String, MapDirectoryPage>> mapDirectory(List<String> mapIds) =>
      _read((reads, handle) async {
        final pages = <String, MapDirectoryPage>{};
        for (var start = 0; start < mapIds.length; start += _usageBatch) {
          final batch = mapIds.skip(start).take(_usageBatch).toList();
          final page = await reads.queryProject(
            handle,
            AuthoringQueryRequest(
              resourceKind: mapDirectoryResourceKind,
              operation: AuthoringQueryOperation.batchGet,
              ids: batch,
              pageSize: batch.length,
            ),
          );
          for (final item in page.items) {
            final directory = mapDirectoryPage(item);
            pages[directory.mapId] = directory;
          }
        }
        return pages;
      });

  @override
  Future<Map<String, String>> characterNames(List<String> characterIds) =>
      _read((reads, handle) async {
        final names = <String, String>{};
        for (var start = 0; start < characterIds.length; start += _usageBatch) {
          final batch = characterIds.skip(start).take(_usageBatch).toList();
          final page = await reads.queryProject(
            handle,
            AuthoringQueryRequest(
              resourceKind: 'character',
              operation: AuthoringQueryOperation.batchGet,
              ids: batch,
              pageSize: batch.length,
            ),
          );
          for (final item in page.items) {
            if (item case {'id': final String id, 'name': final String name}
                when name.trim().isNotEmpty) {
              names[id] = name;
            }
          }
        }
        return names;
      });

  @override
  Future<SceneDocument> sceneDocument(String sceneId) =>
      _read((reads, handle) async {
        final page = await reads.queryProject(
          handle,
          AuthoringQueryRequest(
            resourceKind: sceneDocumentResourceKind,
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: [sceneId],
            pageSize: 1,
          ),
        );
        return codec.sceneDocument(page.items.single);
      });

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
  ) => readNarrativeIndex(session, reader, body);
}
