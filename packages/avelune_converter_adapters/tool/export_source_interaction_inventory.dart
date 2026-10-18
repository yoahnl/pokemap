import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) => exportSourceInteractionInventory(args);

Future<void> exportSourceInteractionInventory(List<String> args) async {
  if (args.length < 4 || (args.length - 4).isOdd) {
    throw ArgumentError(
        'Expected absolute source root, fresh external destination, '
        'logical namespace, tool revision; optional repeated --supplemental root '
        'and all of --historical-qualification, --historical-profile, --historical-freeze.');
  }
  final supplemental = <String>[];
  final options = <String, String>{};
  for (var i = 4; i < args.length; i += 2) {
    final key = args[i], value = args[i + 1];
    if (key == '--supplemental') {
      supplemental.add(value);
    } else if ({
          '--historical-qualification',
          '--historical-profile',
          '--historical-freeze'
        }.contains(key) &&
        !options.containsKey(key)) {
      options[key] = value;
    } else {
      throw ArgumentError('Unknown or duplicate option: $key');
    }
  }
  if (options.isNotEmpty && options.length != 3) {
    throw ArgumentError(
        'Historical qualification, profile and freeze must be supplied together.');
  }
  if ([args[0], args[1], ...supplemental].any((p) => !path.isAbsolute(p))) {
    throw ArgumentError(
        'Source, supplemental and destination paths must be absolute.');
  }
  final roots = [
    for (final root in [args[0], ...supplemental])
      await Directory(root).resolveSymbolicLinks()
  ];
  final destination = path.normalize(args[1]);
  void require(bool value, String message) {
    if (!value) throw StateError(message);
  }

  require(
      await FileSystemEntity.type(destination, followLinks: false) ==
          FileSystemEntityType.notFound,
      'Inventory destination must be fresh.');
  var ancestor = path.dirname(destination);
  while (await FileSystemEntity.type(ancestor, followLinks: false) ==
      FileSystemEntityType.notFound) {
    ancestor = path.dirname(ancestor);
  }
  require(
      await FileSystemEntity.type(ancestor, followLinks: false) ==
              FileSystemEntityType.directory &&
          await Directory(ancestor).resolveSymbolicLinks() == ancestor,
      'Inventory destination ancestors must be canonical directories without symlinks.');
  require(
      roots.every((root) =>
          !path.equals(root, destination) && !path.isWithin(root, destination)),
      'Inventory destination must be outside every source root.');
  Future<List<int>?> read(String option) async {
    final selected = options[option];
    return selected == null ? null : File(selected).readAsBytes();
  }

  final qualification = await read('--historical-qualification');
  final profile = await read('--historical-profile');
  final freeze = await read('--historical-freeze');
  final tree = await SupplementedSourceTree.open(roots.first,
      supplementalRootPaths: roots.skip(1).toList());
  late SourceInteractionInventory inventory;
  try {
    final snapshot = await SourceScanner()
        .scan(source: tree, logicalProjectNamespace: ConverterId(args[2]));
    final files =
        await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
    final normalized = await const RmxpSourceNormalizer()
        .normalize(snapshot: snapshot, files: files, includeEventSystem: true);
    final analysis = SourceEventAnalyzer.forProject(normalized,
            profile: SourceEventProfile.forProject(normalized))
        .analyze();
    inventory = SourceInteractionInventory.build(
      source: normalized,
      analysis: analysis,
      toolRevision: args[3],
      historicalQualificationBytes: qualification,
      historicalProfileBytes: profile,
      historicalFreezeBytes: freeze,
    );
    await files.verifyUnchanged();
  } finally {
    await tree.close();
  }
  require(
      await FileSystemEntity.type(destination, followLinks: false) ==
          FileSystemEntityType.notFound,
      'Inventory destination changed while scanning.');
  final directory = await Directory(destination).create(recursive: true);
  require(await directory.resolveSymbolicLinks() == destination,
      'Inventory destination changed during creation.');
  final outputs = <String, String>{
    'inventory.json': jsonEncode(inventory.toJson()),
    'events.csv': inventory.eventsCsv(),
    'pages.csv': inventory.pagesCsv(),
    'summary.json':
        const JsonEncoder.withIndent('  ').convert(inventory.summaryJson()),
  };
  for (final output in outputs.entries) {
    final file = File(path.join(destination, output.key));
    await file.create(exclusive: true);
    await file.writeAsString(output.value, flush: true);
  }
  stdout.writeln(jsonEncode({
    'kind': 'sourceInteractionInventoryExport',
    'destination': destination,
    'eventCount': inventory.summaryJson()['eventCount'],
    'pageCount': inventory.summaryJson()['pageCount'],
    'globalPlayabilityCertified': false,
    'sourceScriptsExecuted': 0,
    'aiSourceInferenceCalls': 0
  }));
}
