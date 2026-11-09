import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_audio_matcher.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_recipe_converter.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_source_recipe_converter.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

Object? renameTextures(Object? value, Map<String, String> names) {
  if (value is String) return names[value] ?? value;
  if (value is List) {
    return [for (final item in value) renameTextures(item, names)];
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key: renameTextures(entry.value, names)
    };
  }
  return value;
}

Gen5BatchParticle readParticle(int id, Map group) {
  final encoded = (group['textures'] as Map).cast<String, String>();
  final hashes = (group['textureSha256'] as Map).cast<String, String>();
  if (encoded.length != hashes.length ||
      !hashes.keys.toSet().containsAll(encoded.keys)) {
    throw const FormatException('Texture inventory mismatch');
  }
  final names = {for (final key in encoded.keys) key: 'p$id-$key'};
  final textures = <String, Uint8List>{};
  for (final entry in encoded.entries) {
    final bytes = base64Decode(entry.value);
    if (sha256.convert(bytes).toString() != hashes[entry.key]) {
      throw const FormatException('Texture checksum mismatch');
    }
    textures[names[entry.key]!] = bytes;
  }
  final definition = renameTextures(group['definition'], names);
  return Gen5BatchParticle(
    definition: Uint8List.fromList(utf8.encode(jsonEncode(definition))),
    textures: textures,
    sourceEmitterIndices: (group['sourceEmitterIndices'] as List).cast<int>(),
  );
}

Future<void> main(List<String> args) async {
  if ((args.length != 3 && args.length != 4) ||
      args.any((value) => !p.isAbsolute(value))) {
    throw ArgumentError(
        'Usage: gen5_workshop_recipe_batch <workshop-batch> <sounds> <new-output> [move-list.json]');
  }
  final input = Directory(args[0]);
  final sounds = Directory(args[1]);
  final output = Directory(args[2]);
  if (!await input.exists() ||
      !await sounds.exists() ||
      await output.exists()) {
    throw StateError('Input directories must exist and output must be new');
  }
  final index =
      jsonDecode(await File(p.join(input.path, 'index.json')).readAsString())
          as List;
  final selected = <String, Map>{};
  for (final raw in index) {
    final row = raw as Map;
    final id = row['id'];
    final asset = row['bundleAsset'];
    if (id is! String ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$').hasMatch(id) ||
        asset is! String) {
      throw const FormatException('Invalid workshop index');
    }
    if (!selected.containsKey(id) || p.basename(asset) == '$id.json') {
      selected[id] = row;
    }
  }
  final moves = args.length == 4
      ? (jsonDecode(await File(args[3]).readAsString()) as List).cast<String>()
      : selected.keys.toList();
  if (moves.toSet().length != moves.length ||
      moves.any((id) => !RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$').hasMatch(id))) {
    throw const FormatException('Invalid move list');
  }
  final soundFiles = <String, File>{};
  await for (final item in sounds.list(followLinks: false)) {
    if (item is File && p.extension(item.path).toLowerCase() == '.mp3') {
      soundFiles[p.basename(item.path)] = item;
    }
  }
  await output.create();
  final bindings = await Directory(p.join(output.path, 'bindings')).create();
  final blobs = await Directory(p.join(output.path, 'blobs')).create();
  final completed = <Map<String, Object?>>[];
  final failures = <Map<String, String>>[];
  for (final move in moves) {
    try {
      final entry = selected[move];
      final file = File(p.join(
          input.path,
          entry == null
              ? '$move.json'
              : p.basename(entry['bundleAsset'] as String)));
      if (!await file.exists()) {
        throw const FormatException('Move absent from workshop');
      }
      final data = jsonDecode(await file.readAsString()) as Map;
      if (data['id'] != move) {
        throw const FormatException('Workshop identity mismatch');
      }
      final particles = <int, Gen5BatchParticle>{};
      final groups = data['particleGroups'];
      if (groups is Map && groups.isNotEmpty) {
        for (final entry in groups.entries) {
          final id = int.parse(entry.key as String);
          particles[id] = readParticle(id, entry.value as Map);
        }
      } else if (data['particle'] is int && data['definition'] is Map) {
        final id = data['particle'] as int;
        particles[id] = readParticle(id, data);
      }
      final backgrounds = <int, Uint8List>{
        for (final entry in (data['backgrounds'] as Map? ?? const {}).entries)
          int.parse(entry.key as String): base64Decode(entry.value as String),
      };
      final animations = <int,
          ({int background, List<Uint8List> frames, List<int> durations})>{
        for (final entry
            in (data['backgroundAnimations'] as Map? ?? const {}).entries)
          int.parse(entry.key as String): (
            background: (entry.value as Map)['background'] as int,
            frames: [
              for (final frame in (entry.value as Map)['frames'] as List)
                base64Decode(frame as String)
            ],
            durations: ((entry.value as Map)['durations'] as List).cast<int>(),
          ),
      };
      final soundMatch = Gen5BatchAudioMatcher.select(move, soundFiles.keys);
      var soundFile = soundMatch.fileName;
      if (soundFile == null && move == 'present') {
        final variant = (data['program'] as Map)['variant'];
        final name = variant == 'Present'
            ? 'Present damage.mp3'
            : variant == 'Present_Variant1'
                ? 'Present heal.mp3'
                : null;
        if (name != null && soundFiles.containsKey(name)) soundFile = name;
      }
      final sound =
          soundFile == null ? null : await soundFiles[soundFile]!.readAsBytes();
      final result = Gen5SourceRecipeConverter.convert(
        moveId: move,
        sourceProgram: (data['program'] as Map).cast<String, dynamic>(),
        particles: particles,
        backgrounds: backgrounds,
        backgroundAnimations: animations,
        sound: sound,
        soundMediaType: sound == null ? null : 'audio/mpeg',
      );
      final digest = sha256.convert(utf8.encode(move)).toString();
      final folder = await Directory(p.join(blobs.path, digest)).create();
      await File(p.join(folder.path, '${result.binding.recipeSha256}.json'))
          .writeAsBytes(result.bundle.recipeBytes);
      for (final resource in result.bundle.recipe.resources) {
        final extension = switch (resource.mediaType) {
          'image/png' => 'png',
          'audio/mpeg' => 'mp3',
          'application/vnd.avelune.particle+json' => 'json',
          _ => throw const FormatException('Unsupported resource type'),
        };
        await File(p.join(folder.path, '${resource.sha256Hex}.$extension'))
            .writeAsBytes(result.bundle.media[resource.id]!);
      }
      final binding = BattleRecipeProjectBinding(
          binding: result.binding,
          catalogMoveId: move,
          recipeMediaId: result.binding.recipeId);
      await File(p.join(bindings.path, '$digest.json'))
          .writeAsString(jsonEncode(binding.toJson()));
      completed.add({
        'move': move,
        'sound': soundFile,
        'warnings': {
          ...result.warnings,
          ...soundMatch.warnings,
          ...(data['approximations'] as List? ?? const []).cast<String>()
        }.toList()
          ..sort()
      });
    } on Object catch (error) {
      failures.add({'move': move, 'error': error.toString()});
    }
  }
  final report = {
    'requested': moves.length,
    'converted': completed.length,
    'successes': completed,
    'failures': failures
  };
  await File(p.join(output.path, 'manifest.json'))
      .writeAsString(jsonEncode(report));
  stdout.writeln(jsonEncode({
    'requested': moves.length,
    'converted': completed.length,
    'failures': failures
  }));
  if (failures.isNotEmpty) exitCode = 1;
}
