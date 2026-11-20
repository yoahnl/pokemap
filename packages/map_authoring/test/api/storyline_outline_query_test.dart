import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/catalog_unit_reads.dart';
import '../support/narrative_title_fixture.dart';
import '../support/storyline_trame_fixture.dart';

void main() {
  Future<AuthoringQueryPage> query(Directory root, String kind,
      {bool wire = false,
      Future<void> Function(Future<void> Function() read)? measure}) async {
    final handles = WorkspaceHandleStore();
    const files = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: files);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: files, handles: handles),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final opened = await api.openProject(root.path);
    final request = AuthoringQueryRequest(
        resourceKind: kind,
        operation: AuthoringQueryOperation.summary,
        view: AuthoringQueryView.summary);
    try {
      if (measure != null) {
        late AuthoringQueryPage page;
        await measure(() async =>
            page = await api.queryProject(opened.projectHandle, request));
        return page;
      }
      if (!wire) return await api.queryProject(opened.projectHandle, request);
      final result = AuthoringResult.fromJson(
          jsonDecode(await JsonlWorker(api: api).processLine(jsonEncode({
        'id': 'outline',
        'command': 'query',
        'args': {
          'projectHandle': opened.projectHandle.value,
          'request': request.toJson()
        },
      }))) as Map<String, dynamic>);
      if (result.status != AuthoringResultStatus.success) {
        throw AuthoringQueryException(
            result.error!.details['domainCode'] as String,
            result.error!.message);
      }
      return AuthoringQueryPage.fromJson(
          Map<String, dynamic>.from(result.data));
    } finally {
      await api.closeWorkspace(opened.workspaceHandle);
    }
  }

  Matcher code(String value) => isA<AuthoringQueryException>()
      .having((error) => error.code, 'code', value);

  for (final wire in [false, true]) {
    test('the outline assembles indexes and asks for missing ones JSONL=$wire',
        () async {
      final fixture = await NarrativeTitleFixture.create(
          project: storylineOutlineProject(0));
      addTearDown(fixture.close);
      await expectLater(
          query(fixture.root, storylineOutlineResourceKind, wire: wire),
          throwsA(code('query.narrative_titles_preparation_required')));
      await fixture.prepare();
      await expectLater(
          query(fixture.root, storylineOutlineResourceKind, wire: wire),
          throwsA(code('query.narrative_usages_preparation_required')));
      await fixture.prepare(CatalogNarrativeUsages.preparationScope);

      final item =
          (await query(fixture.root, storylineOutlineResourceKind, wire: wire))
              .items
              .single;
      final chapter =
          ((item['storylines'] as List).single as Map)['chapters'] as List;
      expect((chapter.single as Map)['milestones'], [
        {
          'id': 'wake_up',
          'title': 'Wake up',
          'sceneIds': ['scene_gate'],
          'mapIds': ['map_0'],
          'completionFactId': 'fact_fact_0',
          'issues': ['completionFactShared', 'completionFactCanReset'],
        },
        {
          'id': 'leave_home',
          'title': 'Leave home',
          'sceneIds': <String>[],
          'mapIds': <String>[],
          'completionFactId': 'fact_fact_0',
          'issues': [
            'noBehaviour',
            'completionFactShared',
            'completionFactCanReset'
          ],
        },
      ]);
      expect(
          (item['scenesOutsideStorylines'] as List).map((scene) => scene['id']),
          ['arrival', 'farewell', 'scene_town', 'scene_reset']);
      expect(item['reads'], {
        'storylines': 1,
        'completionFacts': 1,
        'writerScenes': 1,
        'events': 1,
        'sceneTitles': 5,
        'maps': 0,
      });
    });

    test(
        'the outline reads a portable project without preparing indexes JSONL=$wire',
        () async {
      final base = await NarrativeTitleFixture.qa.create(recursive: true);
      final root = await base.createTemp('portable-storyline-');
      addTearDown(() => root.delete(recursive: true));
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final publication =
          PortableCatalogPublication.encodeProject(storylineOutlineProject(0));
      await store.publish(publication.storage, expectedRootRevision: null);
      final descriptor = File('${root.path}/project.json');
      final original = jsonEncode(publication.descriptor);
      await descriptor.writeAsString(original, flush: true);
      final head = await store.readHead();

      final result =
          await query(root, storylineOutlineResourceKind, wire: wire);
      final item = result.items.single;
      final story = (item['storylines'] as List).single as Map;
      final chapter = (story['chapters'] as List).single as Map;
      final milestones = chapter['milestones'] as List;
      expect(milestones.map((step) => step['id']), ['wake_up', 'leave_home']);
      expect(milestones.first['mapIds'], ['map_0']);
      expect(milestones.first['issues'],
          ['completionFactShared', 'completionFactCanReset']);
      expect(
          (item['scenesOutsideStorylines'] as List).map((scene) => scene['id']),
          ['arrival', 'farewell', 'scene_town', 'scene_reset']);
      expect((item['reads'] as Map)['maps'], 0);
      expect(await descriptor.readAsString(), original);
      expect(await store.readHead(), head);
    });
  }

  test('the proposal drafts a storyline only for a project without one',
      () async {
    final project = storylineOutlineProject(0).copyWith(storylines: const []);
    final fixture = await NarrativeTitleFixture.create(project: project);
    addTearDown(fixture.close);
    final item =
        (await query(fixture.root, storylineProposalResourceKind)).items.single;
    expect(item['persisted'], false);
    expect(item['milestoneCount'], 1);
    final storyline = StorylineAsset.fromJson(
        Map<String, dynamic>.from(item['storyline'] as Map));
    expect(
        storyline.chapters.single.steps.single.sceneLinkIds, ['scene_reset']);

    final existing =
        await NarrativeTitleFixture.create(project: storylineOutlineProject(0));
    addTearDown(existing.close);
    expect(
        (await query(existing.root, storylineProposalResourceKind))
            .items
            .single,
        {'storyline': null, 'reason': 'storylinesExist'});
  });

  test('the outline reads the same units whatever the unrelated content',
      () async {
    Future<Map<String, int>> reads(int unrelated) async {
      final fixture = await NarrativeTitleFixture.create(
          project: storylineOutlineProject(unrelated));
      try {
        await fixture.prepare();
        await fixture.prepare(CatalogNarrativeUsages.preparationScope);
        late Map<String, int> counted;
        await query(fixture.root, storylineOutlineResourceKind,
            measure: (read) async =>
                counted = await CatalogUnitReads(fixture.root).count(read));
        return counted;
      } finally {
        await fixture.close();
      }
    }

    final small = await reads(0);
    final large = await reads(300);
    printOnFailure(jsonEncode({'small': small, 'large': large}));
    const titlePages = {'narrativeTitles', 'narrativeTitleIndex'};
    expect({...large}..removeWhere((label, _) => titlePages.contains(label)),
        {...small}..removeWhere((label, _) => titlePages.contains(label)));
    expect(large['narrativeTitles']! ~/ small['narrativeTitles']!, 3,
        reason: 'one title page per 128 scenes, never a scene definition');
    expect(large['projectDefinition:scenes'],
        large['projectDefinition:storylines'],
        reason: 'the single writer scene is read like the single storyline');
    expect(large.keys.where((label) => label.contains('maps')), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
