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

  test('preserves a version 18 source effect with verified dependencies', () {
    final workshop = jsonDecode(
      File('${root.path}/batch/dragon-breath.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final definition = Uint8List.fromList(
      utf8.encode(jsonEncode(workshop['definition'])),
    );
    final textures = {
      for (final entry in (workshop['textures'] as Map).entries)
        entry.key as String: base64Decode(entry.value as String),
    };
    final result = Gen5SourceRecipeConverter.convert(
      moveId: 'dragon-breath',
      sourceProgram: (workshop['program'] as Map).cast<String, dynamic>(),
      particles: {
        workshop['particle'] as int: Gen5BatchParticle(
          definition: definition,
          textures: textures,
          sourceEmitterIndices:
              (workshop['sourceEmitterIndices'] as List).cast<int>(),
        ),
      },
    );
    final recipe = result.bundle.recipe;
    expect(recipe.toJson()['requiredCapabilities'], contains('splParticleV18'));
    expect(
      recipe.readVerifiedSplParticleDefinitions(
        result.bundle.media,
        availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      ).values.single.schemaVersion,
      18,
    );
    final missingCapability = recipe.toJson();
    (missingCapability['requiredCapabilities'] as List).remove('splParticleV18');
    expect(
      () => BattleMoveAnimationRecipe.fromJson(missingCapability),
      throwsFormatException,
    );
    final alteredMedia = Map<String, Uint8List>.from(result.bundle.media);
    alteredMedia[textures.keys.first] = Uint8List.fromList([0]);
    expect(
      () => recipe.readVerifiedSplParticleDefinitions(
        alteredMedia,
        availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      ),
      throwsFormatException,
    );
  });

  test('preserves the background needed by the Hyper Beam source program', () {
    final workshop = jsonDecode(
      File('${root.path}/batch/hyper-beam.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final backgrounds = {
      for (final entry in (workshop['backgrounds'] as Map).entries)
        int.parse(entry.key as String): base64Decode(entry.value as String),
    };
    final result = Gen5SourceRecipeConverter.convert(
      moveId: 'hyper-beam',
      sourceProgram: (workshop['program'] as Map).cast<String, dynamic>(),
      particles: {
        workshop['particle'] as int: Gen5BatchParticle(
          definition: Uint8List.fromList(utf8.encode(jsonEncode(workshop['definition']))),
          textures: {
            for (final entry in (workshop['textures'] as Map).entries)
              entry.key as String: base64Decode(entry.value as String),
          },
          sourceEmitterIndices:
              (workshop['sourceEmitterIndices'] as List).cast<int>(),
        ),
      },
      backgrounds: backgrounds,
    );
    final recipe = result.bundle.recipe.toJson();
    expect(recipe['requiredCapabilities'], contains('gen5SourceBackground'));
    final bindings = (recipe['program'] as Map)['backgroundBindings'] as List;
    expect(bindings, hasLength(1));
    expect((bindings.single as Map)['background'], 33);
    expect(result.bundle.media[(bindings.single as Map)['resourceId']], backgrounds[33]);
  });

  test('preserves animated background frames and their timing', () {
    final workshop = jsonDecode(
      File('${root.path}/batch/double-edge.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final backgrounds = {
      for (final entry in (workshop['backgrounds'] as Map).entries)
        int.parse(entry.key as String): base64Decode(entry.value as String),
    };
    final animations = {
      for (final entry in (workshop['backgroundAnimations'] as Map).entries)
        int.parse(entry.key as String): (
          background: (entry.value as Map)['background'] as int,
          frames: [for (final value in (entry.value as Map)['frames'] as List)
            base64Decode(value as String)],
          durations: ((entry.value as Map)['durations'] as List).cast<int>(),
        ),
    };
    final result = Gen5SourceRecipeConverter.convert(
      moveId: 'double-edge',
      sourceProgram: (workshop['program'] as Map).cast<String, dynamic>(),
      particles: {
        workshop['particle'] as int: Gen5BatchParticle(
          definition: Uint8List.fromList(utf8.encode(jsonEncode(workshop['definition']))),
          textures: {
            for (final entry in (workshop['textures'] as Map).entries)
              entry.key as String: base64Decode(entry.value as String),
          },
          sourceEmitterIndices: (workshop['sourceEmitterIndices'] as List).cast<int>(),
        ),
      },
      backgrounds: backgrounds,
      backgroundAnimations: animations,
    );
    final recipe = result.bundle.recipe.toJson();
    expect(recipe['requiredCapabilities'], contains('gen5SourceBackgroundAnimation'));
    final binding = ((recipe['program'] as Map)['backgroundAnimationBindings'] as List).single as Map;
    expect(binding['animation'], 2);
    expect(binding['background'], animations[2]!.background);
    expect(binding['durations'], animations[2]!.durations);
    final frames = (binding['frames'] as List).cast<String>();
    expect(frames, hasLength(animations[2]!.frames.length));
    expect(frames.toSet(), hasLength(animations[2]!.frames.map(base64Encode).toSet().length));
    for (var i = 0; i < frames.length; i++) {
      expect(result.bundle.media[frames[i]], animations[2]!.frames[i]);
    }
  });
}
