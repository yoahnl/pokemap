import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

final class CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final local = const LocalProjectFileReader();
  final paths = <String>[];
  final probes = <String>[];
  final definitions = <String>[];
  final unitKeys = <String>[];
  void clear() {
    paths.clear();
    probes.clear();
    definitions.clear();
    unitKeys.clear();
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      local.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) {
    probes.add(relativePath);
    return local.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  void _record(String path, List<int> bytes) {
    if (path.startsWith('catalog/objects/')) {
      final json = jsonDecode(utf8.decode(bytes)) as Map;
      if (json['type'] == 'unit') {
        final key = json['key'] as Map;
        unitKeys.add('${key['kind']}:${key['id']}');
        final payload = json['payload'] as Map;
        if (payload['section'] == r'$projectDefinition') {
          final definition = (payload['value'] as Map)['definition'] as Map;
          definitions.add(definition['id'] as String);
        }
      }
    }
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    paths.add(relativePath);
    final bytes = await local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    _record(relativePath, bytes);
    return bytes;
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }
}
