import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart'
    show validateProjectRelativePath;
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.length == 1 && arguments.single == '--help') {
      stdout.writeln('dart run tool/import_project_item_icons.dart '
          '--project <absolute-project-directory> '
          '[--source <absolute-pack-directory>] [--item <project-item-id>]');
      return;
    }
    final options = <String, String>{};
    final items = <String>[];
    for (var index = 0; index < arguments.length; index += 2) {
      if (index + 1 >= arguments.length ||
          !const {'--project', '--source', '--item'}
              .contains(arguments[index])) {
        throw const FormatException('Expected --project, --source or --item.');
      }
      final key = arguments[index];
      final value = arguments[index + 1];
      if (value.trim().isEmpty || value.startsWith('--')) {
        throw FormatException('Missing value for $key.');
      }
      if (key == '--item') {
        items.add(value);
      } else if (options.containsKey(key)) {
        throw FormatException('Repeated option: $key.');
      } else {
        options[key] = value;
      }
    }
    final project = options['--project'];
    if (project == null) {
      throw const FormatException('--project is required.');
    }
    final source = options['--source'] ??
        p.join(File.fromUri(Platform.script).parent.parent.parent.parent.path,
            'apps', 'avelune_studio', 'assets', 'pokemon', 'item_icons');
    stdout.writeln(jsonEncode(await provisionProjectItemIcons(
      projectPath: project,
      loadPack: () => _loadPack(source),
      itemIds: items.isEmpty ? null : items,
    )));
  } on ProjectItemIconProvisioningPartialFailure catch (error) {
    stderr.writeln(jsonEncode(error.toJson()));
    exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('Item icon provisioning failed: $error');
    exitCode = 1;
  }
}

Future<ProjectItemIconPack> _loadPack(String sourcePath) async {
  final root = await _directory(sourcePath);
  return ProjectItemIconPack(
    manifestBytes:
        await (await _projectFile(root, 'manifest.json')).readAsBytes(),
    archiveBytes: await (await _projectFile(root, 'icons.zip')).readAsBytes(),
  );
}

Future<String> _directory(String path) async {
  if (!p.isAbsolute(path) ||
      path.contains('\u0000') ||
      path.split(RegExp(r'[\\/]')).contains('..') ||
      await FileSystemEntity.type(path, followLinks: false) !=
          FileSystemEntityType.directory) {
    throw const FormatException(
        'Expected an absolute directory without traversal or symlinks.');
  }
  return Directory(path).resolveSymbolicLinks();
}

Future<File> _projectFile(String root, String relative) async {
  var current = root;
  final segments = validateProjectRelativePath(relative);
  for (var index = 0; index < segments.length; index++) {
    current = p.join(current, segments[index]);
    final type = await FileSystemEntity.type(current, followLinks: false);
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type !=
                (index == segments.length - 1
                    ? FileSystemEntityType.file
                    : FileSystemEntityType.directory))) {
      throw const FormatException('Unsafe project or source file path.');
    }
  }
  return File(current);
}
