import 'dart:io';

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/material.dart';

import 'src/render_host.dart';

final _boundaryKey = GlobalKey();
final _content = ValueNotifier<Widget>(const SizedBox.shrink());

Future<void> main() async {
  AveluneWidgetsFlutterBinding.ensureInitialized();
  final errors = <String>[];
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
    stderr.writeln(details);
  };
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ColoredBox(
      color: const Color(0xff242b31),
      child: ValueListenableBuilder<Widget>(
        valueListenable: _content,
        builder: (_, value, _) => RepaintBoundary(key: _boundaryKey, child: value),
      ),
    ),
  ));
  final renderer = SpatialMapRenderer(boundaryKey: _boundaryKey, content: _content, errors: errors);
  await RenderHost(renderer.render, scan: renderer.scan).serve(stdin, stdout);
  exit(0);
}
