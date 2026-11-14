import 'package:map_core/map_core.dart';

import '../catalog_storage/catalog_storage_store.dart';
import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import '../workspace/catalog/catalog_narrative_event_documents.dart';
import '../workspace/catalog/catalog_narrative_titles.dart';
import '../workspace/catalog/catalog_narrative_usages.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/project_query_service.dart';
import 'storyline_outline_json.dart';

const storylineOutlineResourceKind = 'storylineOutline';
const storylineProposalResourceKind = 'storylineProposal';
const storylineReadResourceKinds = {
  storylineOutlineResourceKind,
  storylineProposalResourceKind,
};

Future<AuthoringQueryPage> queryStorylineReads({
  required CatalogProjectReader? catalog,
  required AuthoringQueryRequest request,
}) async {
  if (request.operation != AuthoringQueryOperation.summary ||
      request.view != AuthoringQueryView.summary ||
      request.ids.isNotEmpty ||
      request.filters.isNotEmpty ||
      request.searchTerm != null ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.extensions.isNotEmpty ||
      request.cursor != null) {
    throw AuthoringQueryException('query.storyline_read_scope_invalid',
        'Request ${request.resourceKind} with operation summary, view summary and no ids, filters or cursor.');
  }
  if (catalog == null) {
    throw const AuthoringQueryException('query.storyline_read_catalog_required',
        'Storyline outlines and proposals are read from a working catalog project.');
  }
  return catalog.read((projection) async {
    final snapshot = projection.snapshot;
    final item = request.resourceKind == storylineOutlineResourceKind
        ? await _outline(
            snapshot, projection.projectMetadata, catalog.store.projectRoot)
        : await _proposal(snapshot, projection.projectMetadata);
    return AuthoringQueryPage(
        snapshotRevision: 'sha256:${snapshot.root.sha256}',
        items: [item],
        totalAvailable: 1);
  });
}

Future<Map<String, Object?>> _outline(
    CatalogSnapshot snapshot, ProjectManifest base, String projectRoot) async {
  final storylines = [
    for (final json in await _all(snapshot, 'storylines'))
      StorylineAsset.fromJson(json)
  ];
  final steps = [
    for (final storyline in storylines)
      for (final chapter in storyline.chapters) ...chapter.steps
  ];
  final completionFacts = {
    for (final step in steps)
      if (storylineMilestoneCompletionFactId(step) case final factId?) factId
  };
  final attached = {for (final step in steps) ...step.sceneLinkIds};
  final scenes = await _sceneTitles(snapshot);
  final writers = <String>{};
  for (final factId in completionFacts) {
    final users =
        switch (await CatalogNarrativeUsages.readFactUsers(snapshot, factId)) {
      CatalogNarrativeUsageEntries(:final entries) => entries,
      CatalogNarrativeUsagesPreparationRequired(:final reason) => _preparation(
          'query.narrative_usages_preparation_required',
          CatalogNarrativeUsages.preparationScope,
          reason),
    };
    for (final user in users) {
      if (user['kind'] == 'scene' && user['role'] == 'write') {
        writers.add(user['id'] as String);
      }
    }
  }
  final NarrativeEventRegistry? events;
  try {
    events = attached.isEmpty
        ? null
        : await CatalogNarrativeEventDocuments.read(
            snapshot,
            await CatalogNarrativeEventDocuments.readSceneOwnerIds(
                snapshot, projectRoot, attached));
  } on CatalogStorageException catch (error) {
    if (error.code != 'catalog.preparation_required') rethrow;
    _preparation(
        'query.narrative_events_preparation_required', 'default', 'absent');
  }
  final documents = await CatalogMetadataDocuments.readDocuments(
      snapshot: snapshot,
      project: base.copyWith(storylines: storylines),
      ids: {'facts': completionFacts, 'scenes': writers});
  final outline = projectStorylineOutline(
      documents.project.copyWith(eventRegistry: events),
      scenes: scenes);
  return {
    ...storylineOutlineJson(outline),
    'reads': {
      'storylines': storylines.length,
      'completionFacts': documents.project.facts.length,
      'writerScenes': documents.project.scenes.length,
      'events': events?.records.length ?? 0,
      'sceneTitles': scenes.length,
      'maps': 0,
    },
  };
}

Future<Map<String, Object?>> _proposal(
    CatalogSnapshot snapshot, ProjectManifest base) async {
  final storylines = await _all(snapshot, 'storylines');
  if (storylines.isNotEmpty) {
    return {'storyline': null, 'reason': 'storylinesExist'};
  }
  final registry = CatalogNarrativeEventDocuments.decodeRegistry(
      await CatalogNarrativeEventDocuments.registryUnits(snapshot.lookup));
  final project = base.copyWith(
    facts: [
      for (final json in await _all(snapshot, 'facts'))
        NarrativeFactDefinition.fromJson(json)
    ],
    scenes: [
      for (final json in await _all(snapshot, 'scenes'))
        SceneAsset.fromJson(json)
    ],
    eventRegistry: registry == null
        ? null
        : NarrativeEventRegistry.fromJson(Map<String, dynamic>.from(registry)),
  );
  return storylineProposalJson(proposeStoryline(project));
}

Future<List<Map<String, dynamic>>> _all(
    CatalogSnapshot snapshot, String field) async {
  final result = <Map<String, dynamic>>[];
  for (var offset = 0;;) {
    final page = await CatalogMetadataDocuments.readPage(
        snapshot: snapshot, field: field, offset: offset, limit: 200);
    result.addAll(page.records);
    offset += page.records.length;
    if (offset >= page.total || page.records.isEmpty) return result;
  }
}

Future<List<StorylineOutlineScene>> _sceneTitles(
    CatalogSnapshot snapshot) async {
  final result = <StorylineOutlineScene>[];
  for (var page = 0;; page++) {
    switch (await CatalogNarrativeTitles.read(snapshot, 'scenes', page)) {
      case CatalogNarrativeTitlesPreparationRequired(:final reason):
        _preparation('query.narrative_titles_preparation_required',
            CatalogNarrativeTitles.preparationScope, reason);
      case CatalogNarrativeTitlePage(:final entries, :final total):
        result.addAll(
            [for (final entry in entries) (id: entry.id, title: entry.title)]);
        if (result.length >= total) return result;
    }
  }
}

Never _preparation(String code, String scope, String reason) =>
    throw AuthoringQueryException(code,
        'The index read by the storyline outline is ${reason == 'stale' ? 'stale' : 'not prepared'}. Prepare the workshop catalog with scope $scope, then retry.');
