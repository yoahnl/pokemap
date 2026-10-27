import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/ports/exclusive_project_directory.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    throw ArgumentError('Expected source project, new destination, receipt.');
  }
  if (arguments.any(
    (path) =>
        !path.startsWith('/') ||
        path.split('/').any((part) => part == '.' || part == '..'),
  )) {
    throw ArgumentError('Expected absolute paths without dot segments.');
  }
  final qaRoot = await Directory(
    '/Users/karim/Library/Caches/AveluneQA/a3d-01-house-tree',
  ).resolveSymbolicLinks();
  final source = await Directory(arguments[0]).resolveSymbolicLinks();
  final destination = Directory(arguments[1]).absolute.path;
  final receiptFile = File(arguments[2]);
  final destinationParent = await Directory(destination).parent
      .resolveSymbolicLinks();
  final receiptParent = await receiptFile.parent.resolveSymbolicLinks();
  final receiptType = await FileSystemEntity.type(
    receiptFile.path,
    followLinks: false,
  );
  if (source != arguments[0] ||
      !source.startsWith('$qaRoot/') ||
      destinationParent != qaRoot ||
      Directory(destination).parent.path != qaRoot ||
      receiptParent != '$qaRoot/evidence' ||
      receiptFile.parent.path != receiptParent ||
      ![
        FileSystemEntityType.file,
        FileSystemEntityType.notFound,
      ].contains(receiptType) ||
      source == destination ||
      await FileSystemEntity.type(destination, followLinks: false) !=
          FileSystemEntityType.notFound) {
    throw ArgumentError(
      'Cloning requires canonical source, new QA child, and QA evidence receipt.',
    );
  }
  final previousAttempts = <Object?>[];
  if (await receiptFile.exists()) {
    final previous = await readJson(receiptFile.path);
    if (previous['source'] != source ||
        previous['destination'] != destination ||
        previous['status'] != 'failed') {
      throw StateError(
        'The evidence file belongs to another or completed clone.',
      );
    }
    previousAttempts.add(previous);
  }
  final receipt = <String, Object?>{
    'source': source,
    'destination': destination,
    'status': 'preparing',
    'method': 'WorkingProjectCatalog.create',
    'previousAttempts': previousAttempts,
    'copiesEditingHistory': false,
    'copiesUserSaves': false,
  };
  Future<void> saveReceipt() async {
    final file = File(arguments[2]);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(receipt),
      flush: true,
    );
  }

  final reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [source],
    fileReader: reader,
  );
  final opener = ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
  );
  OpenedProject? opened;
  try {
    final sourceFiles = await inventory(source);
    final sourceHead = sha256
        .convert(await File('$source/catalog/HEAD.json').readAsBytes())
        .toString();
    receipt['sourceFileCount'] = sourceFiles.length;
    receipt['sourceHeadSha256'] = sourceHead;
    await saveReceipt();
    opened = await opener.openProject(source);
    final snapshot = await ProjectSnapshotLoader(handles: handles)
        .load(opened.projectHandle);
    createExclusiveProjectDirectory(destination);
    var copiedBytes = 0;
    for (final entry in sourceFiles.entries) {
      if (entry.key == 'project.json' || entry.key.startsWith('catalog/')) {
        continue;
      }
      final sourceFile = File('$source/${entry.key}');
      final output = File('$destination/${entry.key}');
      await output.parent.create(recursive: true);
      await sourceFile.copy(output.path);
      if ((await sha256.bind(output.openRead()).first).toString() !=
          entry.value) {
        throw StateError('Copied source differs: ${entry.key}');
      }
      copiedBytes += await output.length();
    }
    receipt['copiedBytes'] = copiedBytes;
    receipt['copiedFileCount'] = sourceFiles.keys
        .where((p) => p != 'project.json' && !p.startsWith('catalog/'))
        .length;
    await saveReceipt();
    final store = await CatalogStorageStore.open(projectRoot: destination);
    final catalog = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'a3d_01_house_tree_pilot',
      project: snapshot.manifest,
    );
    try {
      receipt['catalogRootSha256'] = catalog.root.sha256;
      if (canonical((await catalog.exportProject()).toJson()) !=
          canonical(snapshot.manifest.toJson())) {
        throw StateError('Native clone changed the canonical manifest.');
      }
    } finally {
      await catalog.close();
    }
    final check = ProjectOpenService(
      policy: await WorkspacePolicy.create(
        allowedRootPaths: [destination],
        fileReader: reader,
      ),
      fileReader: reader,
      handles: handles,
    );
    final reopened = await check.openProject(destination);
    try {
      final persisted = await ProjectSnapshotLoader(handles: handles)
          .load(reopened.projectHandle);
      if (canonical(snapshot.manifest.toJson()) !=
              canonical(persisted.manifest.toJson()) ||
          canonical(snapshot.maps.map((map) => map.toJson()).toList()) !=
              canonical(persisted.maps.map((map) => map.toJson()).toList())) {
        throw StateError('Native clone changed canonical manifest or maps.');
      }
      receipt['canonicalManifestAndMapsEqual'] = true;
    } finally {
      check.closeWorkspace(reopened.workspaceHandle);
    }
    final sourceAfter = await inventory(source);
    if (canonical(sourceFiles) != canonical(sourceAfter) ||
        sha256
                .convert(await File('$source/catalog/HEAD.json').readAsBytes())
                .toString() !=
            sourceHead) {
      throw StateError('Source content changed during cloning.');
    }
    receipt['sourceContentUnchanged'] = true;
    receipt['status'] = 'created';
    await saveReceipt();
    stdout.writeln(
      jsonEncode({
        'status': receipt['status'],
        'destination': destination,
        'copiedBytes': copiedBytes,
        'copiedFileCount': receipt['copiedFileCount'],
      }),
    );
  } catch (error) {
    receipt['status'] = 'failed';
    receipt['error'] = error.toString();
    await saveReceipt();
    rethrow;
  } finally {
    if (opened != null) opener.closeWorkspace(opened.workspaceHandle);
  }
}

Future<Map<String, dynamic>> readJson(String path) async =>
    Map<String, dynamic>.from(
      jsonDecode(await File(path).readAsString()) as Map,
    );

Future<Map<String, String>> inventory(String root) async {
  final entries = <String, String>{};
  Future<void> visit(Directory directory) async {
    await for (final entry in directory.list(followLinks: false)) {
      final relative = entry.path.substring(root.length + 1);
      if (entry is Link) throw StateError('Symlink in source: ${entry.path}');
      if (['catalog', '.pokemap', '.avelune-imports'].contains(relative)) {
        continue;
      }
      if (entry is Directory) {
        await visit(entry);
      } else if (entry is File) {
        if (![
              'assets/',
              'data/',
              'maps/',
              'dialogues/',
            ].any(relative.startsWith) &&
            !['project.json', 'project.visual.json'].contains(relative)) {
          throw StateError('Unclassified source file: $relative');
        }
        entries[relative] = (await sha256.bind(entry.openRead()).first)
            .toString();
      }
    }
  }

  await visit(Directory(root));
  return entries;
}

String canonical(Object? value) {
  Object? normalize(Object? item) {
    if (item is Map) {
      return {
        for (final key in item.keys.cast<String>().toList()..sort())
          key: normalize(item[key]),
      };
    }
    if (item is List) return item.map(normalize).toList();
    return item;
  }

  return jsonEncode(normalize(value));
}
