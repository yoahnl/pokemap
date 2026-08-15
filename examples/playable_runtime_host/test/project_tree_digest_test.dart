import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/project_tree_digest.dart';
import 'package:path/path.dart' as p;

void main() {
  test('hashes project files deterministically regardless of creation order',
      () async {
    final first = await Directory.systemTemp.createTemp('tree_digest_a_');
    final second = await Directory.systemTemp.createTemp('tree_digest_b_');
    addTearDown(() => first.delete(recursive: true));
    addTearDown(() => second.delete(recursive: true));
    await _write(first, 'project.json', '{}');
    await _write(first, 'maps/map.json', '{"id":"map"}');
    await _write(second, 'maps/map.json', '{"id":"map"}');
    await _write(second, 'project.json', '{}');

    expect(
      await const ProjectTreeDigest().compute(first),
      await const ProjectTreeDigest().compute(second),
    );
  });

  test(
      'changes when a required manifest, map, dialogue, catalog or asset changes',
      () async {
    final root = await Directory.systemTemp.createTemp('tree_digest_change_');
    addTearDown(() => root.delete(recursive: true));
    await _write(root, 'project.json', '{}');
    await _write(root, 'maps/map.json', '{}');
    await _write(root, 'dialogues/main.yarn', 'Hello');
    await _write(root, 'data/pokemon/catalogs/items.json', '{}');
    await _write(root, 'assets/sprite.bin', 'sprite');
    final before = await const ProjectTreeDigest().compute(root);

    await _write(root, 'assets/sprite.bin', 'changed');

    expect(await const ProjectTreeDigest().compute(root), isNot(before));
  });

  test('excludes saves, build output, tool caches and transient lock files',
      () async {
    final root = await Directory.systemTemp.createTemp('tree_digest_exclude_');
    addTearDown(() => root.delete(recursive: true));
    await _write(root, 'project.json', '{}');
    final before = await const ProjectTreeDigest().compute(root);
    await _write(root, 'build/output.bin', 'ignored');
    await _write(root, 'saves/save.json', 'ignored');
    await _write(root, '.dart_tool/cache.bin', 'ignored');
    await _write(root, '.pokemap/workspace.json', 'ignored');
    await _write(root, '.pokemap-project-local.lock', 'ignored');

    expect(await const ProjectTreeDigest().compute(root), before);
  });
}

Future<void> _write(Directory root, String relativePath, String content) async {
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
