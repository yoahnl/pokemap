import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/resource_pack_stdio_client.dart';

void main() {
  for (final mode in [
    '--verify-no-window-api',
    '--verify-unprepared-v3-api',
    '--verify-v3-race-api'
  ]) {
    test('direct API refuses missing prerequisites without writes $mode',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('context-prerequisites-');
      final root = Directory('${directory.path}/project');
      try {
        final result = await Process.run('dart', [
          'run',
          'test/support/create_metadata_context_fixture.dart',
          root.path,
          mode
        ]);
        expect(result.exitCode, 0,
            reason: '${result.stdout}\n${result.stderr}');
      } finally {
        await _removeAdmissions(root.path);
        await directory.delete(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
  for (final direct in [true, false]) {
    test(
        '${direct ? 'direct API' : 'JSONL CLI'} explicitly prepares metadata context',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('context-transport-');
      final root = Directory('${directory.path}/project');
      ResourcePackStdioClient? client;
      try {
        final fixture = await Process.run('dart', [
          'run',
          'test/support/create_metadata_context_fixture.dart',
          root.path,
          if (direct) '--verify-api',
        ]);
        expect(fixture.exitCode, 0,
            reason: '${fixture.stdout}\n${fixture.stderr}');
        if (direct) return;
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        client = await ResourcePackStdioClient.start(root.path);
        final description = await client.call('describe', {});
        expect(description['workshopPreparation'], isA<Map>());
        final contract = description['workshopPreparation'] as Map;
        expect(contract['scopes'], contains('metadataContext'));
        final context = contract['metadataContext'] as Map;
        expect(context['contextVersion'], 1);
        expect(context['requiresPreparedLocalUndoWindow'], isTrue);
        expect(context['requiresPreparedMetadataIndexes'], isTrue);
        final opened = await client.call('open', {'projectRoot': root.path});
        await client.call(
            'workshop_prepare', {'projectHandle': opened['projectHandle']});
        final snapshot =
            (await store.openRoot((await store.readHead())!)).snapshot;
        expect(await store.metadataContextRevision(snapshot), isNull);
        final head = await File('${root.path}/catalog/HEAD.json').readAsBytes();
        final prepared = await client.call('workshop_prepare', {
          'projectHandle': opened['projectHandle'],
          'scope': 'metadataContext',
        });
        expect(prepared['scope'], 'explicitCatalogMetadataContext');
        expect(prepared['contextVersion'], 1);
        expect(prepared['metadataRevision'],
            await store.requireMetadataContextAdmission(snapshot));
        expect(
            await File('${root.path}/catalog/HEAD.json').readAsBytes(), head);
        final repeated = await client.call('workshop_prepare', {
          'projectHandle': opened['projectHandle'],
          'scope': 'metadataContext',
        });
        expect(repeated, prepared);
        await client
            .call('close', {'workspaceHandle': opened['workspaceHandle']});
      } finally {
        await client?.close();
        await _removeAdmissions(root.path);
        await directory.delete(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}

Future<void> _removeAdmissions(String project) async {
  final home =
      Platform.environment[Platform.isWindows ? 'LOCALAPPDATA' : 'HOME'];
  final directory = Directory('$home/.avelune/authoring/catalog-admissions');
  if (!await directory.exists()) return;
  await for (final file in directory.list()) {
    if (file is! File || !file.path.endsWith('.json')) continue;
    final String source;
    try {
      source = await file.readAsString();
    } on PathNotFoundException {
      continue;
    }
    final value = jsonDecode(source) as Map;
    if (value['projectRoot'] == project ||
        (value['admission'] as Map?)?['projectRoot'] == project) {
      try {
        await file.delete();
      } on PathNotFoundException {
        continue;
      }
    }
  }
}
