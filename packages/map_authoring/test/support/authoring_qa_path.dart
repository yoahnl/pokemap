import 'dart:io';

import 'package:path/path.dart' as p;

String authoringQaPath(String relativePath) {
  final configured = Platform.environment['AVELUNE_QA_ROOT'];
  final userDirectory = Platform.environment['HOME'];
  final fallback = Platform.isMacOS && userDirectory != null
      ? p.join(userDirectory, 'Library', 'Caches', 'AveluneQA')
      : p.join(Directory.systemTemp.path, 'AveluneQA');
  return p.join(configured ?? fallback, relativePath);
}
