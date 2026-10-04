import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'resource_information_fixture.dart';

void main() {
  for (final transport in ['direct', 'jsonl']) {
    test(
        '$transport resource information and organization use real canonical transactions',
        () async {
      final fixture =
          await ResourceInformationFixture.create(smartInformationFixture());
      addTearDown(fixture.dispose);
      var sequence = 0;
      Future<Map<String, Object?>> call(
          String command, Map<String, Object?> args) async {
        if (transport == 'jsonl') {
          final result = await fixture.command(command, args);
          expect(result.status, AuthoringResultStatus.success,
              reason: jsonEncode(result.toJson()));
          return result.data;
        }
        return switch (command) {
          'plan' => fixture.mutations.plan(
              ProjectHandle(fixture.project),
              AuthoringRequest.fromJson(
                  Map<String, dynamic>.from(args['request']! as Map))),
          'confirm' => fixture.mutations.confirm(ProjectHandle(fixture.project),
              planId: args['planId']! as String),
          'apply' => fixture.mutations.apply(ProjectHandle(fixture.project),
              planId: args['planId']! as String,
              operationId: args['operationId']! as String,
              confirmationToken: args['confirmationToken'] as String?),
          _ => throw StateError(command),
        };
      }

      Future<void> mutate(String action, Map<String, Object?> params,
          {bool destructive = false}) async {
        final snapshot =
            await fixture.snapshots.load(ProjectHandle(fixture.project));
        final planned = await call('plan', {
          'projectHandle': fixture.project,
          'request': AuthoringRequest(
                  requestId: 'wire-${sequence++}',
                  actionId: action,
                  actionVersion: 1,
                  workspaceHandle: fixture.workspace,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: 'key-${sequence++}',
                  parameters: params)
              .toJson()
        });
        final args = <String, Object?>{
          'projectHandle': fixture.project,
          'planId': planned['planId'],
          'operationId': 'apply-${sequence++}'
        };
        if (destructive) {
          final confirmed = await call('confirm',
              {'projectHandle': fixture.project, 'planId': planned['planId']});
          args['confirmationToken'] = confirmed['confirmationToken'];
        }
        final result = await call('apply', args);
        expect((result['receipt'] as Map)['status'], 'applied');
        final bytes =
            await File('${fixture.root.path}/project.json').readAsBytes();
        final replayed = await call('apply', args);
        expect((replayed['receipt'] as Map)['status'], 'applied');
        expect(await File('${fixture.root.path}/project.json').readAsBytes(),
            bytes);
      }

      final description = await fixture.command('describe', {});
      final descriptor = (description.data['mutationActions'] as List)
          .cast<Map>()
          .singleWhere((entry) => entry['id'] == 'tileset.metadata.update');
      final schema = (descriptor['extensions'] as Map)['inputSchema'] as Map;
      expect(schema['additionalProperties'], false);
      expect((schema['properties'] as Map).keys.toSet(),
          {'tilesetId', 'name', 'folderId'});
      await mutate('tileset_folder.upsert', {
        'folder': {'id': 'new', 'name': 'Façades'}
      });
      await mutate('tileset.metadata.update',
          {'tilesetId': 'sheet', 'name': 'Été', 'folderId': 'new'});
      await mutate('tileset_folder.upsert', {
        'folder': {
          'id': 'new',
          'name': 'Façades été',
          'parentFolderId': 'shared'
        }
      });
      await mutate('element_category.upsert', {
        'category': {'id': 'new', 'name': 'Mobilier'}
      });
      await mutate('element.category.assign',
          {'elementId': 'decor', 'categoryId': 'new'});
      await mutate('smart_tile.category.upsert', {
        'category': {'id': 'new', 'name': 'Sols'}
      });
      await mutate('smart_tile.preset.category.assign',
          {'presetId': 'ground', 'categoryId': 'new'});
      final changed = await fixture.read();
      expect(changed.tilesets.single.name, 'Été');
      expect(changed.tilesets.single.folderId, 'new');
      expect(changed.tilesetFolders.last.parentFolderId, 'shared');
      expect(changed.elements.single.categoryId, 'new');
      expect(changed.smartTileCatalog.presets.single.categoryId, 'new');
      expect(changed.smartTileCatalog.drafts,
          smartInformationFixture().smartTileCatalog.drafts);
      for (final family in [
        'tileset_folder',
        'element_category',
        'smart_tile.category'
      ]) {
        final key = family == 'tileset_folder' ? 'folder' : 'category';
        await mutate('$family.upsert', {
          key: {'id': 'empty', 'name': 'Vide'}
        });
        await mutate('$family.delete', {'${key}Id': 'empty'},
            destructive: true);
      }
      expect((await fixture.read()).tilesets, changed.tilesets);
      expect((await fixture.read()).elements, changed.elements);
    });
  }
}
