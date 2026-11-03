import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  const root =
      '/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Library/Caches/AveluneQA';
  if (args.length != 1 ||
      p.normalize(args.single) != args.single ||
      p.dirname(args.single) != root ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$')
          .hasMatch(p.basename(args.single))) {
    throw ArgumentError('Provide one canonical atlas task directory.');
  }
  final task = Directory(args.single);
  if (await FileSystemEntity.type(task.path, followLinks: false) !=
          FileSystemEntityType.directory ||
      await task.resolveSymbolicLinks() != task.path) {
    throw StateError('The atlas task directory must already exist.');
  }
  final captures = Directory(p.join(task.path, 'captures'));
  if (await FileSystemEntity.type(captures.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw StateError('The atlas capture directory already exists.');
  }
  await captures.create();
  if (await captures.resolveSymbolicLinks() != captures.path) {
    throw StateError('The atlas capture directory must be canonical.');
  }
  final marker = File(p.join(captures.path, '.avelune-studio-capture-owner'));
  if (await FileSystemEntity.type(marker.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw StateError('The atlas capture marker already exists.');
  }
  await marker.writeAsString('avelune-studio-capture@1', flush: true);
  stdout.writeln(captures.path);
}
