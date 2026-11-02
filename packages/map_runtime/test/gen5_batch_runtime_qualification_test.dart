import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_recipe_compiler.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_static_admission.dart';
import 'package:path/path.dart' as p;

void main() {
  final root = Platform.environment['AVELUNE_BW2_BATCH_CANDIDATES'];
  test(
    'qualifies generated recipes against the current runtime admission',
    () async {
      final manifest = jsonDecode(
        await File(p.join(root!, 'manifest.json')).readAsString(),
      ) as Map;
      final rows = <Map<String, Object?>>[];
      final counts = <String, int>{};
      for (final item in (manifest['moves'] as List).cast<Map>()) {
        if (item['status'] != 'review' || item['apiValidation'] != 'passed') {
          continue;
        }
        var status = 'admitted';
        try {
          final bundle = jsonDecode(
            await File(p.join(root, item['bundle'] as String)).readAsString(),
          ) as Map;
          final recipeBytes = base64.decode(bundle['recipe'] as String);
          final recipe = BattleMoveAnimationRecipe.fromJson(
            jsonDecode(utf8.decode(recipeBytes)) as Map<String, dynamic>,
          );
          final media = <String, List<int>>{
            for (final entry in (bundle['media'] as Map).entries)
              entry.key as String: base64.decode(entry.value as String),
          };
          final selection = const BattleMoveRecipeCompiler().selectGroupedSpl(
            recipe,
          );
          if (selection == null) {
            status = 'fallback:unsupported-recipe-shape';
          } else {
            final all = recipe.readVerifiedSplParticleDefinitions(
              media,
              availableCapabilities:
                  BattleMoveAnimationRecipe.recognizedCapabilities,
            );
            final selected = [
              for (final part in selection.particles) all[part.resourceId]!,
            ];
            final version = selected.first.schemaVersion;
            if (selected.any((part) => part.schemaVersion != version)) {
              status = 'fallback:mixed-particle-versions';
            } else {
              final definition = selected.length == 1
                  ? selected.single
                  : BattleSplParticleDefinition.fromJson({
                      'schemaVersion': version,
                      'emitters': [
                        for (final part in selected)
                          ...(part.toJson()['emitters'] as List),
                      ],
                    });
              final textures = definition.textureIds.toList()..sort();
              final emitters = [
                for (var i = 0; i < definition.emitters.length; i++)
                  BattleSplStaticEmitter(
                    emitterIndex: i,
                    startTick: 0,
                    position: (x: 0, y: 0, z: 0),
                  ),
              ];
              final result = BattleSplStaticAdmission.prepare(
                definition: definition,
                textureIndices: {
                  for (var i = 0; i < textures.length; i++) textures[i]: i,
                },
                emitters: emitters,
                seed: 0,
                poolCapacity: 128,
                maxTicks: 200,
              );
              if (result.failure != null) {
                status = 'fallback:${result.failure!.name}';
              }
              result.playback?.cancel();
            }
          }
        } on Object {
          status = 'fallback:invalid-or-unavailable-definition';
        }
        counts.update(status, (value) => value + 1, ifAbsent: () => 1);
        rows.add({
          'id': item['id'],
          'move': item['move'],
          'runtimeAdmission': status,
        });
      }
      expect(rows, isNotEmpty);
      await File(p.join(root, 'runtime-qualification.json')).writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'scope': 'selection-and-static-admission-only',
          'counts': counts,
          'moves': rows,
        }),
        flush: true,
      );
      stdout.writeln(
        jsonEncode({'runtimeAdmission': counts, 'count': rows.length}),
      );
    },
    skip: root == null,
  );
}
