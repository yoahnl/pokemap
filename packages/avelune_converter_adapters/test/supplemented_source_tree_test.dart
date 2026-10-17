import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  if (!Platform.isMacOS) {
    test('rejects shared source access on unsupported platforms', () async {
      await expectLater(
          SupplementedSourceTree.open('/tmp'),
          throwsA(isA<ContractError>().having(
              (error) => error.code, 'code', 'source.platform_unsupported')));
    });
    return;
  }

  late Directory sandbox;
  late Directory primary;
  late Directory reference;
  late SupplementedSourceTree tree;

  setUp(() async {
    sandbox = await Directory('/private/tmp').createTemp('cv_shared_');
    primary = await Directory('${sandbox.path}/primary').create();
    reference = await Directory('${sandbox.path}/reference').create();
    tree = await SupplementedSourceTree.open(primary.path,
        supplementalRootPaths: [reference.path]);
  });

  tearDown(() async {
    await tree.close();
    await sandbox.delete(recursive: true);
  });

  Future<File> write(Directory root, String name, String value) async {
    final file = File('${root.path}/$name');
    await file.parent.create(recursive: true);
    return file.writeAsString(value);
  }

  Future<List<SourceNode>> walk({SourceScanPolicy? policy}) => tree
      .walk(
          policy: policy ?? SourceScanPolicy(),
          cancellation: ScanCancellation())
      .toList();

  Future<String> read(SourceNode node) async => String.fromCharCodes((await tree
          .read(node, maxBytes: 1024, cancellation: ScanCancellation())
          .toList())
      .expand((chunk) => chunk));

  Matcher code(String value) =>
      isA<ContractError>().having((error) => error.code, 'code', value);

  test('supplements exactly declared missing catalogs without source writes',
      () async {
    await write(primary, 'Data/Map001.rxdata', 'map');
    for (final name in [
      'Data/Scripts.rxdata',
      'Data/items.dat',
      'PBS/items.txt',
      'Data/moves.dat',
      'PBS/moves.txt',
      'Data/species.dat',
      'PBS/pokemon.txt',
      'PBS/pokemon_forms.txt',
      'Graphics/Tilesets/FRLG_Interior general.png',
      'Audio/BGM/route.ogg',
      'Game.exe'
    ]) {
      await write(reference, name, name);
    }
    await write(reference, 'Data/Map002.rxdata', 'foreign map');
    await write(reference, 'Data/encounters.dat', 'foreign encounters');
    await write(reference, 'PBS/metadata.txt', 'foreign metadata');
    await write(reference, 'Graphics/notes.txt', 'foreign text');
    await write(reference, 'Other.exe', 'foreign executable');
    final nodes = await walk();
    expect(
        nodes
            .where((node) => node.kind == SourceNodeKind.file)
            .map((node) => node.relativePath)
            .toSet(),
        {
          'Data/Map001.rxdata',
          'Data/Scripts.rxdata',
          'Data/items.dat',
          'PBS/items.txt',
          'Data/moves.dat',
          'PBS/moves.txt',
          'Data/species.dat',
          'PBS/pokemon.txt',
          'PBS/pokemon_forms.txt',
          'Graphics/Tilesets/FRLG_Interior general.png',
          'Audio/BGM/route.ogg',
          'Game.exe'
        });
    expect(tree.sharedRelativePaths.toSet(), {
      'Data/Scripts.rxdata',
      'Data/items.dat',
      'PBS/items.txt',
      'Data/moves.dat',
      'PBS/moves.txt',
      'Data/species.dat',
      'PBS/pokemon.txt',
      'PBS/pokemon_forms.txt',
      'Graphics/Tilesets/FRLG_Interior general.png',
      'Audio/BGM/route.ogg',
      'Game.exe'
    });
    for (final node
        in nodes.where((node) => node.kind == SourceNodeKind.file)) {
      expect(
          await read(node),
          node.relativePath == 'Data/Map001.rxdata'
              ? 'map'
              : node.relativePath);
    }
    expect(await File('${primary.path}/Data/items.dat').exists(), isFalse);
    expect(await Directory('${primary.path}/PBS').exists(), isFalse);
    expect(await File('${reference.path}/Data/encounters.dat').readAsString(),
        'foreign encounters');
  });

  test('existing source file wins even when reference disagrees', () async {
    await write(primary, 'Data/items.dat', 'primary');
    await write(reference, 'Data/items.dat', 'reference');
    final node =
        (await walk()).singleWhere((n) => n.kind == SourceNodeKind.file);
    expect(await read(node), 'primary');
    expect(tree.sharedRelativePaths, isEmpty);
  });

  test('a complete project without a reference keeps the same inventory',
      () async {
    await write(primary, 'original.txt', 'original');
    final original = await MacOsSourceTree.open(primary.path);
    final unchanged = await SupplementedSourceTree.open(primary.path);
    addTearDown(original.close);
    addTearDown(unchanged.close);
    final namespace = ConverterId('unchanged-project');
    final expected = await SourceScanner()
        .scan(source: original, logicalProjectNamespace: namespace);
    final actual = await SourceScanner()
        .scan(source: unchanged, logicalProjectNamespace: namespace);
    expect(actual.canonicalHash, expected.canonicalHash);
    expect(unchanged.sharedRelativePaths, isEmpty);
  });

  test('missing reference files are not fabricated', () async {
    await write(primary, 'original.txt', 'original');
    expect((await walk()).map((n) => n.relativePath), ['original.txt']);
    expect(tree.sharedRelativePaths, isEmpty);
  });

  test('does not replace an existing source directory with a catalog file',
      () async {
    await Directory('${primary.path}/Data/items.dat').create(recursive: true);
    await write(reference, 'Data/items.dat', 'reference');
    final nodes = await walk();
    expect(nodes.singleWhere((n) => n.relativePath == 'Data/items.dat').kind,
        SourceNodeKind.directory);
    expect(tree.sharedRelativePaths, isEmpty);
  });

  test('rejects a forged shared node with a copied token', () async {
    await write(reference, 'Data/items.dat', 'reference');
    final node =
        (await walk()).singleWhere((n) => n.kind == SourceNodeKind.file);
    final forged = SourceNode(
        relativePath: node.relativePath,
        kind: node.kind,
        byteLength: node.byteLength,
        token: node.token);
    await expectLater(read(forged), throwsA(code('source.node_unissued')));
    expect(await read(node), 'reference');
  });

  test('rejects reference file replaced after inventory', () async {
    final file = await write(reference, 'Data/items.dat', 'reference');
    final node =
        (await walk()).singleWhere((n) => n.kind == SourceNodeKind.file);
    await file.rename('${file.path}.old');
    await write(reference, 'Data/items.dat', 'substitute');
    await expectLater(read(node), throwsA(code('source.changed')));
  });

  test('rejects source gaining a previously missing catalog before read',
      () async {
    await write(primary, 'Data/original.txt', 'original');
    await write(reference, 'Data/items.dat', 'reference');
    final node =
        (await walk()).singleWhere((n) => n.relativePath == 'Data/items.dat');
    await write(primary, 'Data/items.dat', 'new original');
    await expectLater(read(node), throwsA(code('source.changed')));
  });

  test(
      'a new walk cannot reauthorize an old supplemented node after source gain',
      () async {
    await write(primary, 'Data/original.txt', 'original');
    await write(reference, 'Data/items.dat', 'reference');
    final old =
        (await walk()).singleWhere((n) => n.relativePath == 'Data/items.dat');
    await write(primary, 'Data/items.dat', 'new original');
    final current =
        (await walk()).singleWhere((n) => n.relativePath == 'Data/items.dat');
    expect(await read(current), 'new original');
    await expectLater(read(old), throwsA(code('source.changed')));
  });

  test('rejects source gaining the catalog during a shared read', () async {
    await write(primary, 'Data/original.txt', 'original');
    await write(reference, 'Data/items.dat', 'reference');
    final node =
        (await walk()).singleWhere((n) => n.relativePath == 'Data/items.dat');
    await expectLater(
        tree
            .read(node, maxBytes: 1024, cancellation: ScanCancellation())
            .asyncMap((chunk) async {
          await write(primary, 'Data/items.dat', 'new original');
          return chunk;
        }).toList(),
        throwsA(code('source.changed')));
  });

  test('rejects shared ancestor case conflict with source', () async {
    await write(primary, 'data/original.txt', 'original');
    await write(reference, 'Data/items.dat', 'reference');
    await expectLater(walk(), throwsA(code('source.shared.path_conflict')));
  });

  test('rejects Unicode folded ancestor conflicts across source roots',
      () async {
    await write(primary, 'PBſ/original.txt', 'original');
    await write(reference, 'PBS/items.txt', 'reference');
    expect(sourcePathCollisionKey('PBſ'), sourcePathCollisionKey('PBS'));
    await expectLater(walk(), throwsA(code('source.shared.path_conflict')));
  });

  for (final name in ['Data/items.dat', 'Data']) {
    test('rejects shared link at $name', () async {
      await Directory('${reference.path}/Data').create();
      if (name == 'Data') await Directory('${reference.path}/Data').delete();
      await Link('${reference.path}/$name').create(primary.path);
      await expectLater(walk(), throwsA(code('source.shared.node_invalid')));
    });
  }

  test('rejects shared special nodes without opening them', () async {
    await Directory('${reference.path}/Data').create();
    final result = await Process.run(
        '/usr/bin/mkfifo', ['${reference.path}/Data/items.dat']);
    expect(result.exitCode, 0);
    await expectLater(walk(), throwsA(code('source.shared.node_invalid')));
  });

  test('honors excluded shared paths', () async {
    await write(reference, 'Data/items.dat', 'private');
    final nodes =
        await walk(policy: SourceScanPolicy(excludedSegments: ['Data']));
    expect(nodes.where((n) => n.kind == SourceNodeKind.file), isEmpty);
    expect(tree.sharedRelativePaths, isEmpty);
  });

  test('combined logical inventory enforces aggregate quotas', () async {
    await write(primary, 'original.txt', '1234');
    await write(reference, 'PBS/items.txt', '5678');
    await expectLater(
        walk(
            policy: SourceScanPolicy(
                limits: const SourceScanLimits(maxTotalBytes: 6))),
        throwsA(code('source.total_bytes_limit')));
    await expectLater(
        walk(
            policy: SourceScanPolicy(
                limits: const SourceScanLimits(maxEntries: 2))),
        throwsA(code('source.entry_limit')));
  });

  test('cancelled walk and read stop before access', () async {
    await write(reference, 'Data/items.dat', 'reference');
    final node =
        (await walk()).singleWhere((n) => n.kind == SourceNodeKind.file);
    final cancellation = ScanCancellation()..cancel();
    await expectLater(
        tree
            .walk(policy: SourceScanPolicy(), cancellation: cancellation)
            .toList(),
        throwsA(code('source.cancelled')));
    await expectLater(
        tree.read(node, maxBytes: 1024, cancellation: cancellation).toList(),
        throwsA(code('source.cancelled')));
  });

  test('ordered roots fill missing paths once and preserve exact origins',
      () async {
    final later = await Directory('${sandbox.path}/later').create();
    await tree.close();
    tree = await SupplementedSourceTree.open(primary.path,
        supplementalRootPaths: [reference.path, later.path]);
    await write(primary, 'Graphics/Tilesets/primary.png', 'primary');
    await write(reference, 'Graphics/Tilesets/primary.png', 'shadow');
    await write(reference, 'Graphics/Tilesets/shared.png', 'first');
    await write(later, 'Graphics/Tilesets/shared.png', 'second');
    await write(later, 'Audio/BGM/route.ogg', 'music');
    await write(later, 'Game.exe', 'oracle');
    await write(later, 'Data/Map999.rxdata', 'foreign map');
    await write(later, 'Graphics/tool.exe', 'foreign executable');
    final nodes = await walk();
    expect(
        await read(nodes.singleWhere(
            (node) => node.relativePath == 'Graphics/Tilesets/shared.png')),
        'first');
    final snapshot = await SourceScanner().scan(
        source: tree, logicalProjectNamespace: ConverterId('ordered-roots'));
    expect(snapshot.state, SourceScanState.complete);
    final provenance = tree.sharedSourceFilesFor(snapshot);
    expect(provenance.map((file) => file.relativePath).toSet(),
        {'Graphics/Tilesets/shared.png', 'Audio/BGM/route.ogg', 'Game.exe'});
    expect(
        provenance
            .singleWhere((file) => file.relativePath.endsWith('shared.png'))
            .referenceRootPath,
        reference.path);
    expect(
        provenance
            .singleWhere((file) => file.relativePath == 'Game.exe')
            .referenceRootPath,
        later.path);
    expect(await File('${primary.path}/Game.exe').exists(), isFalse);
    await tree.close();
    tree = await SupplementedSourceTree.open(primary.path,
        supplementalRootPaths: [later.path, reference.path]);
    expect(
        await read((await walk())
            .singleWhere((node) => node.relativePath.endsWith('shared.png'))),
        'second');
  });

  for (final duringRead in [false, true]) {
    test(
        'earlier reference gaining a media path is rejected duringRead=$duringRead',
        () async {
      final later = await Directory('${sandbox.path}/later').create();
      await tree.close();
      tree = await SupplementedSourceTree.open(primary.path,
          supplementalRootPaths: [reference.path, later.path]);
      await write(reference, 'Graphics/Tilesets/existing.png', 'existing');
      await write(later, 'Graphics/Tilesets/shared.png', 'same bytes');
      final node = (await walk())
          .singleWhere((node) => node.relativePath.endsWith('shared.png'));
      if (duringRead) {
        await expectLater(
            tree
                .read(node, maxBytes: 1024, cancellation: ScanCancellation())
                .asyncMap((chunk) async {
              await write(reference, node.relativePath, 'same bytes');
              return chunk;
            }).toList(),
            throwsA(code('source.changed')));
      } else {
        await write(reference, node.relativePath, 'same bytes');
        await expectLater(read(node), throwsA(code('source.changed')));
      }
    });
  }

  for (final blocked in ['Graphics/Pictures', 'data/items.dat']) {
    test('an invalid earlier entry blocks a lower reference at $blocked',
        () async {
      final later = await Directory('${sandbox.path}/later').create();
      await tree.close();
      tree = await SupplementedSourceTree.open(primary.path,
          supplementalRootPaths: [reference.path, later.path]);
      await write(reference, blocked, 'invalid higher entry');
      await write(
          later,
          blocked.startsWith('Graphics')
              ? 'Graphics/Pictures/witness.png'
              : 'Data/items.dat',
          'lower substitute');
      await expectLater(walk(), throwsA(code('source.shared.path_conflict')));
    });
  }

  test('canonical aliases and more than four references are rejected',
      () async {
    for (final roots in [
      [reference.path, reference.path.replaceFirst('/private/tmp/', '/tmp/')],
      [primary.path],
      List.filled(5, reference.path),
    ]) {
      await expectLater(
          SupplementedSourceTree.open(primary.path,
              supplementalRootPaths: roots),
          throwsA(code('source.shared.roots_invalid')));
    }
    expect(
        () => ConverterSourceSelection(
            rootPath: primary.path,
            supplementalRootPaths: [reference.path, reference.path],
            logicalProjectNamespace: ConverterId('roots')),
        throwsA(isA<ConverterWorkflowFailure>()));
  });

  test('media file quota stops the scan before any file body is read',
      () async {
    final file = await write(reference, 'Graphics/Tilesets/large.png', '');
    final opened = await file.open(mode: FileMode.write);
    await opened
        .truncate(SupplementedSourceTree.maxSupplementalMediaFileBytes + 1);
    await opened.close();
    final snapshot = await SourceScanner().scan(
        source: tree, logicalProjectNamespace: ConverterId('media-quota'));
    expect(snapshot.state, isNot(SourceScanState.complete));
    expect(snapshot.entries.where((entry) => entry.sha256 != null), isEmpty);
    expect(
        snapshot.diagnostics
            .any((entry) => entry.code == 'source.shared.media_quota'),
        isTrue);
  });

  test('media aggregate quota is reserved before reading sparse bodies',
      () async {
    for (var index = 0; index < 17; index++) {
      final file = await write(reference, 'Graphics/Pictures/$index.png', '');
      final opened = await file.open(mode: FileMode.write);
      await opened
          .truncate(SupplementedSourceTree.maxSupplementalMediaFileBytes);
      await opened.close();
    }
    await expectLater(walk(), throwsA(code('source.shared.media_quota')));
  });

  test('selection copies the ordered roots and exposes immutable lists', () {
    final roots = [reference.path, '${sandbox.path}/later'];
    final selected = ConverterSourceSelection(
        rootPath: primary.path,
        supplementalRootPaths: roots,
        logicalProjectNamespace: ConverterId('ordered-selection'));
    final reversed = ConverterSourceSelection(
        rootPath: primary.path,
        supplementalRootPaths: roots.reversed.toList(),
        logicalProjectNamespace: ConverterId('ordered-selection'));
    roots.clear();
    expect(selected.supplementalRootPaths.length, 2);
    expect(selected.canonicalHash, isNot(reversed.canonicalHash));
    expect(
        () => selected.supplementalRootPaths.clear(), throwsUnsupportedError);
    expect(() => selected.sourceRoots.clear(), throwsUnsupportedError);
  });

  test('media count quota is enforced before reading bodies', () async {
    for (var index = 0;
        index <= SupplementedSourceTree.maxSupplementalMediaFiles;
        index++) {
      await write(reference, 'Graphics/Pictures/$index.png', '');
    }
    await expectLater(walk(), throwsA(code('source.shared.media_quota')));
  });

  test('exclusions and unsupported media cannot be supplemented', () async {
    await write(reference, 'Graphics/cache/private.png', 'private');
    await write(reference, 'Audio/route.mid', 'unsupported');
    await write(reference, 'Graphics/script.rb', 'unsupported');
    await write(reference, 'Data/encounters.dat', 'unsupported');
    expect((await walk()).where((node) => node.kind == SourceNodeKind.file),
        isEmpty);
  });

  test('selection identity binds the explicit reference even for equal bytes',
      () {
    ConverterSourceSelection selection(String? root) =>
        ConverterSourceSelection(
            rootPath: primary.path,
            supplementalRootPaths: root == null ? const [] : [root],
            logicalProjectNamespace: ConverterId('shared-reference'));
    expect(selection(null).canonicalHash,
        isNot(selection(reference.path).canonicalHash));
    expect(selection(reference.path).canonicalHash,
        isNot(selection('${sandbox.path}/another').canonicalHash));
    expect(
        selection(reference.path).sourceRoots, [primary.path, reference.path]);
  });
}
