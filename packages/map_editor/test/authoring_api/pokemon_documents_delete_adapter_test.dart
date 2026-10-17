import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'editor adapter confirms, deletes and restores exact Pokemon copies',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'editor-pokemon-delete-',
      );
      final root = Directory(await temporary.resolveSymbolicLinks());
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/project.json').writeAsString(
        jsonEncode(
          const ProjectManifest(
            name: 'Copies',
            maps: [],
            tilesets: [],
          ).toJson(),
        ),
      );
      final documents = <Map<String, Object?>>[];
      for (final entry in [
        ('learnsets', 'learnset', 'alpha'),
        ('evolutions', 'evolution', 'beta'),
      ]) {
        final path = 'data/pokemon/${entry.$1}/${entry.$3} 2.json';
        final bytes = utf8.encode(
          '{"speciesId":"${entry.$3}","sourceField":true}\n',
        );
        final file = File('${root.path}/$path');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        documents.add({
          'actionId': 'pokemon.${entry.$2}.delete',
          'parameters': {
            'relativePath': path,
            'resourceId': entry.$3,
            'beforeBytesBase64': base64Encode(bytes),
          },
        });
      }
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(() async {
        await mutations.closeProject(root.path);
        await queries.closeProject(root.path);
      });
      final plan = await mutations.plan(
        root.path,
        actionId: 'pokemon.documents.delete',
        parameters: {'documents': documents},
        idempotencyKey: 'delete-copies',
      );
      final token = await mutations.confirm(plan);
      final result = await mutations.apply(
        plan,
        operationId: 'delete-copies',
        confirmationToken: token,
      );
      expect(result.receipt.status, AuthoringReceiptStatus.applied);
      for (final member in documents) {
        final parameters = member['parameters']! as Map;
        expect(
          await File('${root.path}/${parameters['relativePath']}').exists(),
          isFalse,
        );
      }
      await mutations.undo(
        root.path,
        entryId: result.receipt.receiptId,
        idempotencyKey: 'restore-copies',
      );
      for (final member in documents) {
        final parameters = member['parameters']! as Map;
        expect(
          await File(
            '${root.path}/${parameters['relativePath']}',
          ).readAsBytes(),
          base64Decode(parameters['beforeBytesBase64'] as String),
        );
      }
    },
  );
}
