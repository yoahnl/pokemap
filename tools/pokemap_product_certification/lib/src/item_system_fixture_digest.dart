import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

Future<String> computeItemSystemFixtureSha256(Directory root) async {
  if (!await root.exists()) {
    throw ArgumentError.value(root.path, 'root', 'does not exist');
  }
  final files = await root
      .list(recursive: true, followLinks: false)
      .where((entity) => entity is File && p.extension(entity.path) == '.json')
      .cast<File>()
      .toList();
  files.sort((left, right) {
    final leftPath = p.relative(left.path, from: root.path);
    final rightPath = p.relative(right.path, from: root.path);
    return leftPath.compareTo(rightPath);
  });
  if (files.isEmpty) {
    throw ArgumentError.value(root.path, 'root', 'contains no fixture files');
  }
  final input = BytesBuilder(copy: false);
  for (final file in files) {
    input
      ..add(utf8.encode(p.relative(file.path, from: root.path)))
      ..addByte(0)
      ..add(await file.readAsBytes())
      ..addByte(0);
  }
  return sha256.convert(input.takeBytes()).toString();
}
