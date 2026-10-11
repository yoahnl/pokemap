import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  if (!Platform.isMacOS) {
    test('rejects source access on unsupported platforms', () async {
      await expectLater(
          MacOsSourceTree.open('.'),
          throwsA(isA<ContractError>().having(
              (error) => error.code, 'code', 'source.platform_unsupported')));
    });
    return;
  }

  late Directory root;
  late MacOsSourceTree tree;

  setUp(() async {
    root = await Directory('/private/tmp').createTemp('avelune_source_test_');
    final ownedRoot = root;
    addTearDown(() => ownedRoot.delete(recursive: true));
    tree = await MacOsSourceTree.open(root.path);
    final ownedTree = tree;
    addTearDown(ownedTree.close);
  });

  Future<List<SourceNode>> nodes({SourceScanPolicy? policy}) => tree
      .walk(
        policy: policy ?? SourceScanPolicy(),
        cancellation: ScanCancellation(),
      )
      .toList();

  Future<List<int>> bytes(SourceNode node, {int maxBytes = 1 << 20}) async => [
        for (final chunk in await tree
            .read(node, maxBytes: maxBytes, cancellation: ScanCancellation())
            .toList())
          ...chunk
      ];

  Matcher code(String value) =>
      isA<ContractError>().having((error) => error.code, 'code', value);

  test('enumerates nested source files and reads their exact bytes', () async {
    await Directory('${root.path}/Data').create();
    await File('${root.path}/Data/Map001.rxdata').writeAsBytes([0, 1, 2, 255]);
    await File('${root.path}/README.txt').writeAsString('sample');
    final entries = await nodes();
    expect(entries.map((node) => node.relativePath).toSet(),
        {'Data', 'Data/Map001.rxdata', 'README.txt'});
    final node =
        entries.singleWhere((node) => node.relativePath.endsWith('rxdata'));
    expect(node.kind, SourceNodeKind.file);
    expect(node.byteLength, 4);
    expect(await bytes(node), [0, 1, 2, 255]);
    expect(tree.rootPath, await root.resolveSymbolicLinks());
  });

  test('does not follow a file or directory symlink outside the source',
      () async {
    final outside =
        await Directory('/private/tmp').createTemp('avelune_outside_');
    addTearDown(() => outside.delete(recursive: true));
    await File('${outside.path}/secret').writeAsString('outside');
    await Link('${root.path}/linked-file').create('${outside.path}/secret');
    await Link('${root.path}/linked-dir').create(outside.path);
    final entries = await nodes();
    expect(entries, hasLength(2));
    expect(entries.every((node) => node.kind == SourceNodeKind.link), isTrue);
    for (final node in entries) {
      await expectLater(bytes(node), throwsA(code('source.node_not_file')));
    }
  });

  test('excludes a sensitive directory before listing its descendants',
      () async {
    await Directory('${root.path}/.git').create();
    await File('${root.path}/.git/secret').writeAsString('private');
    await File('${root.path}/safe').writeAsString('safe');
    final entries = await nodes();
    expect(entries.map((node) => node.relativePath).toSet(), {'.git', 'safe'});
    await expectLater(
        bytes(entries.singleWhere((node) => node.relativePath == '.git')),
        throwsA(isA<ContractError>()));
  });

  test('excluded files cannot be read through their emitted node', () async {
    await File('${root.path}/.env').writeAsString('secret');
    final node = (await nodes()).single;
    await expectLater(bytes(node), throwsA(code('source.excluded')));
  });

  test('rejects excluded node replay into a fresh instance of the same root',
      () async {
    await File('${root.path}/.env').writeAsString('secret');
    final excluded = (await nodes()).single;
    final other = await MacOsSourceTree.open(root.path);
    addTearDown(other.close);
    await expectLater(
        other
            .read(excluded, maxBytes: 100, cancellation: ScanCancellation())
            .toList(),
        throwsA(code('source.node_unissued')));
  });

  test('rejects same-root foreign nodes before and after its own walk',
      () async {
    await File('${root.path}/source').writeAsString('sample');
    final foreign = (await nodes()).single;
    final other = await MacOsSourceTree.open(root.path);
    addTearDown(other.close);
    Future<List<List<int>>> replay() => other
        .read(foreign, maxBytes: 100, cancellation: ScanCancellation())
        .toList();
    await expectLater(replay(), throwsA(code('source.node_unissued')));
    final own = (await other
            .walk(policy: SourceScanPolicy(), cancellation: ScanCancellation())
            .toList())
        .single;
    await expectLater(replay(), throwsA(code('source.node_unissued')));
    expect(
        (await other
                .read(own, maxBytes: 100, cancellation: ScanCancellation())
                .toList())
            .expand((chunk) => chunk),
        'sample'.codeUnits);
  });

  test('rejects a reconstructed node even with the exact emitted token',
      () async {
    await File('${root.path}/source').writeAsString('sample');
    final original = (await nodes()).single;
    final copy = SourceNode(
        relativePath: original.relativePath,
        kind: original.kind,
        byteLength: original.byteLength,
        token: original.token);
    await expectLater(bytes(copy), throwsA(code('source.node_unissued')));
    expect(await bytes(original), 'sample'.codeUnits);
  });

  test('rejects a file replaced after its inventory token was emitted',
      () async {
    final file = await File('${root.path}/source').writeAsString('original');
    final node = (await nodes()).single;
    await file.rename('${root.path}/old');
    await File(file.path).writeAsString('substitute');
    await expectLater(bytes(node), throwsA(code('source.changed')));
  });

  test('rejects a parent directory replaced with an outside symlink', () async {
    final directory = await Directory('${root.path}/Data').create();
    await File('${directory.path}/source').writeAsString('original');
    final node =
        (await nodes()).singleWhere((node) => node.kind == SourceNodeKind.file);
    final outside =
        await Directory('/private/tmp').createTemp('avelune_outside_');
    addTearDown(() => outside.delete(recursive: true));
    await File('${outside.path}/source').writeAsString('outside');
    await directory.rename('${root.path}/old');
    await Link(directory.path).create(outside.path);
    await expectLater(bytes(node), throwsA(isA<ContractError>()));
  });

  test('rejects forged traversal paths before resolving any component',
      () async {
    for (final path in [
      '../secret',
      '/private/tmp/secret',
      'Data/../secret',
      'a//b',
      'a\u0000b'
    ]) {
      final node = SourceNode(
          relativePath: path,
          kind: SourceNodeKind.file,
          byteLength: 1,
          token: 'forged');
      await expectLater(bytes(node), throwsA(isA<ContractError>()));
    }
  });

  test('rejects forged and foreign tokens before emitting any source bytes',
      () async {
    await File('${root.path}/source').writeAsString('original');
    final original = (await nodes()).single;
    final forged = SourceNode(
      relativePath: original.relativePath,
      kind: original.kind,
      byteLength: original.byteLength,
      token: 'forged',
    );
    await expectLater(bytes(forged), throwsA(code('source.node_unissued')));
    final outside =
        await Directory('/private/tmp').createTemp('avelune_foreign_');
    addTearDown(() => outside.delete(recursive: true));
    await File('${outside.path}/source').writeAsString('original');
    final other = await MacOsSourceTree.open(outside.path);
    addTearDown(other.close);
    final foreign = (await other
            .walk(policy: SourceScanPolicy(), cancellation: ScanCancellation())
            .toList())
        .single;
    await expectLater(bytes(foreign), throwsA(code('source.node_unissued')));
    final forgedLength = SourceNode(
        relativePath: original.relativePath,
        kind: original.kind,
        byteLength: 1,
        token: original.token);
    await expectLater(
        bytes(forgedLength), throwsA(code('source.node_unissued')));
  });

  test('rejects a file swapped to a link before reading', () async {
    final file = await File('${root.path}/source').writeAsString('original');
    final node = (await nodes()).single;
    await file.delete();
    await Link(file.path).create('/etc/passwd');
    await expectLater(bytes(node), throwsA(code('source.changed')));
  });

  test('binds the inventory token to its relative path for hardlinked files',
      () async {
    await File('${root.path}/original').writeAsString('sample');
    final linked = await Process.run(
        '/bin/ln', ['${root.path}/original', '${root.path}/alias']);
    expect(linked.exitCode, 0, reason: '${linked.stderr}');
    final entries = await nodes();
    final original =
        entries.singleWhere((node) => node.relativePath == 'original');
    final forged = SourceNode(
        relativePath: 'alias',
        kind: original.kind,
        byteLength: original.byteLength,
        token: original.token);
    await expectLater(bytes(forged), throwsA(code('source.node_unissued')));
    expect(
        await bytes(
            entries.singleWhere((node) => node.relativePath == 'alias')),
        'sample'.codeUnits);
  });

  test('checks cancellation before enumerating or reading', () async {
    await File('${root.path}/source').writeAsString('original');
    final node = (await nodes()).single;
    final cancellation = ScanCancellation()..cancel();
    await expectLater(
        tree
            .walk(policy: SourceScanPolicy(), cancellation: cancellation)
            .toList(),
        throwsA(code('source.cancelled')));
    await expectLater(
        tree.read(node, maxBytes: 100, cancellation: cancellation).toList(),
        throwsA(code('source.cancelled')));
  });

  test('checks file and entry quotas while walking', () async {
    await File('${root.path}/source').writeAsBytes(List.filled(20, 1));
    await expectLater(
        nodes(
            policy: SourceScanPolicy(
                limits: const SourceScanLimits(maxFileBytes: 10))),
        throwsA(code('source.file_limit')));
    await File('${root.path}/second').writeAsString('second');
    await expectLater(
        nodes(
            policy: SourceScanPolicy(
                limits: const SourceScanLimits(maxEntries: 1))),
        throwsA(code('source.entry_limit')));
  });

  test('checks depth before opening a descendant directory', () async {
    await Directory('${root.path}/one/two').create(recursive: true);
    await File('${root.path}/one/two/source').writeAsString('source');
    await expectLater(
        nodes(
            policy:
                SourceScanPolicy(limits: const SourceScanLimits(maxDepth: 1))),
        throwsA(code('source.depth_limit')));
  });

  test('bounded chunks permit cancellation between reads', () async {
    await File('${root.path}/source').writeAsBytes(List.filled(150000, 7));
    final node = (await nodes()).single;
    final cancellation = ScanCancellation();
    final chunks = <List<int>>[];
    await expectLater(
        tree
            .read(node, maxBytes: 200000, cancellation: cancellation)
            .map((chunk) {
          chunks.add(chunk);
          cancellation.cancel();
          return chunk;
        }).drain<void>(),
        throwsA(code('source.cancelled')));
    expect(chunks, hasLength(1));
    expect(chunks.single.length, lessThanOrEqualTo(65536));
  });

  test('rejects a read beyond its declared maximum without returning bytes',
      () async {
    await File('${root.path}/source').writeAsBytes(List.filled(20, 7));
    final node = (await nodes()).single;
    await expectLater(
        bytes(node, maxBytes: 10), throwsA(code('source.file_limit')));
  });

  test('detects file mutation between chunks before completing the stream',
      () async {
    final file =
        await File('${root.path}/source').writeAsBytes(List.filled(150000, 7));
    final node = (await nodes()).single;
    var changed = false;
    await expectLater(
        tree
            .read(node, maxBytes: 200000, cancellation: ScanCancellation())
            .asyncMap((chunk) async {
          if (!changed) {
            changed = true;
            await file.writeAsBytes(List.filled(150000, 8));
          }
          return chunk;
        }).drain<void>(),
        throwsA(code('source.changed')));
  });

  test('classifies a FIFO without opening it for reading', () async {
    final result = await Process.run('/usr/bin/mkfifo', ['${root.path}/fifo']);
    expect(result.exitCode, 0);
    final node = (await nodes()).single;
    expect(node.kind, SourceNodeKind.special);
    await expectLater(bytes(node), throwsA(code('source.node_not_file')));
  });

  test('a closed tree rejects new work and close is idempotent', () async {
    await tree.close();
    await tree.close();
    await expectLater(nodes(), throwsA(code('source.closed')));
  });

  test('root descriptor remains anchored when its visible path is replaced',
      () async {
    await File('${root.path}/source').writeAsString('original');
    final node = (await nodes()).single;
    final oldPath = root.path;
    final moved = await root.rename('${root.path}_moved');
    addTearDown(() => moved.delete(recursive: true));
    root = await Directory(oldPath).create();
    await File('${root.path}/source').writeAsString('outside replacement');
    expect(String.fromCharCodes(await bytes(node)), 'original');
  });

  test('checks total bytes and path length quotas', () async {
    await File('${root.path}/first').writeAsString('123456');
    await File('${root.path}/second').writeAsString('123456');
    await expectLater(
        nodes(
            policy: SourceScanPolicy(
                limits: const SourceScanLimits(maxTotalBytes: 10))),
        throwsA(code('source.total_bytes_limit')));
    await expectLater(
        nodes(
            policy: SourceScanPolicy(
                limits: const SourceScanLimits(maxPathCodeUnits: 3))),
        throwsA(isA<ContractError>()));
  });

  test('checks the total path budget before opening descendants', () async {
    await Directory('${root.path}/parent').create();
    await File('${root.path}/parent/child').writeAsString('sample');
    await expectLater(
        nodes(
            policy: SourceScanPolicy(
                limits: const SourceScanLimits(maxTotalPathCodeUnits: 10))),
        throwsA(code('source.total_path_limit')));
  });

  test('explicitly canonicalizes a selected root symlink', () async {
    await File('${root.path}/source').writeAsString('sample');
    final parent =
        await Directory('/private/tmp').createTemp('avelune_root_link_');
    addTearDown(() => parent.delete(recursive: true));
    final link = await Link('${parent.path}/selected').create(root.path);
    final linked = await MacOsSourceTree.open(link.path);
    addTearDown(linked.close);
    expect(linked.rootPath, await root.resolveSymbolicLinks());
    final node = (await linked
            .walk(policy: SourceScanPolicy(), cancellation: ScanCancellation())
            .toList())
        .single;
    expect(
        (await linked
                .read(node, maxBytes: 6, cancellation: ScanCancellation())
                .toList())
            .expand((chunk) => chunk),
        'sample'.codeUnits);
  });

  test('macOS SDK validates native stat and dirent layouts and open flags',
      () async {
    final source = File('${root.path}/layout.c');
    await source.writeAsString(r'''
#include <sys/stat.h>
#include <dirent.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
int main(void) {
  printf("%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%x,%x,%x,%x,%x", sizeof(struct stat), offsetof(struct stat, st_dev), offsetof(struct stat, st_mode), offsetof(struct stat, st_nlink), offsetof(struct stat, st_ino), offsetof(struct stat, st_mtimespec), offsetof(struct stat, st_mtimespec.tv_nsec), offsetof(struct stat, st_ctimespec), offsetof(struct stat, st_ctimespec.tv_nsec), offsetof(struct stat, st_birthtimespec), offsetof(struct stat, st_birthtimespec.tv_nsec), offsetof(struct stat, st_size), offsetof(struct stat, st_gen), sizeof(struct dirent), offsetof(struct dirent, d_name), offsetof(struct dirent, d_namlen), offsetof(struct dirent, d_reclen), offsetof(struct dirent, d_type), sizeof(ino_t), O_NOFOLLOW, O_DIRECTORY, O_CLOEXEC, O_NONBLOCK, AT_SYMLINK_NOFOLLOW);
  return 0;
}
''');
    final executable = '${root.path}/layout';
    final compiled = await Process.run('/usr/bin/xcrun',
        ['clang', '-Wall', '-Werror', source.path, '-o', executable]);
    expect(compiled.exitCode, 0, reason: '${compiled.stderr}');
    final result = await Process.run(executable, []);
    expect(result.exitCode, 0);
    expect(result.stdout,
        '144,0,4,6,8,48,56,64,72,80,88,96,120,1048,21,18,16,20,8,100,100000,1000000,4,20');
  });
}
