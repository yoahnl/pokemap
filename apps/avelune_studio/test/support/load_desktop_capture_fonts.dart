import 'dart:io';

import 'package:flutter/services.dart';

var _loaded = false;

Future<void> loadDesktopCaptureFonts() async {
  if (_loaded || (Platform.environment['AVELUNE_CAPTURE_DIR'] ?? '').isEmpty) {
    return;
  }
  final helvetica = File('/System/Library/Fonts/HelveticaNeue.ttc');
  final candidates = <File>[
    if (Platform.environment['FLUTTER_ROOT'] case final String root)
      File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    File(
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ),
  ];
  var directory = File(Platform.resolvedExecutable).parent;
  for (var level = 0; level < 8; level++) {
    candidates.add(
      File(
        '${directory.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
    directory = directory.parent;
  }
  File? material;
  for (final candidate in candidates) {
    if (await candidate.exists()) {
      material = candidate;
      break;
    }
  }
  if (!await helvetica.exists() || material == null) {
    throw StateError(
      'Les captures desktop exigent Helvetica Neue et MaterialIcons réels.',
    );
  }
  final textLoader = FontLoader('Helvetica Neue')
    ..addFont(helvetica.readAsBytes().then(ByteData.sublistView));
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(material.readAsBytes().then(ByteData.sublistView));
  await textLoader.load();
  await iconLoader.load();
  for (final family in ['Roboto', 'monospace']) {
    final loader = FontLoader(family)
      ..addFont(helvetica.readAsBytes().then(ByteData.sublistView));
    await loader.load();
  }
  _loaded = true;
}
