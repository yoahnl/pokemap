import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_recipe_converter.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_source_recipe_converter.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final root = Directory('../../tools/avelune_attack_comparator/assets/bw2');
  for (final pilot in [
    (id: 'tackle', file: 'tackle', particle: 199, indices: [0, 1], emissions: 2),
    (id: 'water-gun', file: 'water_gun', particle: 220, indices: [0, 1], emissions: 17),
    (id: 'surf', file: 'surf', particle: 222, indices: [3, 1, 4, 5, 2], emissions: 5),
  ]) {
    test('preserves the complete ${pilot.id} source sequence and media', () {
      final program = jsonDecode(File('${root.path}/${pilot.file}.json').readAsStringSync())
          as Map<String, dynamic>;
      final directory = Directory('${root.path}/particle${pilot.particle}');
      final definitionBytes = File('${directory.path}/definition.json').readAsBytesSync();
      final definition = BattleSplParticleDefinition.fromJson(
        jsonDecode(utf8.decode(definitionBytes)) as Map<String, dynamic>,
      );
      final textures = <String, Uint8List>{};
      for (final id in definition.textureIds) {
        final png = File('${directory.path}/$id.png');
        textures[id] = png.existsSync() ? png.readAsBytesSync()
            : base64Decode(File('${directory.path}/$id.b64').readAsStringSync().trim());
      }
      final result = Gen5SourceRecipeConverter.convert(
        moveId: pilot.id,
        sourceProgram: program,
        particles: {pilot.particle: Gen5BatchParticle(
          definition: definitionBytes, textures: textures,
          sourceEmitterIndices: pilot.indices, warnings: const {'example-approximation'},
        )},
      );
      final recipe = result.bundle.recipe;
      final visual = recipe.toJson()['program'] as Map;
      expect(visual['sourceProgram'], program);
      final bindings = (visual['particleBindings'] as List).cast<Map>();
      expect(bindings.single['sourceEmitterIndices'], pilot.indices);
      final instructions = ((visual['sourceProgram'] as Map)['instructions'] as List).cast<Map>();
      expect(instructions.where((value) => (value['op'] as String).startsWith('start') &&
          (value['op'] as String).endsWith('Emitter')), hasLength(pilot.emissions));
      expect(recipe.unsupportedCapabilities({...BattleMoveAnimationRecipe.recognizedCapabilities}
          ..remove('gen5SourceProgram')), {'gen5SourceProgram'});
      expect(result.warnings, contains('source-audio-not-mapped'));
      expect(result.warnings, contains('source-program-not-reverified'));
      expect(result.warnings, contains('example-approximation'));
      expect(() => Gen5SourceRecipeConverter.convert(
        moveId: pilot.id, sourceProgram: program, particles: {},
      ), throwsFormatException);
      expect(() => Gen5SourceRecipeConverter.convert(
        moveId: pilot.id, sourceProgram: program,
        particles: {pilot.particle: Gen5BatchParticle(
          definition: definitionBytes, textures: textures,
          sourceEmitterIndices: [for (final _ in pilot.indices) 0],
        )},
      ), throwsFormatException);
    });
  }
}
