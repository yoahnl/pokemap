import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  try {
    importBattleTransitionAssets(arguments);
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 65;
  }
}

void importBattleTransitionAssets(List<String> arguments) {
  if (arguments.length != 6 || arguments[0] != '--source-root' ||
      arguments[2] != '--catalogue' || arguments[4] != '--output-root' ||
      [arguments[1], arguments[3], arguments[5]].any((value) => !p.isAbsolute(value))) {
    throw const FormatException('Usage: --source-root <absolute directory> '
        '--catalogue <absolute JSON file> --output-root <new absolute directory>');
  }
  final sourceRoot = Directory(arguments[1]).resolveSymbolicLinksSync();
  final catalogue = File(arguments[3]);
  if (catalogue.lengthSync() > 2 * 1024 * 1024) {
    throw const FormatException('Transition catalogue exceeds 2 MiB.');
  }
  final document = jsonDecode(catalogue.readAsStringSync());
  if (document is! Map<String, dynamic> || document['schemaVersion'] != 1 ||
      document['definitions'] is! List || document['assets'] is! List) {
    throw const FormatException('Invalid transition catalogue.');
  }
  final definitions = (document['definitions'] as List)
      .map(BattleTransitionDefinition.fromJson).toList();
  ProjectBattleTransitionConfig(definitions: definitions).validate();
  final entries = document['assets'] as List;
  if (entries.isEmpty || entries.length > 256) {
    throw const FormatException('Expected between 1 and 256 transition assets.');
  }
  final pending = <String, List<int>>{};
  final references = <String>{};
  var totalBytes = 0;
  for (final entry in entries) {
    if (entry is! Map<String, dynamic> || entry.length != 3 ||
        !entry.keys.toSet().containsAll({'reference', 'sourceRelativePath', 'sha256'})) {
      throw const FormatException('Invalid transition asset entry.');
    }
    final reference = entry['reference'];
    validateBattleTransitionAssetReference(reference);
    final name = (reference as String).substring(reference.indexOf(':') + 1);
    final relative = entry['sourceRelativePath'];
    if (relative is! String || relative.isEmpty || p.isAbsolute(relative) ||
        relative.contains(RegExp(r'[%\\:\x00]')) ||
        relative.split('/').any((part) => part.isEmpty || part == '.' || part == '..') ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(entry['sha256'] is String ? entry['sha256'] as String : '')) {
      throw const FormatException('Invalid transition asset source or digest.');
    }
    if (!references.add(reference) || pending.containsKey(name)) {
      throw const FormatException('Duplicate transition asset destination.');
    }
    final file = File(p.join(sourceRoot, relative));
    if (FileSystemEntity.typeSync(file.path, followLinks: false) != FileSystemEntityType.file) {
      throw const FormatException('Transition assets must be regular source files.');
    }
    final resolved = file.resolveSymbolicLinksSync();
    if (!p.isWithin(sourceRoot, resolved) || file.lengthSync() > 32 * 1024 * 1024) {
      throw const FormatException('Transition asset exceeds its source boundary or byte budget.');
    }
    final bytes = file.readAsBytesSync();
    totalBytes += bytes.length;
    if (totalBytes > 256 * 1024 * 1024 ||
        sha256.convert(bytes).toString() != entry['sha256'] || image.decodePng(bytes) == null) {
      throw const FormatException('Transition asset content or digest is invalid.');
    }
    pending[name] = bytes;
  }
  for (final definition in definitions) {
    for (final phase in definition.phases) {
      final reference = phase.parameters['sheetName'] ?? phase.parameters['textureName'];
      if (reference != null && !references.contains(reference)) {
        throw const FormatException('Transition catalogue references an undeclared asset.');
      }
    }
  }
  final requested = p.normalize(arguments[5]);
  final parent = Directory(p.dirname(requested)).resolveSymbolicLinksSync();
  final output = Directory(p.join(parent, p.basename(requested)));
  if (FileSystemEntity.typeSync(output.path, followLinks: false) != FileSystemEntityType.notFound ||
      p.equals(sourceRoot, output.path) || p.isWithin(sourceRoot, output.path) ||
      p.isWithin(output.path, sourceRoot)) {
    throw const FormatException('Output must be a new directory outside the source tree.');
  }
  final staging = Directory(parent).createTempSync('.transition-assets-');
  try {
    for (final entry in pending.entries) {
      final target = File(p.join(staging.path, entry.key));
      target.parent.createSync(recursive: true);
      target.writeAsBytesSync(entry.value, flush: true);
    }
    File(p.join(staging.path, 'import-receipt.json')).writeAsStringSync(jsonEncode({
      'schemaVersion': 1,
      'catalogueSha256': sha256.convert(catalogue.readAsBytesSync()).toString(),
      'assets': entries,
      'bytes': totalBytes,
    }), flush: true);
    staging.renameSync(output.path);
  } finally {
    if (staging.existsSync()) staging.deleteSync(recursive: true);
  }
  stdout.writeln('${pending.length} transition assets imported to ${output.path}');
}
