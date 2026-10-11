import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

final class FakeSourceTree implements SourceTreePort {
  FakeSourceTree({
    required this.nodes,
    required this.chunks,
    this.secondWalk,
    this.forbiddenReads = const {},
    this.onChunk,
  });

  factory FakeSourceTree.text(
    Map<String, String> files, {
    List<SourceNode> extraNodes = const [],
    bool reverse = false,
    Set<String> forbiddenReads = const {},
  }) {
    final chunks = {
      for (final entry in files.entries) entry.key: [utf8.encode(entry.value)],
    };
    final nodes = [
      ...extraNodes,
      for (final entry in files.entries)
        fileNode(entry.key, utf8.encode(entry.value).length),
    ];
    return FakeSourceTree(
      nodes: reverse ? nodes.reversed.toList() : nodes,
      chunks: chunks,
      forbiddenReads: forbiddenReads,
    );
  }

  final List<SourceNode> nodes;
  final Map<String, List<List<int>>> chunks;
  final List<SourceNode>? secondWalk;
  final Set<String> forbiddenReads;
  final void Function(String path, int chunkIndex)? onChunk;
  final List<String> readCalls = [];
  final Map<String, int> readBudgets = {};
  int walkCalls = 0;
  int chunksDelivered = 0;

  @override
  Stream<SourceNode> walk({
    required SourceScanPolicy policy,
    required ScanCancellation cancellation,
  }) async* {
    walkCalls++;
    final current = walkCalls == 1 ? nodes : secondWalk ?? nodes;
    for (final node in current) {
      cancellation.check();
      yield node;
    }
  }

  @override
  Stream<List<int>> read(
    SourceNode node, {
    required int maxBytes,
    required ScanCancellation cancellation,
  }) async* {
    readCalls.add(node.relativePath);
    readBudgets[node.relativePath] = maxBytes;
    if (forbiddenReads.contains(node.relativePath)) {
      throw StateError('Sensitive or unsupported entry was read');
    }
    final content = chunks[node.relativePath];
    if (content == null) {
      throw StateError('No readable content for ${node.relativePath}');
    }
    for (var i = 0; i < content.length; i++) {
      cancellation.check();
      chunksDelivered++;
      onChunk?.call(node.relativePath, i);
      yield content[i];
    }
  }
}

SourceNode fileNode(String path, int bytes, {String? token}) => SourceNode(
      relativePath: path,
      kind: SourceNodeKind.file,
      byteLength: bytes,
      token: token ?? 'file:$path:$bytes',
    );

SourceNode directoryNode(String path) => SourceNode(
      relativePath: path,
      kind: SourceNodeKind.directory,
      byteLength: 0,
      token: 'directory:$path',
    );

Sha256Hash bytesHash(String text) =>
    Sha256Hash(crypto.sha256.convert(utf8.encode(text)).toString());

Future<SourceSnapshot> scan(
  FakeSourceTree tree, {
  String namespace = 'source-project',
  SourceScanPolicy? policy,
  ScanCancellation? cancellation,
  void Function(JobProgress progress)? onProgress,
}) =>
    SourceScanner().scan(
      source: tree,
      logicalProjectNamespace: ConverterId(namespace),
      policy: policy,
      cancellation: cancellation,
      onProgress: onProgress,
    );

SourceFileEntry entryAt(SourceSnapshot snapshot, String path) =>
    snapshot.entries.singleWhere((entry) => entry.relativePath == path);

void expectBlocked(SourceSnapshot snapshot, String path) {
  expect(snapshot.state, isNot(SourceScanState.complete));
  expect(
    snapshot.diagnostics,
    contains(isA<SourceScanDiagnostic>()
        .having((diagnostic) => diagnostic.blocksExtraction, 'blocks', true)
        .having((diagnostic) => diagnostic.relativePath, 'path', path)),
  );
}

Future<SourceSnapshot> conflictingProfile() => scan(FakeSourceTree.text({
      'README.md': '# Demo\nPokemon Essentials v21.1\n',
      'Data/Scripts/001_Settings.rb': '# Settings\nESSENTIALS_VERSION = "22"\n',
    }));

ConfirmedProfileOverride overrideFor(
  SourceProfile profile, {
  String version = '21.1',
  Sha256Hash? sourceHash,
  Sha256Hash? evidenceHash,
  bool humanConfirmed = true,
  String reason = 'The README is the intended source profile.',
}) =>
    ConfirmedProfileOverride(
      version: version,
      sourceSnapshotHash: sourceHash ?? profile.sourceSnapshotHash,
      evidenceHash: evidenceHash ?? profile.evidenceHash,
      humanConfirmed: humanConfirmed,
      reason: reason,
    );

SourceSnapshot snapshotWith(
  SourceSnapshot original, {
  List<SourceFileEntry>? entries,
  List<String>? excludedPaths,
  List<SourceProfileEvidence>? profileEvidence,
}) =>
    SourceSnapshot(
      logicalProjectNamespace: original.logicalProjectNamespace,
      policyHash: original.policyHash,
      entries: entries ?? original.entries,
      diagnostics: original.diagnostics,
      excludedPaths: excludedPaths ?? original.excludedPaths,
      profileEvidence: profileEvidence ?? original.profileEvidence,
      state: original.state,
    );

SourceFileEntry entryWith(
  SourceFileEntry original, {
  String? path,
  int? byteLength,
  SourceNodeKind? kind,
  bool clearHash = false,
}) =>
    SourceFileEntry(
      fileId: original.fileId,
      relativePath: path ?? original.relativePath,
      kind: kind ?? original.kind,
      byteLength: byteLength ?? original.byteLength,
      sha256: clearHash ? null : original.sha256,
      format: original.format,
      family: original.family,
    );

Future<({SourceSnapshot complete, SourceSnapshot partial})> snapshotPair(
    SourceNodeKind kind) async {
  const files = {'README.md': 'Pokemon Essentials v21.1\n'};
  final complete = await scan(FakeSourceTree.text(files));
  final partial = await scan(FakeSourceTree.text(files, extraNodes: [
    SourceNode(
      relativePath: 'unsafe-node',
      kind: kind,
      byteLength: 0,
      token: 'unsafe-node',
    ),
  ]));
  return (complete: complete, partial: partial);
}

void main() {
  group('SRC-01 immutable source inventory', () {
    test('hashes real file bytes and preserves directory structure', () async {
      final tree = FakeSourceTree.text(
        {'Data/Map001.rxdata': 'hello', 'Graphics/Tilesets/outside.png': 'png'},
        extraNodes: [
          directoryNode('Data'),
          directoryNode('Graphics'),
          directoryNode('Graphics/Tilesets'),
          directoryNode('Empty'),
        ],
      );
      final before = jsonEncode(tree.chunks);
      final snapshot = await scan(tree);

      expect(snapshot.state, SourceScanState.complete);
      expect(
          snapshot.entries.map((entry) => entry.relativePath),
          containsAll([
            'Data',
            'Graphics',
            'Graphics/Tilesets',
            'Empty',
            'Data/Map001.rxdata',
            'Graphics/Tilesets/outside.png',
          ]));
      final file = entryAt(snapshot, 'Data/Map001.rxdata');
      expect(file.sha256?.value,
          '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824');
      expect(file.byteLength, 5);
      expect(entryAt(snapshot, 'Empty').kind, SourceNodeKind.directory);
      expect(entryAt(snapshot, 'Empty').sha256, isNull);
      expect(tree.readCalls.toSet(),
          {'Data/Map001.rxdata', 'Graphics/Tilesets/outside.png'});
      expect(jsonEncode(tree.chunks), before);
    });

    test('snapshot hash is stable across enumeration order', () async {
      final files = {'Data/a.rxdata': 'a', 'Graphics/b.png': 'b'};
      final first = await scan(FakeSourceTree.text(files));
      final second = await scan(FakeSourceTree.text(files, reverse: true));

      expect(first.canonicalHash, second.canonicalHash);
      expect(first.toJson(), second.toJson());
      expect(first.entries.map((entry) => entry.relativePath).toList(),
          orderedEquals(second.entries.map((entry) => entry.relativePath)));
    });

    test('snapshot bytes stay separate from the logical namespace', () async {
      final first = await scan(FakeSourceTree.text({'Data/a.rxdata': 'a'}),
          namespace: 'project-one');
      final second = await scan(FakeSourceTree.text({'Data/a.rxdata': 'a'}),
          namespace: 'project-two');

      expect(first.canonicalHash, second.canonicalHash);
      expect(entryAt(first, 'Data/a.rxdata').fileId,
          isNot(entryAt(second, 'Data/a.rxdata').fileId));
    });

    for (final path in ['Graphics/outside.png', 'Data/Scripts/main.rb']) {
      test('changing $path changes the snapshot but preserves its file ID',
          () async {
        final first = await scan(FakeSourceTree.text({path: 'old'}));
        final second = await scan(FakeSourceTree.text({path: 'new'}));

        expect(first.canonicalHash, isNot(second.canonicalHash));
        expect(entryAt(first, path).sha256, bytesHash('old'));
        expect(entryAt(second, path).sha256, bytesHash('new'));
        expect(entryAt(first, path).fileId, entryAt(second, path).fileId);
      });
    }

    test('empty directories are part of the source structure', () async {
      final first = await scan(FakeSourceTree.text({'Data/a.rxdata': 'a'}));
      final second = await scan(FakeSourceTree.text({'Data/a.rxdata': 'a'},
          extraNodes: [directoryNode('Empty')]));

      expect(first.canonicalHash, isNot(second.canonicalHash));
    });

    test('port identity tokens do not replace content identities', () async {
      final first = await scan(FakeSourceTree(
        nodes: [fileNode('Data/a.rxdata', 1, token: 'first-handle')],
        chunks: {
          'Data/a.rxdata': [utf8.encode('a')]
        },
      ));
      final second = await scan(FakeSourceTree(
        nodes: [fileNode('Data/a.rxdata', 1, token: 'second-handle')],
        chunks: {
          'Data/a.rxdata': [utf8.encode('a')]
        },
      ));

      expect(first.canonicalHash, second.canonicalHash);
    });

    test('file identities preserve original Unicode path bytes', () async {
      const composed = 'Graphics/Café.png';
      const decomposed = 'Graphics/Cafe\u0301.png';
      final first = await scan(FakeSourceTree.text({composed: 'image'}));
      final second = await scan(FakeSourceTree.text({decomposed: 'image'}));

      expect(
          sourcePathCollisionKey(composed), sourcePathCollisionKey(decomposed));
      expect(entryAt(first, composed).fileId,
          isNot(entryAt(second, decomposed).fileId));
    });

    test('node kind participates in stable file identity', () async {
      final file = await scan(FakeSourceTree.text({'node': 'a'}));
      final directory = await scan(
          FakeSourceTree.text({}, extraNodes: [directoryNode('node')]));

      expect(entryAt(file, 'node').fileId,
          isNot(entryAt(directory, 'node').fileId));
    });

    test('excluded secrets and source caches are never opened', () async {
      final sensitive = {
        '.env',
        '.git/config',
        'credentials.json',
        'Data/secrets.json',
        'saves/slot1.rxdata',
        'cache/thumbnail.png',
        'logs/debug.log',
      };
      final files = {
        'Data/Map001.rxdata': 'map',
        for (final path in sensitive) path: 'private',
      };
      final tree = FakeSourceTree.text(files, forbiddenReads: sensitive);
      final snapshot = await scan(tree);

      expect(snapshot.state, SourceScanState.complete);
      expect(tree.readCalls, ['Data/Map001.rxdata']);
      expect(snapshot.excludedPaths, containsAll(sensitive));
      expect(snapshot.entries.map((entry) => entry.relativePath),
          isNot(anyElement(isIn(sensitive))));
    });

    test('excluded byte changes cannot affect the public source fingerprint',
        () async {
      final first = await scan(FakeSourceTree.text(
          {'Data/Map001.rxdata': 'map', '.env': 'first secret'}));
      final second = await scan(FakeSourceTree.text(
          {'Data/Map001.rxdata': 'map', '.env': 'another secret'}));

      expect(first.canonicalHash, second.canonicalHash);
    });

    test('exclusion rules match folded path segments rather than substrings',
        () {
      final policy = SourceScanPolicy();

      for (final path in [
        'Data/.ENV',
        'DATA/CREDENTIALS.JSON',
        'SAVES/slot1'
      ]) {
        expect(policy.isExcluded(path), isTrue, reason: path);
      }
      expect(policy.isExcluded('Data/cacheable.rb'), isFalse);
      expect(policy.isExcluded('Graphics/saveset.png'), isFalse);
    });

    test('scan policy receipts include limits and exclusion rules', () {
      final first = SourceScanPolicy();
      final limitsChanged =
          SourceScanPolicy(limits: const SourceScanLimits(maxFileBytes: 100));
      final exclusionsChanged = SourceScanPolicy(excludedSegments: ['private']);

      expect(first.canonicalHash, isNot(limitsChanged.canonicalHash));
      expect(first.canonicalHash, isNot(exclusionsChanged.canonicalHash));
      expect(first.canonicalHash, SourceScanPolicy().canonicalHash);
    });

    test('snapshot and policy collections reject caller mutation', () async {
      final excludedSegments = ['private'];
      final policy = SourceScanPolicy(excludedSegments: excludedSegments);
      excludedSegments.clear();
      final snapshot = await scan(
        FakeSourceTree.text({'Data/a.rxdata': 'a', 'private/key': 'secret'}),
        policy: policy,
      );
      final hash = snapshot.canonicalHash;

      expect(policy.isExcluded('private/key'), isTrue);
      expect(() => policy.excludedSegments.clear(), throwsUnsupportedError);
      expect(() => snapshot.entries.clear(), throwsUnsupportedError);
      expect(() => snapshot.excludedPaths.clear(), throwsUnsupportedError);
      expect(() => snapshot.diagnostics.clear(), throwsUnsupportedError);
      expect(() => snapshot.profileEvidence.clear(), throwsUnsupportedError);
      expect(() => snapshot.toJson().clear(), throwsUnsupportedError);
      final encodedEntries = snapshot.toJson()['entries'] as List;
      expect(() => encodedEntries.clear(), throwsUnsupportedError);
      expect(
          () => (encodedEntries.first as Map).clear(), throwsUnsupportedError);
      expect(snapshot.canonicalHash, hash);
    });
  });

  group('SRC-02 hostile source entries', () {
    for (final path in [
      '',
      '.',
      '..',
      '../outside',
      '/absolute',
      'Data/../outside',
      'Data/./map.rxdata',
      'Data//map.rxdata',
      'Data/',
      'Data/map\u0000.rxdata',
      r'Data\map.rxdata',
      'C:/Data/map.rxdata',
      'C:map.rxdata',
    ]) {
      test('path validation refuses ${jsonEncode(path)}', () {
        expect(() => validateSourceRelativePath(path), throwsFormatException);
      });
      test('scanner never reads ${jsonEncode(path)}', () async {
        final tree =
            FakeSourceTree.text({path: 'hostile'}, forbiddenReads: {path});
        final snapshot = await scan(tree);

        expectBlocked(snapshot, path);
        expect(tree.readCalls, isEmpty);
      });
    }

    test('normal relative Unicode names remain valid', () {
      for (final path in [
        'Data/Map001.rxdata',
        'Graphics/Café.png',
        'file..txt'
      ]) {
        expect(() => validateSourceRelativePath(path), returnsNormally);
      }
    });

    test('path length is checked before file reads', () async {
      const path = 'a-too-long-path.rxdata';
      final tree =
          FakeSourceTree.text({path: 'content'}, forbiddenReads: {path});
      final snapshot = await scan(tree,
          policy: SourceScanPolicy(
              limits: const SourceScanLimits(maxPathCodeUnits: 8)));

      expect(() => validateSourceRelativePath(path, maxCodeUnits: 8),
          throwsFormatException);
      expectBlocked(snapshot, path);
      expect(tree.readCalls, isEmpty);
    });

    for (final kind in [SourceNodeKind.link, SourceNodeKind.special]) {
      test('$kind is reported without opening it', () async {
        final tree = FakeSourceTree.text(
          {'Data/Map001.rxdata': 'map'},
          extraNodes: [
            SourceNode(
                relativePath: 'Data/unsupported',
                kind: kind,
                byteLength: 0,
                token: 'unsupported'),
          ],
          forbiddenReads: {'Data/unsupported'},
        );
        final snapshot = await scan(tree);

        expect(snapshot.state, SourceScanState.partial);
        expectBlocked(snapshot, 'Data/unsupported');
        expect(
            entryAt(snapshot, 'Data/Map001.rxdata').sha256, bytesHash('map'));
        expect(tree.readCalls, ['Data/Map001.rxdata']);
      });
    }
  });

  group('SRC-03 case and Unicode ambiguity', () {
    final collisions = <String, List<String>>{
      'ASCII case': ['Graphics/Outside.png', 'graphics/outside.PNG'],
      'NFC': ['Graphics/Café.png', 'Graphics/Cafe\u0301.png'],
      'sharp s': ['Graphics/straße.png', 'Graphics/STRASSE.png'],
      'Greek sigma': ['Graphics/Σ.png', 'Graphics/σ.png', 'Graphics/ς.png'],
      'dotted I': ['Graphics/İ.png', 'Graphics/i\u0307.png'],
    };
    for (final collision in collisions.entries) {
      test('${collision.key} has a common collision key', () {
        final keys = collision.value.map(sourcePathCollisionKey).toSet();
        expect(keys, hasLength(1));
      });
      test(
          '${collision.key} reports the complete group without choosing a file',
          () async {
        final tree = FakeSourceTree.text(
          {for (final path in collision.value) path: 'image'},
          forbiddenReads: collision.value.toSet(),
        );
        final snapshot = await scan(tree);

        expect(snapshot.state, isNot(SourceScanState.complete));
        expect(tree.readCalls, isEmpty);
        expect(
          snapshot.diagnostics,
          contains(isA<SourceScanDiagnostic>()
              .having(
                  (diagnostic) => diagnostic.blocksExtraction, 'blocks', true)
              .having((diagnostic) => diagnostic.relatedPaths, 'group',
                  containsAll(collision.value))),
        );
      });
    }

    test('Unicode default folding does not conflate dotless I', () {
      expect(sourcePathCollisionKey('Graphics/I.png'),
          isNot(sourcePathCollisionKey('Graphics/ı.png')));
      expect(sourcePathCollisionKey('Graphics/İ.png'),
          isNot(sourcePathCollisionKey('Graphics/i.png')));
    });

    test('collision diagnostic groups are immutable', () async {
      final snapshot = await scan(
          FakeSourceTree.text({'Graphics/A.png': 'a', 'Graphics/a.PNG': 'b'}));
      final diagnostic = snapshot.diagnostics
          .firstWhere((diagnostic) => diagnostic.relatedPaths.length == 2);

      expect(() => diagnostic.relatedPaths.clear(), throwsUnsupportedError);
    });
  });

  group('SRC-04 bounded scan and source races', () {
    test('aggregate path quota stops before content reads', () async {
      final tree = FakeSourceTree.text({'a-long.bin': 'a', 'b-long.bin': 'b'},
          forbiddenReads: {'a-long.bin', 'b-long.bin'});
      final snapshot = await scan(tree,
          policy: SourceScanPolicy(
              limits: const SourceScanLimits(maxTotalPathCodeUnits: 15)));

      expect(snapshot.state, isNot(SourceScanState.complete));
      expect(
          snapshot.diagnostics.any((diagnostic) => diagnostic.blocksExtraction),
          isTrue);
      expect(tree.readCalls, isEmpty);
    });

    test('an allowed inventory larger than four MiB remains hashable',
        () async {
      final longComponent = 'x' * 3700;
      final files = {
        for (var i = 0; i < 1150; i++) 'Data/$longComponent-$i.bin': 'a',
      };
      final snapshot = await scan(FakeSourceTree.text(files));

      expect(snapshot.state, SourceScanState.complete);
      expect(snapshot.entries, hasLength(files.length));
      expect(utf8.encode(jsonEncode(snapshot.toJson())).length,
          greaterThan(4 * 1024 * 1024));
      expect(snapshot.canonicalHash.value, hasLength(64));
      expect(snapshot.canonicalHash, snapshot.canonicalHash);
    });

    final invalidLimits = <String, SourceScanLimits>{
      'entries': const SourceScanLimits(maxEntries: 0),
      'depth': const SourceScanLimits(maxDepth: 0),
      'file bytes': const SourceScanLimits(maxFileBytes: 0),
      'total bytes': const SourceScanLimits(maxTotalBytes: 0),
      'path length': const SourceScanLimits(maxPathCodeUnits: 0),
      'total path length': const SourceScanLimits(maxTotalPathCodeUnits: 0),
      'probe bytes': const SourceScanLimits(maxProbeBytes: 0),
      'diagnostics': const SourceScanLimits(maxDiagnostics: 0),
      'profile evidence': const SourceScanLimits(maxProfileEvidence: 0),
    };
    for (final limits in invalidLimits.entries) {
      test('invalid ${limits.key} limit is rejected before enumeration',
          () async {
        final tree = FakeSourceTree.text({'a.bin': 'a'});

        await expectLater(
          Future.sync(
              () => scan(tree, policy: SourceScanPolicy(limits: limits.value))),
          throwsA(anyOf(isA<ArgumentError>(), isA<ContractError>())),
        );
        expect(tree.walkCalls, 0);
        expect(tree.readCalls, isEmpty);
      });
    }

    for (final segment in [
      '',
      '.',
      '..',
      '../secret',
      'private/file',
      r'private\file',
      'secret\u0000'
    ]) {
      test(
          'invalid exclusion ${jsonEncode(segment)} is rejected before walking',
          () async {
        final tree = FakeSourceTree.text({'a.bin': 'a'});

        await expectLater(
          Future.sync(() => scan(tree,
              policy: SourceScanPolicy(excludedSegments: [segment]))),
          throwsA(anyOf(isA<ArgumentError>(), isA<ContractError>())),
        );
        expect(tree.walkCalls, 0);
        expect(tree.readCalls, isEmpty);
      });
    }

    test('entry quota stops before any content is opened', () async {
      final tree = FakeSourceTree.text({'a.bin': 'a', 'b.bin': 'b'},
          forbiddenReads: {'a.bin', 'b.bin'});
      final snapshot = await scan(tree,
          policy:
              SourceScanPolicy(limits: const SourceScanLimits(maxEntries: 1)));

      expect(snapshot.state, isNot(SourceScanState.complete));
      expect(
          snapshot.diagnostics.any((diagnostic) => diagnostic.blocksExtraction),
          isTrue);
      expect(tree.readCalls, isEmpty);
    });

    test('depth quota stops before a deeply nested file read', () async {
      const path = 'Data/Nested/deep.bin';
      final tree = FakeSourceTree.text({path: 'data'}, forbiddenReads: {path});
      final snapshot = await scan(tree,
          policy:
              SourceScanPolicy(limits: const SourceScanLimits(maxDepth: 1)));

      expectBlocked(snapshot, path);
      expect(tree.readCalls, isEmpty);
    });

    test('declared file size quota stops before allocation or reading',
        () async {
      const path = 'huge.bin';
      final tree = FakeSourceTree(
        nodes: [fileNode(path, 1000000000)],
        chunks: {},
        forbiddenReads: {path},
      );
      final snapshot = await scan(tree,
          policy: SourceScanPolicy(
              limits: const SourceScanLimits(maxFileBytes: 8)));

      expectBlocked(snapshot, path);
      expect(tree.readCalls, isEmpty);
    });

    test('declared aggregate quota stops before any content read', () async {
      final tree = FakeSourceTree.text({'a.bin': 'abc', 'b.bin': 'def'},
          forbiddenReads: {'a.bin', 'b.bin'});
      final snapshot = await scan(tree,
          policy: SourceScanPolicy(
              limits: const SourceScanLimits(maxTotalBytes: 5)));

      expect(snapshot.state, isNot(SourceScanState.complete));
      expect(
          snapshot.diagnostics.any((diagnostic) => diagnostic.blocksExtraction),
          isTrue);
      expect(tree.readCalls, isEmpty);
    });

    test('actual file growth is rejected while consuming bounded chunks',
        () async {
      final tree = FakeSourceTree(
        nodes: [fileNode('growing.bin', 3)],
        chunks: {
          'growing.bin': [utf8.encode('abc'), utf8.encode('def')],
        },
      );
      final snapshot = await scan(tree,
          policy: SourceScanPolicy(
              limits: const SourceScanLimits(maxFileBytes: 5)));

      expectBlocked(snapshot, 'growing.bin');
      expect(tree.readBudgets['growing.bin'], lessThanOrEqualTo(5));
      expect(
          snapshot.entries
              .where((entry) => entry.relativePath == 'growing.bin')
              .every((entry) => entry.sha256 == null),
          isTrue);
    });

    test('a shorter stream cannot claim the declared file hash', () async {
      final tree = FakeSourceTree(
        nodes: [fileNode('truncated.bin', 5)],
        chunks: {
          'truncated.bin': [utf8.encode('abc')]
        },
      );
      final snapshot = await scan(tree);

      expectBlocked(snapshot, 'truncated.bin');
      expect(
          snapshot.entries
              .where((entry) => entry.relativePath == 'truncated.bin')
              .every((entry) => entry.sha256 == null),
          isTrue);
    });

    test('a changed second-walk identity prevents a complete snapshot',
        () async {
      final tree = FakeSourceTree(
        nodes: [fileNode('Data/a.rxdata', 3, token: 'revision-one')],
        secondWalk: [fileNode('Data/a.rxdata', 3, token: 'revision-two')],
        chunks: {
          'Data/a.rxdata': [utf8.encode('abc')]
        },
      );
      final snapshot = await scan(tree);

      expect(tree.walkCalls, 2);
      expectBlocked(snapshot, 'Data/a.rxdata');
    });

    test('a file introduced after preflight invalidates the inventory',
        () async {
      final tree = FakeSourceTree(
        nodes: [fileNode('Data/a.rxdata', 3)],
        secondWalk: [
          fileNode('Data/a.rxdata', 3),
          fileNode('Data/new.rxdata', 3)
        ],
        chunks: {
          'Data/a.rxdata': [utf8.encode('abc')]
        },
        forbiddenReads: {'Data/new.rxdata'},
      );
      final snapshot = await scan(tree);

      expect(tree.walkCalls, 2);
      expectBlocked(snapshot, 'Data/new.rxdata');
      expect(tree.readCalls, ['Data/a.rxdata']);
    });

    test('pre-cancellation performs neither enumeration nor content reads',
        () async {
      final cancellation = ScanCancellation()..cancel();
      final tree = FakeSourceTree.text({'a.bin': 'abc'});
      final snapshot = await scan(tree, cancellation: cancellation);

      expect(snapshot.state, SourceScanState.cancelled);
      expect(tree.walkCalls, 0);
      expect(tree.readCalls, isEmpty);
      expect(snapshot.entries, isEmpty);
    });

    test('chunk cancellation stops before the next stream chunk', () async {
      final cancellation = ScanCancellation();
      final tree = FakeSourceTree(
        nodes: [fileNode('a.bin', 6)],
        chunks: {
          'a.bin': [utf8.encode('abc'), utf8.encode('def')]
        },
        onChunk: (_, chunkIndex) => cancellation.cancel(),
      );
      final snapshot = await scan(tree, cancellation: cancellation);

      expect(snapshot.state, SourceScanState.cancelled);
      expect(tree.chunksDelivered, 1);
      expect(
          snapshot.entries
              .where((entry) => entry.relativePath == 'a.bin')
              .every((entry) => entry.sha256 == null),
          isTrue);
    });

    test('progress reports monotonic completed files with a stable total',
        () async {
      final progress = <JobProgress>[];
      final snapshot = await scan(
        FakeSourceTree.text({'a.bin': 'abc', 'b.bin': 'def'}),
        onProgress: progress.add,
      );

      expect(snapshot.state, SourceScanState.complete);
      expect(progress, isNotEmpty);
      expect(progress.first.done, 0);
      expect(progress.last.done, 2);
      expect(progress.last.total, 2);
      for (var i = 0; i < progress.length; i++) {
        expect(progress[i].unit, JobUnit.files);
        expect(progress[i].total, 2);
        if (i > 0) {
          expect(progress[i].done, greaterThanOrEqualTo(progress[i - 1].done));
        }
      }
    });

    test('progress cancellation cannot start another file', () async {
      final cancellation = ScanCancellation();
      final progress = <JobProgress>[];
      final tree = FakeSourceTree.text({'a.bin': 'abc', 'b.bin': 'def'});
      final snapshot = await scan(
        tree,
        cancellation: cancellation,
        onProgress: (update) {
          progress.add(update);
          if (update.done == 1) {
            cancellation.cancel();
          }
        },
      );

      expect(snapshot.state, SourceScanState.cancelled);
      expect(tree.readCalls.length, lessThanOrEqualTo(1));
      expect(progress.last.done, 1);
      expect(progress.last.total, 2);
    });
  });

  group('SRC-05 observed profile and explicit confirmation', () {
    test('no version evidence leaves the source profile unknown', () async {
      final snapshot =
          await scan(FakeSourceTree.text({'Data/map.rxdata': 'map'}));

      expect(snapshot.profile.state, SourceProfileState.unknown);
      expect(snapshot.profile.version, isNull);
      expect(snapshot.profile.evidence, isEmpty);
    });

    test('a single README version is observed rather than certified', () async {
      final snapshot = await scan(
          FakeSourceTree.text({'README.md': 'Pokemon Essentials v21.1\n'}));

      expect(snapshot.state, SourceScanState.complete);
      expect(snapshot.profile.state, SourceProfileState.observed);
      expect(snapshot.profile.version, '21.1');
      expect(snapshot.profile.state, isNot(SourceProfileState.confirmed));
    });

    test('README and script disagreement requires human confirmation',
        () async {
      final snapshot = await conflictingProfile();
      final profile = snapshot.profile;

      expect(snapshot.state, SourceScanState.complete);
      expect(profile.state, SourceProfileState.requiresConfirmation);
      expect(profile.version, isNull);
      expect(profile.evidence.map((evidence) => evidence.version).toSet(),
          {'21.1', '22'});
      for (final evidence in profile.evidence) {
        expect(
            evidence.fileHash, entryAt(snapshot, evidence.relativePath).sha256);
        expect(evidence.line, 2);
        expect(evidence.excerpt, contains(evidence.version));
      }
    });

    test('profile evidence is bounded without truncating the file digest',
        () async {
      const content = 'ordinary text\nPokemon Essentials v21.1\n';
      final snapshot = await scan(
        FakeSourceTree.text({'README.md': content}),
        policy:
            SourceScanPolicy(limits: const SourceScanLimits(maxProbeBytes: 4)),
      );

      expect(entryAt(snapshot, 'README.md').sha256, bytesHash(content));
      expect(snapshot.profile.evidence, isEmpty);
      expect(snapshot.profile.state, SourceProfileState.unknown);
    });

    test('confirmation binds the exact snapshot and evidence without mutation',
        () async {
      final snapshot = await conflictingProfile();
      final original = snapshot.profile;
      final confirmed = original.confirm(overrideFor(original));

      expect(confirmed.state, SourceProfileState.confirmed);
      expect(confirmed.version, '21.1');
      expect(confirmed.sourceSnapshotHash, original.sourceSnapshotHash);
      expect(confirmed.evidenceHash, original.evidenceHash);
      expect(original.state, SourceProfileState.requiresConfirmation);
      expect(() => confirmed.evidence.clear(), throwsUnsupportedError);
    });

    test('evidence receipts are immutable and independent of enumeration order',
        () async {
      final source = (await conflictingProfile()).profile;
      final evidence = source.evidence.toList();
      final profile = SourceProfile(
        sourceSnapshotHash: source.sourceSnapshotHash,
        evidence: evidence,
      );
      final reversed = SourceProfile(
        sourceSnapshotHash: source.sourceSnapshotHash,
        evidence: evidence.reversed.toList(),
      );
      evidence.clear();

      expect(profile.evidence, hasLength(2));
      expect(profile.evidenceHash, reversed.evidenceHash);
      expect(() => profile.evidence.clear(), throwsUnsupportedError);
    });

    for (final mismatch in [
      'snapshot',
      'evidence',
      'human',
      'reason',
      'version'
    ]) {
      test('confirmation rejects mismatched $mismatch', () async {
        final profile = (await conflictingProfile()).profile;
        final override = overrideFor(
          profile,
          sourceHash: mismatch == 'snapshot' ? Sha256Hash('0' * 64) : null,
          evidenceHash: mismatch == 'evidence' ? Sha256Hash('1' * 64) : null,
          humanConfirmed: mismatch != 'human',
          reason: mismatch == 'reason' ? ' \n ' : 'Explicit profile choice.',
          version: mismatch == 'version' ? ' ' : '21.1',
        );

        expect(() => profile.confirm(override), throwsFormatException);
      });
    }
  });

  group('public snapshot validation', () {
    for (final paths in [
      ['Graphics/A.png', 'Graphics/a.PNG'],
      ['Graphics/Café.png', 'Graphics/Cafe\u0301.png'],
    ]) {
      test('complete public snapshots reject folded collision ${paths.first}',
          () async {
        final first = await scan(FakeSourceTree.text({paths.first: 'image'}));
        final second = await scan(FakeSourceTree.text({paths.last: 'image'}));
        final entries = [first.entries.single, second.entries.single];
        expect(entries.first.fileId, isNot(entries.last.fileId));
        expect(entries.every((entry) => entry.sha256 != null), isTrue);

        expect(
          () => SourceSnapshot(
            logicalProjectNamespace: first.logicalProjectNamespace,
            policyHash: first.policyHash,
            entries: entries,
            diagnostics: [],
            excludedPaths: [],
            profileEvidence: [],
            state: SourceScanState.complete,
          ),
          throwsFormatException,
        );
      });
    }

    test('duplicate paths and file IDs are rejected', () async {
      final original = await scan(FakeSourceTree.text({'a.bin': 'a'}));
      final entry = original.entries.single;

      expect(() => snapshotWith(original, entries: [entry, entry]),
          throwsFormatException);
    });

    test('invalid public entry paths are rejected', () async {
      final original = await scan(FakeSourceTree.text({'a.bin': 'a'}));

      expect(
        () => snapshotWith(original,
            entries: [entryWith(original.entries.single, path: '../outside')]),
        throwsFormatException,
      );
    });

    test('a complete file entry must carry its digest', () async {
      final original = await scan(FakeSourceTree.text({'a.bin': 'a'}));

      expect(
        () => snapshotWith(original,
            entries: [entryWith(original.entries.single, clearHash: true)]),
        throwsFormatException,
      );
    });

    test('directory entries cannot impersonate hashed file bytes', () async {
      final original = await scan(FakeSourceTree.text({'a.bin': 'a'}));

      expect(
        () => snapshotWith(original, entries: [
          entryWith(original.entries.single,
              kind: SourceNodeKind.directory, byteLength: 0),
        ]),
        throwsFormatException,
      );
    });

    test('negative public entry sizes are rejected', () async {
      final original = await scan(FakeSourceTree.text({'a.bin': 'a'}));

      expect(
        () => snapshotWith(original,
            entries: [entryWith(original.entries.single, byteLength: -1)]),
        throwsFormatException,
      );
    });

    test('excluded paths must also respect relative path validation', () async {
      final original = await scan(FakeSourceTree.text({'a.bin': 'a'}));

      expect(() => snapshotWith(original, excludedPaths: ['../secret']),
          throwsFormatException);
    });

    test('profile evidence cannot reference an absent source entry', () async {
      final original = await conflictingProfile();
      final evidence = original.profileEvidence.first;

      expect(
        () => snapshotWith(original, profileEvidence: [
          SourceProfileEvidence(
            relativePath: 'absent.rb',
            fileHash: evidence.fileHash,
            version: evidence.version,
            line: evidence.line,
            excerpt: evidence.excerpt,
          ),
        ]),
        throwsFormatException,
      );
    });

    test('profile evidence digest must match its source file entry', () async {
      final original = await conflictingProfile();
      final evidence = original.profileEvidence.first;

      expect(
        () => snapshotWith(original, profileEvidence: [
          SourceProfileEvidence(
            relativePath: evidence.relativePath,
            fileHash: Sha256Hash('0' * 64),
            version: evidence.version,
            line: evidence.line,
            excerpt: evidence.excerpt,
          ),
        ]),
        throwsFormatException,
      );
    });
  });

  group('snapshot completion and bounded profile evidence', () {
    for (final kind in [SourceNodeKind.link, SourceNodeKind.special]) {
      test(
          '$kind changes the fingerprint without changing the profile evidence',
          () async {
        final pair = await snapshotPair(kind);

        expect(pair.complete.state, SourceScanState.complete);
        expect(pair.partial.state, SourceScanState.partial);
        expect(pair.partial.canonicalHash, isNot(pair.complete.canonicalHash));
        expect(pair.partial.profile.evidenceHash,
            pair.complete.profile.evidenceHash);
      });
      test('$kind cannot inherit a complete snapshot approval', () async {
        final pair = await snapshotPair(kind);

        expect(
          () =>
              pair.partial.profile.confirm(overrideFor(pair.complete.profile)),
          throwsFormatException,
        );
      });
      test('$kind cannot confirm an incomplete current snapshot', () async {
        final pair = await snapshotPair(kind);

        expect(
          () => pair.partial.profile.confirm(overrideFor(pair.partial.profile)),
          throwsFormatException,
        );
      });
    }

    test('dense one MiB profile probes stop at the evidence quota', () async {
      final content = 'Pokemon Essentials v1\n' * 50000;
      final snapshot = await scan(
        FakeSourceTree.text({'README.md': content}),
        policy: SourceScanPolicy(
          limits: const SourceScanLimits(
            maxProbeBytes: 1024 * 1024,
            maxProfileEvidence: 1,
          ),
        ),
      );

      expect(snapshot.state, SourceScanState.partial);
      expectBlocked(snapshot, 'README.md');
      expect(snapshot.profile.evidence, hasLength(1));
      expect(snapshot.profile.evidence.single.line, 1);
    });
  });
}
