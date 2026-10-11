import 'dart:collection';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

final class _FakeTree implements SourceTreePort {
  _FakeTree(this.nodes, this.chunks);

  final List<SourceNode> nodes;
  final Map<String, List<List<int>>> chunks;
  final Set<SourceNode> issued = HashSet.identity();
  final List<SourceNode> reads = [];
  final List<int> budgets = [];
  void Function(int)? onChunk;
  void Function()? afterRead;
  Object? readError;
  Object? walkError;
  int walks = 0;
  int deliveredChunks = 0;

  @override
  Stream<SourceNode> walk({
    required SourceScanPolicy policy,
    required ScanCancellation cancellation,
  }) async* {
    walks++;
    if (walkError case final error?) throw error;
    for (final description in nodes) {
      cancellation.check();
      final node = SourceNode(
          relativePath: description.relativePath,
          kind: description.kind,
          byteLength: description.byteLength,
          token: description.token);
      issued.add(node);
      yield node;
    }
  }

  @override
  Stream<List<int>> read(
    SourceNode node, {
    required int maxBytes,
    required ScanCancellation cancellation,
  }) async* {
    if (!issued.contains(node)) {
      throw StateError('Read received a reconstructed or foreign node');
    }
    reads.add(node);
    budgets.add(maxBytes);
    if (readError case final error?) throw error;
    final values = chunks[node.relativePath]!;
    for (var i = 0; i < values.length; i++) {
      deliveredChunks++;
      onChunk?.call(i);
      yield values[i];
    }
    afterRead?.call();
  }
}

SourceNode _node(String path, SourceNodeKind kind, int size, {String? token}) =>
    SourceNode(
        relativePath: path,
        kind: kind,
        byteLength: size,
        token: token ?? 'initial:$path');

_FakeTree _tree() => _FakeTree([
      _node('Data', SourceNodeKind.directory, 0),
      _node('Data/Map001.rxdata', SourceNodeKind.file, 3),
    ], {
      'Data/Map001.rxdata': [
        [1],
        [2, 3],
      ],
    });

SourceSnapshot _snapshot(
  _FakeTree tree, {
  SourceScanPolicy? policy,
  SourceScanState state = SourceScanState.complete,
  Map<String, Sha256Hash> hashes = const {},
}) {
  final effective = policy ?? SourceScanPolicy();
  return SourceSnapshot(
      logicalProjectNamespace: ConverterId('snapshot-port-test'),
      policyHash: effective.canonicalHash,
      entries: [
        for (var i = 0; i < tree.nodes.length; i++)
          if (!effective.isExcluded(tree.nodes[i].relativePath))
            SourceFileEntry(
                fileId: ConverterId('fixture:$i'),
                relativePath: tree.nodes[i].relativePath,
                kind: tree.nodes[i].kind,
                byteLength: tree.nodes[i].byteLength,
                sha256: tree.nodes[i].kind == SourceNodeKind.file
                    ? hashes[tree.nodes[i].relativePath] ??
                        Sha256Hash(crypto.sha256
                            .convert(tree.chunks[tree.nodes[i].relativePath]!
                                .expand((chunk) => chunk)
                                .toList())
                            .toString())
                    : null,
                format: tree.nodes[i].kind == SourceNodeKind.file
                    ? 'ruby-marshal'
                    : 'directory',
                family: 'data'),
      ],
      diagnostics: [],
      excludedPaths: [
        for (final node in tree.nodes)
          if (effective.isExcluded(node.relativePath)) node.relativePath,
      ],
      profileEvidence: [],
      state: state);
}

ConverterId _file(SourceSnapshot snapshot) => snapshot.entries
    .singleWhere((entry) => entry.kind == SourceNodeKind.file)
    .fileId;

Matcher _code(String code) =>
    isA<ContractError>().having((error) => error.code, 'code', code);

void main() {
  group('snapshot binding', () {
    test('binds fresh authorized nodes without reading source bytes', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      expect(files, isA<SourceFilePort>());
      expect(tree.walks, 1);
      expect(tree.reads, isEmpty);
      expect(await files.read(_file(snapshot)), [1, 2, 3]);
      expect(tree.issued.contains(tree.reads.single), isTrue);
      expect(tree.reads.single, isNot(same(tree.nodes[1])));
      expect(tree.budgets, [3]);
      expect(tree.walks, 1);
    });

    for (final state in [
      SourceScanState.partial,
      SourceScanState.failed,
      SourceScanState.cancelled
    ]) {
      test('refuses a $state snapshot before walking the source', () async {
        final tree = _tree();
        await expectLater(
            SnapshotSourceFiles.bind(
                source: tree, snapshot: _snapshot(tree, state: state)),
            throwsA(_code('source.snapshot_incomplete')));
        expect(tree.walks, 0);
      });
    }

    test('refuses a different policy hash before walking source', () async {
      final tree = _tree();
      await expectLater(
          SnapshotSourceFiles.bind(
              source: tree,
              snapshot: _snapshot(tree),
              policy: SourceScanPolicy(excludedSegments: [])),
          throwsA(_code('source.policy_mismatch')));
      expect(tree.walks, 0);
    });

    test('refuses cancellation before binding', () async {
      final tree = _tree();
      final cancel = ScanCancellation()..cancel();
      await expectLater(
          SnapshotSourceFiles.bind(
              source: tree, snapshot: _snapshot(tree), cancellation: cancel),
          throwsA(_code('source.cancelled')));
      expect(tree.walks, 0);
    });

    for (final change in ['missing', 'added', 'size', 'kind']) {
      test('refuses $change admitted manifest changes at bind', () async {
        final tree = _tree();
        final snapshot = _snapshot(tree);
        switch (change) {
          case 'missing':
            tree.nodes.removeLast();
          case 'added':
            tree.nodes.add(_node('new.txt', SourceNodeKind.file, 1));
          case 'size':
            tree.nodes[1] = _node('Data/Map001.rxdata', SourceNodeKind.file, 4);
          case 'kind':
            tree.nodes[1] = _node('Data/Map001.rxdata', SourceNodeKind.link, 0);
        }
        await expectLater(
            SnapshotSourceFiles.bind(source: tree, snapshot: snapshot),
            throwsA(_code('source.snapshot_changed')));
        expect(tree.reads, isEmpty);
      });
    }

    test('refuses duplicate source paths even if metadata is identical',
        () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      tree.nodes.add(tree.nodes.last);
      await expectLater(
          SnapshotSourceFiles.bind(source: tree, snapshot: snapshot),
          throwsA(_code('source.duplicate_path')));
    });

    test('refuses malformed fresh paths', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      tree.nodes[1] = _node('../outside', SourceNodeKind.file, 3);
      await expectLater(
          SnapshotSourceFiles.bind(source: tree, snapshot: snapshot),
          throwsA(_code('source.path')));
      expect(tree.reads, isEmpty);
    });

    test('refuses snapshot entry sizes beyond policy before walking', () async {
      final tree = _tree();
      final policy =
          SourceScanPolicy(limits: const SourceScanLimits(maxFileBytes: 2));
      await expectLater(
          SnapshotSourceFiles.bind(
              source: tree,
              snapshot: _snapshot(tree, policy: policy),
              policy: policy),
          throwsA(_code('source.file_limit')));
      expect(tree.walks, 0);
    });

    test('sanitizes unexpected source walk errors', () async {
      final tree = _tree()
        ..walkError = StateError('private absolute source root');
      await expectLater(
          SnapshotSourceFiles.bind(source: tree, snapshot: _snapshot(tree)),
          throwsA(_code('source.walk_failed')));
    });

    test('excludes sensitive nodes and verifies their path presence only',
        () async {
      final tree = _tree();
      tree.nodes.add(_node('.env', SourceNodeKind.file, 1000000000));
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      await files.verifyUnchanged();
      expect(tree.reads, isEmpty);
      expect(await files.read(_file(snapshot)), [1, 2, 3]);
      expect(tree.reads.single.relativePath, 'Data/Map001.rxdata');
    });
  });

  group('snapshot reads', () {
    test('returns only immutable bytes matching the snapshot hash', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      final bytes = await files.read(_file(snapshot));
      tree.chunks['Data/Map001.rxdata']![0][0] = 255;
      expect(bytes, [1, 2, 3]);
      expect(() => bytes[0] = 0, throwsUnsupportedError);
    });

    test('refuses unknown file IDs without reading', () async {
      final tree = _tree();
      final files = await SnapshotSourceFiles.bind(
          source: tree, snapshot: _snapshot(tree));
      await expectLater(files.read(ConverterId('unknown')),
          throwsA(_code('source.file_unknown')));
      expect(tree.reads, isEmpty);
    });

    test('refuses directory IDs without reading', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      final directory = snapshot.entries
          .singleWhere((entry) => entry.kind == SourceNodeKind.directory);
      await expectLater(
          files.read(directory.fileId), throwsA(_code('source.node_not_file')));
      expect(tree.reads, isEmpty);
    });

    test('refuses same-size content with a different SHA256', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      tree.chunks['Data/Map001.rxdata'] = [
        [3, 2, 1]
      ];
      await expectLater(files.read(_file(snapshot)),
          throwsA(_code('source.content_changed')));
    });

    test('refuses content changes made before binding when read', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      tree.chunks['Data/Map001.rxdata'] = [
        [9, 9, 9]
      ];
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      await expectLater(files.read(_file(snapshot)),
          throwsA(_code('source.content_changed')));
    });

    for (final length in [2, 4]) {
      test('refuses actual byte length $length versus manifest size 3',
          () async {
        final tree = _tree();
        final snapshot = _snapshot(tree);
        final files =
            await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
        tree.chunks['Data/Map001.rxdata'] = [List.filled(length, 1)];
        await expectLater(
            files.read(_file(snapshot)), throwsA(_code('source.changed')));
      });
    }

    for (final byte in [-1, 256]) {
      test('refuses invalid byte $byte without wrapping its value', () async {
        final tree = _tree();
        final snapshot = _snapshot(tree);
        final files =
            await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
        tree.chunks['Data/Map001.rxdata'] = [
          [1, byte, 3]
        ];
        await expectLater(
            files.read(_file(snapshot)), throwsA(_code('source.invalid_byte')));
      });
    }

    test('refuses cancellation while a read is active', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final cancel = ScanCancellation();
      final files = await SnapshotSourceFiles.bind(
          source: tree, snapshot: snapshot, cancellation: cancel);
      tree.onChunk = (index) {
        if (index == 1) cancel.cancel();
      };
      await expectLater(
          files.read(_file(snapshot)), throwsA(_code('source.cancelled')));
      expect(tree.deliveredChunks, 2);
    });

    test('refuses cancellation after the last chunk before returning bytes',
        () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final cancel = ScanCancellation();
      final files = await SnapshotSourceFiles.bind(
          source: tree, snapshot: snapshot, cancellation: cancel);
      tree.afterRead = cancel.cancel;
      await expectLater(
          files.read(_file(snapshot)), throwsA(_code('source.cancelled')));
    });

    test('bounds empty chunks that provide no progress during a read',
        () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      tree.chunks['Data/Map001.rxdata'] = List.generate(2000, (_) => []);
      await expectLater(files.read(_file(snapshot)),
          throwsA(_code('source.empty_chunk_limit')));
      expect(tree.deliveredChunks, 1025);
    });

    test('propagates safe drift errors from the native source contract',
        () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      tree.readError =
          ContractError('source.changed', 'Data/Map001.rxdata', 'Changed');
      await expectLater(
          files.read(_file(snapshot)), throwsA(_code('source.changed')));
    });

    test('sanitizes unexpected source read errors', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      tree.readError = StateError('private absolute source root');
      await expectLater(
          files.read(_file(snapshot)), throwsA(_code('source.read_failed')));
    });

    test('bounds cumulative read reservations including repeated reads',
        () async {
      final tree = _tree();
      final policy =
          SourceScanPolicy(limits: const SourceScanLimits(maxTotalBytes: 6));
      final snapshot = _snapshot(tree, policy: policy);
      final files = await SnapshotSourceFiles.bind(
          source: tree, snapshot: snapshot, policy: policy);
      await files.read(_file(snapshot));
      await files.read(_file(snapshot));
      await expectLater(files.read(_file(snapshot)),
          throwsA(_code('source.read_byte_limit')));
      expect(tree.reads, hasLength(2));
    });

    test('bounds read attempts even for empty files', () async {
      final tree =
          _FakeTree([_node('empty', SourceNodeKind.file, 0)], {'empty': []});
      final policy =
          SourceScanPolicy(limits: const SourceScanLimits(maxEntries: 1));
      final snapshot = _snapshot(tree, policy: policy);
      final files = await SnapshotSourceFiles.bind(
          source: tree, snapshot: snapshot, policy: policy);
      expect(await files.read(_file(snapshot)), isEmpty);
      await expectLater(files.read(_file(snapshot)),
          throwsA(_code('source.read_count_limit')));
      expect(tree.budgets, [0]);
    });
  });

  group('whole-batch freshness', () {
    test('verifies manifest without rebuilding cached read nodes', () async {
      final tree = _tree();
      final snapshot = _snapshot(tree);
      final files =
          await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
      await files.verifyUnchanged();
      await files.read(_file(snapshot));
      final original = tree.reads.single;
      await files.verifyUnchanged();
      await files.read(_file(snapshot));
      expect(tree.reads[1], same(original));
      expect(tree.walks, 3);
    });

    for (final change in ['added', 'missing', 'token', 'excluded']) {
      test('refuses $change tree drift at a batch freshness gate', () async {
        final tree = _tree();
        final snapshot = _snapshot(tree);
        final files =
            await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
        switch (change) {
          case 'added':
            tree.nodes.add(_node('extra', SourceNodeKind.file, 0));
          case 'missing':
            tree.nodes.removeLast();
          case 'token':
            tree.nodes[1] = _node('Data/Map001.rxdata', SourceNodeKind.file, 3,
                token: 'changed');
          case 'excluded':
            tree.nodes.add(_node('.env', SourceNodeKind.file, 0));
        }
        await expectLater(
            files.verifyUnchanged(), throwsA(_code('source.snapshot_changed')));
        expect(tree.reads, isEmpty);
      });
    }
  });

  if (Platform.isMacOS) {
    group('macOS snapshot integration', () {
      late Directory root;
      late MacOsSourceTree tree;

      setUp(() async {
        root = await Directory('/private/tmp')
            .createTemp('avelune_snapshot_files_');
        final ownedRoot = root;
        addTearDown(() => ownedRoot.delete(recursive: true));
        await Directory('${root.path}/Data').create();
        await File('${root.path}/Data/Map001.rxdata')
            .writeAsBytes([4, 8, 0x30]);
        tree = await MacOsSourceTree.open(root.path);
        final ownedTree = tree;
        addTearDown(ownedTree.close);
      });

      Future<SourceSnapshot> scan() => SourceScanner().scan(
          source: tree,
          logicalProjectNamespace: ConverterId('native-snapshot-test'));

      test(
          'reads through original authorized native nodes and keeps caller ownership',
          () async {
        final snapshot = await scan();
        final files =
            await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
        await files.verifyUnchanged();
        expect(await files.read(_file(snapshot)), [4, 8, 0x30]);
        await files.verifyUnchanged();
        expect(
            await tree
                .walk(
                    policy: SourceScanPolicy(),
                    cancellation: ScanCancellation())
                .toList(),
            hasLength(2));
      });

      test('rejects a same-size file replacement after binding', () async {
        final snapshot = await scan();
        final files =
            await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
        final original = File('${root.path}/Data/Map001.rxdata');
        await original.rename('${root.path}/Data/old.rxdata');
        await File(original.path).writeAsBytes([4, 8, 0x30]);
        await expectLater(
            files.read(_file(snapshot)), throwsA(_code('source.changed')));
        await expectLater(
            files.verifyUnchanged(), throwsA(_code('source.snapshot_changed')));
      });

      test(
          'rejects replacement by an external symlink without reading its bytes',
          () async {
        final snapshot = await scan();
        final files =
            await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
        final original = File('${root.path}/Data/Map001.rxdata');
        await original.delete();
        await Link(original.path).create('/etc/passwd');
        await expectLater(
            files.read(_file(snapshot)), throwsA(_code('source.changed')));
      });
    });
  }
}
