import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Capture attendue');
    exitCode = 1;
    return;
  }
  try {
    final decoded = image.decodeImage(File(arguments.single).readAsBytesSync());
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      throw const FormatException('Capture illisible');
    }
    stdout.writeln(
      jsonEncode({'width': decoded.width, 'height': decoded.height}),
    );
  } catch (_) {
    stderr.writeln('Capture illisible');
    exitCode = 1;
  }
}
