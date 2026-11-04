import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_recipe_converter.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_audio_matcher.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_particle_approximation.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_script_selection.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_spl_particle_converter.dart';
import 'package:path/path.dart' as p;

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const _release = 'public-2026-11-02-bw2';

Future<Gen5BatchParticle> loadBatchParticle(
  Directory particleRoot, int id, List<int> sourceEmitterIndices,
) async {
  final directory = p.join(particleRoot.path, '$id');
  final bytes = await File(p.join(directory, 'particles.json')).readAsBytes();
  final source = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final rawTextures = source['textures'] as List;
  final mappings = <String, String>{
    for (var index = 0; index < rawTextures.length; index++)
      (rawTextures[index] as Map)['name'] as String: 'p$id-texture$index',
  };
  if (mappings.length != rawTextures.length) {
    throw const FormatException('Duplicate particle texture name');
  }
  final sourceHash = sha256.convert(bytes).toString();
  var normalizedHash = sourceHash;
  final changes = <String>{};
  Gen5SplParticleConversion convert(Uint8List data, String hash, {List<int>? indices}) =>
    Gen5SplParticleConverter.convert(data, particleId: id, sourceRevision: _revision,
      sourcePath: 'res/particles/btlv_effvm_particles/$id/particles.json',
      expectedSha256: hash, textureResourceIds: mappings,
      experimentalSourceEmitterIndices: indices);
  late final Gen5SplParticleConversion converted;
  try {
    converted = convert(bytes, sourceHash);
  } on FormatException {
    Gen5SplParticleConversion? selected;
    try {
      final candidate = convert(bytes, sourceHash, indices: sourceEmitterIndices);
      if (candidate.definition.schemaVersion == 5) selected = candidate;
    } on FormatException {
      selected = null;
    }
    if (selected != null) {
      converted = selected;
      changes.add('selected-source-emitters-v5');
    } else {
      final normalized = Gen5BatchParticleApproximation.normalize(source);
      changes.addAll(normalized.warnings);
      final normalizedBytes = Uint8List.fromList(utf8.encode(jsonEncode(normalized.document)));
      normalizedHash = sha256.convert(normalizedBytes).toString();
      try {
        converted = convert(normalizedBytes, normalizedHash);
      } on FormatException catch (error) {
        if (!error.message.toString().contains('SPL child')) rethrow;
        final withoutChildren = Gen5BatchParticleApproximation.normalize(source, omitChildren: true);
        changes.addAll(withoutChildren.warnings);
        final fallbackBytes = Uint8List.fromList(utf8.encode(jsonEncode(withoutChildren.document)));
        normalizedHash = sha256.convert(fallbackBytes).toString();
        converted = convert(fallbackBytes, normalizedHash);
      }
    }
  }
  final used = converted.definition.textureIds;
  final textures = <String, Uint8List>{};
  for (final entry in mappings.entries.where((item) => used.contains(item.value))) {
    textures[entry.value] = await File(p.join(directory, '${entry.key}.png')).readAsBytes();
  }
  return Gen5BatchParticle(
    definition: Uint8List.fromList(utf8.encode(jsonEncode(converted.definition.toJson()))),
    textures: textures, sourceEmitterIndices: converted.sourceEmitterIndices,
    warnings: changes, sourceSha256: sourceHash, normalizedSha256: normalizedHash,
  );
}

Future<void> main(List<String> args) async {
  if ((args.length != 3 && args.length != 4) || args.any((value) => !p.isAbsolute(value))) {
    throw ArgumentError('Usage: gen5_batch_convert <particle-source-root> <sound-directory> <new-output-directory> [previous-runtime-qualification]');
  }
  final boundedIds = <int>{};
  if (args.length == 4) {
    final report = jsonDecode(await File(args[3]).readAsString()) as Map;
    if (report['schemaVersion'] != 1 || report['scope'] != 'selection-and-static-admission-only') {
      throw const FormatException('Invalid runtime qualification report');
    }
    for (final row in report['moves'] as List) {
      final item = row as Map;
      if ({'fallback:poolExhausted', 'fallback:frameLimit'}.contains(item['runtimeAdmission'])) {
        boundedIds.add(item['id'] as int);
      }
    }
  }
  final particleRoot = Directory(args[0]);
  final soundRoot = Directory(args[1]);
  final output = Directory(args[2]);
  if (!await particleRoot.exists() || !await soundRoot.exists() || await output.exists()) {
    throw StateError('Sources must exist and the output directory must be new');
  }
  await output.create(recursive: true);
  final bundleRoot = await Directory(p.join(output.path, 'bundles')).create();
  final sounds = <String, File>{};
  await for (final entity in soundRoot.list(followLinks: false)) {
    if (entity is File && p.extension(entity.path).toLowerCase() == '.mp3') {
      sounds[p.basename(entity.path)] = entity;
    }
  }
  final client = HttpClient()..maxConnectionsPerHost = 4;
  final rows = <int, Map<String, Object?>>{};
  final particleCache = <String, Future<Gen5BatchParticle>>{};
  var next = 1;
  Future<Gen5BatchParticle> loadParticle(int id, List<int> indices) =>
    particleCache.putIfAbsent('$id:${indices.join(',')}',
      () => loadBatchParticle(particleRoot, id, indices));
  Future<void> worker() async {
    while (next <= 559) {
      final id = next++;
      String? move;
      var stage = 'source';
      try {
        final uri = Uri.https('pokemon-api.yoahn.me', '/v1/snapshots/$_release/gen5-move-script/$id');
        final request = await client.getUrl(uri).timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        final response = await request.close().timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          await response.drain();
          throw FormatException('Source HTTP ${response.statusCode}');
        }
        final builder = BytesBuilder();
        await for (final chunk in response.timeout(const Duration(seconds: 20))) {
          builder.add(chunk);
          if (builder.length > 1024 * 1024) throw const FormatException('Source response too large');
        }
        final document = jsonDecode(utf8.decode(builder.takeBytes())) as Map;
        final source = document['source'] as Map;
        final moveData = document['move'] as Map;
        final scriptData = document['script'] as Map;
        move = moveData['id'] as String;
        final bytes = base64.decode(scriptData['data'] as String);
        if (moveData['sourceId'] != id || source['revision'] != _revision ||
            source['repository'] != 'fuddlesworth/pokebw2' ||
            bytes.length != scriptData['size'] || sha256.convert(bytes).toString() != scriptData['sha256']) {
          throw const FormatException('Source identity or checksum mismatch');
        }
        stage = 'script';
        final selected = Gen5BatchScriptSelection.read(bytes, sourceRevision: _revision,
          sourcePath: scriptData['path'] as String, expectedSha256: scriptData['sha256'] as String);
        final script = selected.script;
        final analysis = Gen5BatchRecipeConverter.analyze(script);
        if (analysis.particles.isEmpty) throw const FormatException('No supported particle placement');
        stage = 'particle';
        final active = analysis.particles.take(5).toList();
        final ids = active.map((part) => part.id).toSet();
        final particles = <int, Gen5BatchParticle>{};
        for (final particleId in ids) {
          final indices = active.where((part) => part.id == particleId)
              .map((part) => part.emitterIndex).toSet().toList()..sort();
          particles[particleId] = await loadParticle(particleId, indices);
        }
        stage = 'audio';
        final match = Gen5BatchAudioMatcher.select(move, sounds.keys);
        final sound = match.fileName == null ? null : await sounds[match.fileName]!.readAsBytes();
        stage = 'recipe';
        final result = Gen5BatchRecipeConverter.convert(moveId: move, sourceMoveId: id,
          script: script, particles: particles, sound: sound, soundMediaType: sound == null ? null : 'audio/mpeg',
          boundedPreview: boundedIds.contains(id));
        final warnings = {...result.warnings, ...selected.warnings, ...match.warnings};
        final documentBytes = utf8.encode(jsonEncode({
          'recipe': base64.encode(result.bundle.recipeBytes),
          'media': {for (final entry in result.bundle.media.entries) entry.key: base64.encode(entry.value)},
        }));
        final file = File(p.join(bundleRoot.path, '$id-$move.json'));
        await file.writeAsBytes(documentBytes, flush: true);
        rows[id] = {'id': id, 'move': move, 'status': 'review',
          'bundle': p.relative(file.path, from: output.path),
          'bundleSha256': sha256.convert(documentBytes).toString(),
          'recipeSha256': result.binding.recipeSha256,
          'sourceScriptSha256': scriptData['sha256'],
          'selectedScriptSha256': script.sha256Hex,
          'selectedVariant': script.variant,
          'particleIds': ids.toList()..sort(),
          'particleSources': [for (final particleId in ids) {
            'id': particleId, 'sourceSha256': particles[particleId]!.sourceSha256,
            'normalizedSha256': particles[particleId]!.normalizedSha256,
            'approximations': particles[particleId]!.warnings.toList()..sort(),
          }],
          'soundFile': match.fileName,
          'warnings': warnings.toList()..sort(), 'apiValidation': 'pending'};
      } on Object catch (error) {
        rows[id] = {'id': id, if (move != null) 'move': move,
          'status': 'blocked', 'stage': stage,
          'reason': error is FormatException ? error.message : error.runtimeType.toString()};
      }
    }
  }
  try {
    await Future.wait(List.generate(4, (_) => worker()));
    if (rows.length != 559) throw StateError('Batch did not produce a result for every source');
    final ordered = [for (var id = 1; id <= 559; id++) rows[id]!];
    final counts = <String, int>{};
    for (final row in ordered) {
      counts.update(row['status'] as String, (v) => v + 1, ifAbsent: () => 1);
    }
    final manifest = {'schemaVersion': 1, 'sourceRevision': _revision,
      'sourceRelease': _release, 'requested': 559, 'counts': counts,
      'audioSource': 'user-provided-bw-clips-name-match-unverified',
      'visualStatus': 'unreviewed', 'apiValidation': 'pending', 'moves': ordered};
    await File(p.join(output.path, 'manifest.json')).writeAsString(jsonEncode(manifest), flush: true);
    stdout.writeln(jsonEncode({'requested': 559, 'counts': counts, 'output': output.path}));
  } finally { client.close(force: true); }
}
