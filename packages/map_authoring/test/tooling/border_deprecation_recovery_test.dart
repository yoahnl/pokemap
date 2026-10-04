import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/border_deprecated_placement_test.dart'
    show placementFixture;
import 'jsonl_border_catalog_flow_test.dart' show BorderCatalogHarness;

void main() {
  for (final checkpoint in [
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    AuthoringTransactionCheckpoint.afterResourcePromoted,
  ]) {
    test('deprecation recovers honestly after ${checkpoint.name}', () async {
      var crash = false;
      var reachedFault = false;
      final harness = await BorderCatalogHarness.create('deprecation-recovery',
          faultInjector: (context) {
        if (crash &&
            context.operationId == 'deprecation-crash' &&
            context.checkpoint == checkpoint) {
          reachedFault = true;
          throw const AuthoringTransactionSimulatedCrash();
        }
      });
      addTearDown(harness.dispose);
      await harness.runJsonlLifecycle();
      final projectFile = File('${harness.root.path}/project.json');
      final raw =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
      ((raw['borderCatalog'] as Map)['records'] as List)
          .single['isDeprecated'] = false;
      raw['foreign'] = {
        'nested': ['été', 13]
      };
      final map = placementFixture().map;
      raw['maps'] = [
        ProjectMapEntry(id: map.id, name: map.name, relativePath: 'closed.json')
            .toJson()
      ];
      await projectFile.writeAsString(jsonEncode(raw));
      final mapFile = File('${harness.root.path}/closed.json');
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      final beforeBytes = await projectFile.readAsBytes();
      final before = ProjectManifest.fromJson(raw);
      final snapshots = before.borderCatalog.visualSnapshots;
      expect(snapshots, isNotEmpty);
      final preserved = <String, List<int>>{
        'closed.json': await mapFile.readAsBytes(),
        for (final snapshot in snapshots)
          for (final frame in snapshot.frames)
            frame.relativeAssetPath:
                await File('${harness.root.path}/${frame.relativeAssetPath}')
                    .readAsBytes(),
      };
      final opened = await harness.readApi.open(harness.root.path);
      final project = ProjectHandle(opened['projectHandle'] as String);
      await harness.mutations.attachProject(
          projectRootPath: harness.root.path,
          workspaceHandle: WorkspaceHandle(opened['workspaceHandle'] as String),
          projectHandle: project);
      final snapshot = await harness.snapshots.load(project);
      final plan = await harness.mutations.plan(
          project,
          AuthoringRequest(
              requestId: 'deprecation-fault',
              actionId: 'border.blueprint.set_deprecated',
              actionVersion: 1,
              workspaceHandle: opened['workspaceHandle'] as String,
              parameters: {'blueprintId': 'fence', 'isDeprecated': true},
              expectedRevision: snapshot.revision,
              idempotencyKey: 'deprecation-fault'));
      expect(await projectFile.readAsBytes(), beforeBytes);
      final confirmation = await harness.mutations
          .confirm(project, planId: plan['planId'] as String);
      crash = true;
      await expectLater(
          harness.mutations.apply(project,
              planId: plan['planId'] as String,
              operationId: 'deprecation-crash',
              confirmationToken: confirmation['confirmationToken'] as String),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      expect(reachedFault, true);
      final interrupted = ProjectManifest.fromJson(
          jsonDecode(await projectFile.readAsString()));
      expect(interrupted.borderCatalog.records.single.isDeprecated,
          checkpoint == AuthoringTransactionCheckpoint.afterResourcePromoted);
      if (checkpoint ==
          AuthoringTransactionCheckpoint.beforeResourcePromotion) {
        expect(await projectFile.readAsBytes(), beforeBytes);
      }
      for (final entry in preserved.entries) {
        expect(await File('${harness.root.path}/${entry.key}').readAsBytes(),
            entry.value);
      }
      crash = false;
      final recovered = await harness.mutations
          .recover(project, operationId: 'deprecation-crash');
      expect((recovered['receipt'] as Map)['status'], 'recovered');
      final reread = await _independent(harness.root);
      final record = reread.manifest.borderCatalog.records.single;
      expect(record.isDeprecated, true);
      expect(record.draft, before.borderCatalog.records.single.draft);
      expect(record.latestPublished,
          before.borderCatalog.records.single.latestPublished);
      expect(reread.manifest.borderCatalog.visualSnapshots, snapshots);
      expect(reread.maps.single, map);
      final afterRaw =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
      expect(afterRaw['foreign'], raw['foreign']);
      expect(afterRaw['elements'], raw['elements']);
      expect(afterRaw['tilesets'], raw['tilesets']);
      expect(
          Map<String, dynamic>.of(afterRaw)
            ..remove('borderCatalog')
            ..remove('version'),
          Map<String, dynamic>.of(raw)
            ..remove('borderCatalog')
            ..remove('version'));
      for (final entry in preserved.entries) {
        expect(await File('${harness.root.path}/${entry.key}').readAsBytes(),
            entry.value);
      }
    });
  }
}

Future<ProjectSnapshot> _independent(Directory root) async {
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final opened = await ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles)
      .openProject(root.path);
  try {
    return await ProjectSnapshotLoader(handles: handles)
        .load(opened.projectHandle);
  } finally {
    handles.closeWorkspace(opened.workspaceHandle);
  }
}
