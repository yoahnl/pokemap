import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

final class PreviewReads {
  var indexReads = 0, atmosphereReads = 0, rasterReads = 0, bytes = 0;
  (int, int, int, int) get snapshot =>
      (indexReads, atmosphereReads, rasterReads, bytes);
  void record(String path, int length) {
    if (path.endsWith('.pokemap-assets.json')) {
      indexReads++;
    } else if (path.endsWith('.atmosphere.json')) {
      atmosphereReads++;
    } else if (path.endsWith('.png')) {
      rasterReads++;
    } else {
      return;
    }
    bytes += length;
  }
}

final class PreviewCountingFile implements File {
  PreviewCountingFile(this.file, this.reads);
  final File file;
  final PreviewReads reads;
  @override
  String get path => file.path;
  @override
  Uri get uri => file.uri;
  @override
  File get absolute => PreviewCountingFile(file.absolute, reads);
  @override
  Directory get parent => file.parent;
  @override
  bool get isAbsolute => file.isAbsolute;
  @override
  Future<bool> exists() => file.exists();
  @override
  bool existsSync() => file.existsSync();
  @override
  Future<FileStat> stat() => file.stat();
  @override
  FileStat statSync() => file.statSync();
  @override
  Future<int> length() => file.length();
  @override
  int lengthSync() => file.lengthSync();
  @override
  Future<String> resolveSymbolicLinks() => file.resolveSymbolicLinks();
  @override
  String resolveSymbolicLinksSync() => file.resolveSymbolicLinksSync();
  @override
  Future<Uint8List> readAsBytes() async {
    final bytes = await file.readAsBytes();
    reads.record(path, bytes.length);
    return bytes;
  }

  @override
  Uint8List readAsBytesSync() {
    final bytes = file.readAsBytesSync();
    reads.record(path, bytes.length);
    return bytes;
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    final text = await file.readAsString(encoding: encoding);
    reads.record(path, encoding.encode(text).length);
    return text;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
