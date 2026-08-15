import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../ui/canvas/cinematics/presentation/presentation_studio_shell.dart';

typedef PresentationStudioSupportDirectory = Future<Directory> Function();

final class FilePresentationStudioLayoutStore
    implements PresentationStudioLayoutStore {
  FilePresentationStudioLayoutStore({
    PresentationStudioSupportDirectory? supportDirectory,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static const _fileName = 'presentation_studio_layout_v1.json';

  final PresentationStudioSupportDirectory _supportDirectory;
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<PresentationStudioLayout?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
        return null;
      }
      final inspectorWidth = decoded['inspectorWidth'];
      final timelineHeight = decoded['timelineHeight'];
      if (inspectorWidth is! num || timelineHeight is! num) return null;
      final inspector = inspectorWidth.toDouble();
      final timeline = timelineHeight.toDouble();
      if (!inspector.isFinite ||
          !timeline.isFinite ||
          inspector <= 0 ||
          timeline <= 0) {
        return null;
      }
      return PresentationStudioLayout(
        inspectorWidth: inspector,
        timelineHeight: timeline,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(PresentationStudioLayout layout) {
    final write = _writeTail.then((_) => _write(layout));
    _writeTail = write.catchError((_) {});
    return write;
  }

  Future<void> _write(PresentationStudioLayout layout) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temporary = File(
      '${file.path}.${DateTime.now().toUtc().microsecondsSinceEpoch}.tmp',
    );
    await temporary.writeAsString(
      jsonEncode(<String, Object>{
        'schemaVersion': 1,
        'inspectorWidth': layout.inspectorWidth,
        'timelineHeight': layout.timelineHeight,
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<File> _file() async {
    final directory = await _supportDirectory();
    return File.fromUri(directory.uri.resolve(_fileName));
  }
}
