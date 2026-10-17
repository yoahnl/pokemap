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
    'editor adapter repairs an invalid evolution through canonical plan/apply',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pmcp_evolution_repair_',
      );
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(() async {
        await mutations.closeAll();
        await queries.closeAll();
        await root.delete(recursive: true);
      });
      final manifest = File('${root.path}/project.json');
      await manifest.writeAsString(
        jsonEncode(
          const ProjectManifest(
            name: 'Evolution repair',
            maps: [],
            tilesets: [],
          ).toJson(),
        ),
      );
      final manifestBefore = await manifest.readAsBytes();
      final original = {
        'schemaVersion': 1,
        'speciesId': 'seadra',
        'preEvolution': 'horsea',
        'evolutions': [
          {
            'method': 'trade',
            'targetSpeciesId': 'kingdra',
            'itemId': 'dragon_scale',
          },
        ],
      };
      final replacement = {
        ...original,
        'evolutions': [
          {
            'method': 'trade',
            'targetSpeciesId': 'kingdra',
            'tradeRequirements': {'requiredHeldItemId': 'dragon_scale'},
          },
        ],
      };
      final file = File('${root.path}/data/pokemon/evolutions/seadra.json');
      await file.parent.create(recursive: true);
      final before = utf8.encode(jsonEncode(original));
      await file.writeAsBytes(before);
      final plan = await mutations.plan(
        root.path,
        actionId: 'pokemon.evolution.write',
        parameters: {
          'relativePath': 'data/pokemon/evolutions/seadra.json',
          'document': replacement,
          'beforeBytesBase64': base64Encode(before),
        },
        idempotencyKey: 'editor-evolution-repair',
      );
      expect(await file.readAsBytes(), before);
      final applied = await mutations.apply(
        plan,
        operationId: 'editor-evolution-repair',
      );
      expect(applied.receipt.actionId, 'pokemon.evolution.write');
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      expect(
        jsonDecode(await file.readAsString()),
        PokemonEvolutionFile.fromJson(replacement).toJson(),
      );
      expect(await manifest.readAsBytes(), manifestBefore);
    },
  );
}
