import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class EvaluationCheckpointProvenance {
  EvaluationCheckpointProvenance({
    required String projectTreeHashSha256,
    required String evaluationCodeDigestSha256,
    required String scenarioId,
    required int scenarioVersion,
    required int saveSchemaVersion,
  })  : projectTreeHashSha256 =
            _hash(projectTreeHashSha256, 'projectTreeHashSha256'),
        evaluationCodeDigestSha256 =
            _hash(evaluationCodeDigestSha256, 'evaluationCodeDigestSha256'),
        scenarioId = _nonBlank(scenarioId, 'scenarioId'),
        scenarioVersion = _positive(scenarioVersion, 'scenarioVersion'),
        saveSchemaVersion = _positive(saveSchemaVersion, 'saveSchemaVersion');

  factory EvaluationCheckpointProvenance.fromJson(
    Map<String, Object?> json,
  ) {
    _expectKeys(
      json,
      const <String>{
        'projectTreeHashSha256',
        'evaluationCodeDigestSha256',
        'scenarioId',
        'scenarioVersion',
        'saveSchemaVersion',
      },
    );
    return EvaluationCheckpointProvenance(
      projectTreeHashSha256: _string(
        json['projectTreeHashSha256'],
        'projectTreeHashSha256',
      ),
      evaluationCodeDigestSha256: _string(
        json['evaluationCodeDigestSha256'],
        'evaluationCodeDigestSha256',
      ),
      scenarioId: _string(json['scenarioId'], 'scenarioId'),
      scenarioVersion: _integer(json['scenarioVersion'], 'scenarioVersion'),
      saveSchemaVersion:
          _integer(json['saveSchemaVersion'], 'saveSchemaVersion'),
    );
  }

  final String projectTreeHashSha256;
  final String evaluationCodeDigestSha256;
  final String scenarioId;
  final int scenarioVersion;
  final int saveSchemaVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'projectTreeHashSha256': projectTreeHashSha256,
      'evaluationCodeDigestSha256': evaluationCodeDigestSha256,
      'scenarioId': scenarioId,
      'scenarioVersion': scenarioVersion,
      'saveSchemaVersion': saveSchemaVersion,
    };
  }

  String get canonicalJson => jsonEncode(_canonicalize(toJson()));

  String get digestSha256 {
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  @override
  bool operator ==(Object other) {
    return other is EvaluationCheckpointProvenance &&
        other.canonicalJson == canonicalJson;
  }

  @override
  int get hashCode => canonicalJson.hashCode;
}

final class EvaluationCheckpointCache {
  const EvaluationCheckpointCache({required this.root});

  final Directory root;

  Directory entryDirectory(
    String checkpointId,
    EvaluationCheckpointProvenance provenance,
  ) {
    final id = _checkpointId(checkpointId);
    return Directory(p.join(root.path, provenance.digestSha256, id));
  }

  Future<void> store(
    String checkpointId,
    EvaluationCheckpointProvenance provenance,
    GameState state,
  ) async {
    final id = _checkpointId(checkpointId);
    final entry = entryDirectory(id, provenance);
    await entry.create(recursive: true);
    final saveJson = jsonEncode(_canonicalize(strictGameStateSaveJson(state)));
    final saveDigest = sha256.convert(utf8.encode(saveJson)).toString();
    final saveFile = File(p.join(entry.path, 'save.json'));
    await _writeAtomically(saveFile, saveJson);
    final manifest = <String, Object?>{
      'schemaVersion': 1,
      'checkpointId': id,
      'provenance': provenance.toJson(),
      'provenanceDigestSha256': provenance.digestSha256,
      'saveFile': 'save.json',
      'saveDigestSha256': saveDigest,
    };
    await _writeAtomically(
      File(p.join(entry.path, 'manifest.json')),
      jsonEncode(_canonicalize(manifest)),
    );
  }

  Future<GameState> load(
    String checkpointId,
    EvaluationCheckpointProvenance provenance,
  ) async {
    final id = _checkpointId(checkpointId);
    final entry = entryDirectory(id, provenance);
    if (!await entry.exists()) {
      if (await _checkpointExistsUnderOtherProvenance(id)) {
        throw EvaluationCheckpointStale(
          id,
          'Checkpoint exists but its provenance no longer matches.',
        );
      }
      throw EvaluationCheckpointNotFound(id);
    }

    try {
      final manifestFile = File(p.join(entry.path, 'manifest.json'));
      if (!await manifestFile.exists()) {
        throw const FormatException('manifest.json is missing.');
      }
      final decodedManifest = jsonDecode(await manifestFile.readAsString());
      if (decodedManifest is! Map) {
        throw const FormatException('Manifest root must be an object.');
      }
      final manifest = Map<String, Object?>.from(decodedManifest);
      _expectKeys(
        manifest,
        const <String>{
          'schemaVersion',
          'checkpointId',
          'provenance',
          'provenanceDigestSha256',
          'saveFile',
          'saveDigestSha256',
        },
      );
      if (manifest['schemaVersion'] != 1 ||
          manifest['checkpointId'] != id ||
          manifest['provenanceDigestSha256'] != provenance.digestSha256 ||
          manifest['saveFile'] != 'save.json') {
        throw const FormatException('Manifest metadata does not match.');
      }
      final rawProvenance = manifest['provenance'];
      if (rawProvenance is! Map) {
        throw const FormatException('Manifest provenance is invalid.');
      }
      final storedProvenance = EvaluationCheckpointProvenance.fromJson(
        Map<String, Object?>.from(rawProvenance),
      );
      if (storedProvenance != provenance) {
        throw const FormatException('Manifest provenance is stale.');
      }
      final expectedSaveDigest = manifest['saveDigestSha256'];
      if (expectedSaveDigest is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedSaveDigest)) {
        throw const FormatException('Manifest save digest is invalid.');
      }
      final saveFile = File(p.join(entry.path, 'save.json'));
      if (!await saveFile.exists()) {
        throw const FormatException('save.json is missing.');
      }
      final saveSource = await saveFile.readAsString();
      final actualSaveDigest =
          sha256.convert(utf8.encode(saveSource)).toString();
      if (actualSaveDigest != expectedSaveDigest) {
        throw const FormatException('Checkpoint save digest is stale.');
      }
      final decodedSave = jsonDecode(saveSource);
      if (decodedSave is! Map) {
        throw const FormatException('Checkpoint save must be an object.');
      }
      return gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(decodedSave),
      );
    } on EvaluationCheckpointStale {
      rethrow;
    } on Object catch (failure) {
      throw EvaluationCheckpointStale(id, failure.toString());
    }
  }

  Future<bool> _checkpointExistsUnderOtherProvenance(
    String checkpointId,
  ) async {
    if (!await root.exists()) return false;
    await for (final entity in root.list(followLinks: false)) {
      if (entity is Directory &&
          await Directory(p.join(entity.path, checkpointId)).exists()) {
        return true;
      }
    }
    return false;
  }
}

final class EvaluationCheckpointNotFound implements Exception {
  const EvaluationCheckpointNotFound(this.checkpointId);

  final String checkpointId;

  @override
  String toString() => 'Checkpoint "$checkpointId" was not found.';
}

final class EvaluationCheckpointStale implements Exception {
  const EvaluationCheckpointStale(this.checkpointId, this.reason);

  final String checkpointId;
  final String reason;

  @override
  String toString() => 'Checkpoint "$checkpointId" is stale: $reason';
}

Future<void> _writeAtomically(File destination, String source) async {
  final temporary = File('${destination.path}.tmp');
  await temporary.writeAsString(source, flush: true);
  if (await destination.exists()) await destination.delete();
  await temporary.rename(destination.path);
}

void _expectKeys(Map<String, Object?> json, Set<String> expected) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException('Unexpected checkpoint manifest fields.');
  }
}

String _checkpointId(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'checkpointId',
      'Expected a portable checkpoint id.',
    );
  }
  return value;
}

String _hash(String value, String name) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, name, 'Expected a SHA-256 digest.');
  }
  return value;
}

String _nonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Value must not be blank.');
  }
  return value;
}

int _positive(int value, String name) {
  if (value < 1) {
    throw ArgumentError.value(value, name, 'Value must be positive.');
  }
  return value;
}

String _string(Object? value, String name) {
  if (value is! String) {
    throw FormatException('$name must be a string.');
  }
  return value;
}

int _integer(Object? value, String name) {
  if (value is! int) {
    throw FormatException('$name must be an integer.');
  }
  return value;
}

Object? _canonicalize(Object? value) {
  return switch (value) {
    Map map => <String, Object?>{
        for (final key in map.keys.cast<String>().toList()..sort())
          key: _canonicalize(map[key]),
      },
    List list => list.map(_canonicalize).toList(growable: false),
    Set set => set.map(_canonicalize).toList(growable: false),
    _ => value,
  };
}
