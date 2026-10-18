import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';
import 'resource_pack_transfer_api_test.dart' show waitForJob;

void main() {
  test('diagnose refuses a stale saved-project revision', () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final project = fixture.opened.projectHandle;
      final before = (await fixture.loader.load(project)).revision;
      final done = await waitForJob(api, project,
          await api.transfer(project, verb: 'diagnose', input: {
        'expectedRevision': 'sha256:${'0' * 64}',
      }));
      expect((done['snapshot'] as Map)['state'], 'failed');
      expect((done['snapshot'] as Map)['errorCode'], 'resource_pack.project_stale');
      expect(done['result'], isNull);
      expect((await fixture.loader.load(project)).revision, before);
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  for (final release in [false, true]) {
    test('diagnose refuses a selection ${release ? 'released' : 'changed'} while queued', () async {
      final fixture = await NativeResourcePackImportFixture.create();
      final api = LocalResourcePackTransferApi(
          mutations: fixture.mutations, snapshotLoader: fixture.loader);
      try {
        final project = fixture.opened.projectHandle;
        final selected = await api.transfer(project,
            verb: 'selection.create', input: {'mode': 'native'});
        final start = await api.transfer(project, verb: 'diagnose', input: {
          'expectedRevision': selected['sourceRevision'],
          'selectionHandle': selected['selectionHandle'],
          'revision': selected['revision'],
        });
        await api.transfer(project, verb: release ? 'release' : 'selection.patch',
          input: release ? {'handle': selected['selectionHandle']} : {
            'selectionHandle': selected['selectionHandle'],
            'revision': selected['revision'], 'add': []});
        final done = await waitForJob(api, project, start);
        expect((done['snapshot'] as Map)['state'], 'failed');
        expect((done['snapshot'] as Map)['errorCode'], 'resource_pack.selection_stale');
        expect(done['result'], isNull);
      } finally {
        await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
        await fixture.dispose();
      }
    });
  }

  test('diagnose reports the saved project without creating a preparation',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final project = fixture.opened.projectHandle;
      final before = await fixture.loader.load(project);
      final result = await waitForJob(api, project,
          await api.transfer(project, verb: 'diagnose', input: {
        'expectedRevision': before.revision,
      }));
      expect((result['snapshot'] as Map)['state'], 'succeeded',
          reason: result.toString());
      final value = result['result'] as Map;
      final report = (value['budgetReports'] as List).single as Map;
      expect(report['scope'], 'sourceProjectDistribution');
      expect((report['totals'] as Map)['sourceDocumentBytes'],
          before.resourceBytes('project').length);
      expect((report['totals'] as Map)['catalogBytes'],
          const CatalogBudgetCalculator()
              .measureProjectJson(before.manifest.toJson())
              .totals['catalogBytes']);
      expect(value.containsKey('preparedImportHandle'), isFalse);
      expect(value.containsKey('preparedExportHandle'), isFalse);
      expect((await fixture.loader.load(project)).revision, before.revision);
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test('diagnose native selection retains source and selection revisions',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    await fixture.apply(await fixture.plan(await fixture.prepare()));
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final project = fixture.opened.projectHandle;
      final selected = await api.transfer(project,
          verb: 'selection.create', input: {'mode': 'native'});
      final chosen = await api.transfer(project,
          verb: 'selection.select_filtered', input: {
        'selectionHandle': selected['selectionHandle'],
        'revision': selected['revision'],
        'filter': {'kind': 'tileset'},
      });
      final done = await waitForJob(api, project,
          await api.transfer(project, verb: 'diagnose', input: {
        'selectionHandle': chosen['selectionHandle'],
        'revision': chosen['revision'],
        'expectedRevision': selected['sourceRevision'],
      }));
      expect((done['snapshot'] as Map)['state'], 'succeeded',
          reason: done.toString());
      final value = done['result'] as Map;
      expect(value['selectionRevision'], chosen['revision']);
      expect(value['sourceRevision'], selected['sourceRevision']);
      final reports = (value['budgetReports'] as List).cast<Map>();
      expect(reports.map((r) => r['scope']),
          containsAll(['sourceProjectDistribution', 'nativeSelection']));
      final selectedReport = reports.singleWhere(
          (r) => r['scope'] == 'nativeSelection');
      expect((selectedReport['totals'] as Map)['files'], greaterThan(0));
      final after = await api.transfer(project,
          verb: 'entries', input: {'selectionHandle': chosen['selectionHandle']});
      expect(after['items'], isNotEmpty);
      expect((await fixture.loader.load(project)).revision,
          selected['sourceRevision']);
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test('archive diagnosis includes the full inspected file inventory', () async {
    final fixture = await NativeResourcePackImportFixture.create(allowPackSources: true);
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final project = fixture.opened.projectHandle;
      final sourcePath = '${fixture.root.path}/source.aveluneassets';
      final sink = File(sourcePath).openWrite();
      await fixture.source.archive.withSource(
          (source) => sink.addStream(sourceChunks(source)));
      await sink.close();
      final staged = await waitForJob(api, project, await api.transfer(project,
          verb: 'stage', input: {'sourcePath': sourcePath}));
      expect((staged['snapshot'] as Map)['state'], 'succeeded',
          reason: staged.toString());
      final inspected = await waitForJob(api, project, await api.transfer(project,
          verb: 'inspect', input: {
            'archiveHandle': (staged['result'] as Map)['archiveHandle'],
          }));
      expect((inspected['snapshot'] as Map)['state'], 'succeeded');
      final selected = await api.transfer(project, verb: 'selection.create', input: {
        'mode': 'archive',
        'inspectionHandle': (inspected['result'] as Map)['inspectionHandle'],
      });
      final revision = (await fixture.loader.load(project)).revision;
      final done = await waitForJob(api, project, await api.transfer(project,
          verb: 'diagnose', input: {
        'expectedRevision': revision,
        'selectionHandle': selected['selectionHandle'],
        'revision': selected['revision'],
      }));
      expect((done['snapshot'] as Map)['state'], 'succeeded');
      final reports = ((done['result'] as Map)['budgetReports'] as List).cast<Map>();
      final report = reports.singleWhere((r) => r['scope'] == 'inspectedArchive');
      final inventory = fixture.source.archive.inspection.manifest.content.files;
      expect((report['totals'] as Map)['files'], inventory.length);
      expect((report['totals'] as Map)['fileBytes'],
          inventory.fold<int>(0, (sum, file) => sum + file.byteLength));
      expect((await fixture.loader.load(project)).revision, revision);
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test('failed jobs preserve all safe budget facts and readable messages',
      () async {
    const metric = CatalogBudgetMetric(scope: 'nativeSelection',
      dimension: 'supports', observed: 10001, allowed: 10000,
      unit: 'count', label: 'Définitions techniques',
      remedy: 'Partager les définitions équivalentes.');
    final report = CatalogBudgetReport(scope: 'nativeSelection', metrics: [metric]);
    final jobs = ResourcePackJobService(requireActive: () {});
    try {
      final start = await jobs.startWork(AuthoringJobRequest(
        requestId: 'budget', kind: 'resource_pack.prepare', projectId: 'p',
        projectRevision: 'sha256:${'0' * 64}',
      ), (_) async => throw CatalogBudgetExceededException(report));
      while (!(await jobs.get(start.jobId)).state.isTerminal) {
        await Future<void>.delayed(Duration.zero);
      }
      final result = jobs.result(start.jobId);
      expect((result['snapshot'] as Map)['errorCode'], 'catalog.budget_exceeded');
      expect((result['snapshot'] as Map)['errorMessage'], contains('10001'));
      expect((result['result'] as Map)['budgetReport'], report.toJson());
      expect(utf8.encode(jsonEncode(result)).length, lessThan(240 * 1024));
    } finally {
      await jobs.close();
    }
  });

  test('archive quota failures retain their code and bounded report', () async {
    final report = CatalogBudgetReport(scope: 'inspectedArchive', metrics: [
      const CatalogBudgetMetric(scope: 'inspectedArchive',
        dimension: 'resources', observed: 10001, allowed: 10000,
        unit: 'count', label: 'Ressources', remedy: 'Réduire la sélection.'),
    ]).toBoundedJson(maximumBytes: 96 * 1024);
    final jobs = ResourcePackJobService(requireActive: () {});
    try {
      final start = await jobs.startWork(AuthoringJobRequest(
        requestId: 'archive-budget', kind: 'resource_pack.inspect', projectId: 'p',
        projectRevision: 'sha256:${'0' * 64}',
      ), (_) async => throw GamePackageFormatException(
        code: 'resource_limit', path: 'catalog.json', message: 'Too many resources.',
        details: {'budgetReport': report},
      ));
      while (!(await jobs.get(start.jobId)).state.isTerminal) {
        await Future<void>.delayed(Duration.zero);
      }
      final result = jobs.result(start.jobId);
      expect((result['snapshot'] as Map)['errorCode'], 'resource_limit');
      expect((result['result'] as Map)['budgetReport'], report);
      expect(utf8.encode(jsonEncode(result)).length, lessThan(240 * 1024));
    } finally {
      await jobs.close();
    }
  });
}
