import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

final class SaveDiskTrace {
  SaveDiskTrace(this.root);

  final String root;
  bool armed = false;
  final _rows = <String, Map<String, Object>>{};

  void arm() {
    _rows.clear();
    armed = true;
  }

  void record(String path, String operation, [int bytes = 0]) {
    if (!armed || !path.startsWith('$root/')) return;
    final relative = path.substring(root.length + 1);
    final key = '$relative:$operation';
    final row = _rows.putIfAbsent(
      key,
      () => {'path': relative, 'operation': operation, 'calls': 0, 'bytes': 0},
    );
    row['calls'] = (row['calls']! as int) + 1;
    row['bytes'] = (row['bytes']! as int) + bytes;
  }

  Map<String, Object> snapshot() => {
    'root': root,
    'coverage': 'Dart File and Directory APIs in the UI isolate, including data reads, completed writes and directory listings',
    'rows': _rows.values.toList(),
  };

  Future<void> run(Future<void> Function() body) async {
    IOOverrides.global = _TraceOverrides(this);
    await body();
  }
}

final class _TraceOverrides extends IOOverrides {
  _TraceOverrides(this.trace);
  final SaveDiskTrace trace;
  @override
  File createFile(String path) {
    final file = super.createFile(path);
    return p.absolute(file.path).startsWith('${trace.root}/')
        ? _TraceFile(file, trace)
        : file;
  }

  @override
  Directory createDirectory(String path) {
    final directory = super.createDirectory(path);
    return p.absolute(directory.path) == trace.root ||
            p.absolute(directory.path).startsWith('${trace.root}/')
        ? _TraceDirectory(directory, trace)
        : directory;
  }
}

final class _TraceFile implements File {
  _TraceFile(this.file, this.trace);
  final File file;
  final SaveDiskTrace trace;
  void note(String operation, [int bytes = 0]) =>
      trace.record(p.absolute(file.path), operation, bytes);
  @override
  String get path => file.path;
  @override
  Uri get uri => file.uri;
  @override
  File get absolute => File(p.absolute(path));
  @override
  Directory get parent => file.parent;
  @override
  Future<bool> exists() {
    note('exists');
    return file.exists();
  }

  @override
  Future<FileStat> stat() {
    note('stat');
    return file.stat();
  }

  @override
  Future<int> length() {
    note('length');
    return file.length();
  }

  @override
  Future<String> resolveSymbolicLinks() => file.resolveSymbolicLinks();
  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    note('create');
    await file.create(recursive: recursive, exclusive: exclusive);
    return this;
  }

  @override
  Future<File> delete({bool recursive = false}) async {
    note('delete');
    await file.delete(recursive: recursive);
    return this;
  }

  @override
  Future<File> rename(String newPath) async {
    note('rename');
    return _TraceFile(await file.rename(newPath), trace);
  }

  @override
  Future<File> copy(String newPath) async {
    note('copy', await file.length());
    return _TraceFile(await file.copy(newPath), trace);
  }

  @override
  Future<Uint8List> readAsBytes() async {
    final value = await file.readAsBytes();
    note('read', value.length);
    return value;
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    final value = await file.readAsString(encoding: encoding);
    note('read', encoding.encode(value).length);
    return value;
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    note('openRead');
    return file.openRead(start, end).map((chunk) {
      note('read', chunk.length);
      return chunk;
    });
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    note('open:${mode.toString()}');
    return _TraceRandomFile(await file.open(mode: mode), this);
  }

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    await file.writeAsBytes(bytes, mode: mode, flush: flush);
    note('write', bytes.length);
    return this;
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    await file.writeAsString(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
    note('write', encoding.encode(contents).length);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Untraced File API: ${invocation.memberName}');
}

final class _TraceRandomFile implements RandomAccessFile {
  _TraceRandomFile(this.file, this.owner);
  final RandomAccessFile file;
  final _TraceFile owner;
  @override
  String get path => file.path;
  @override
  Future<void> close() => file.close();
  @override
  Future<RandomAccessFile> flush() async {
    await file.flush();
    owner.note('flush');
    return this;
  }

  @override
  Future<int> length() => file.length();
  @override
  Future<int> position() => file.position();
  @override
  Future<RandomAccessFile> setPosition(int position) async {
    await file.setPosition(position);
    return this;
  }

  @override
  Future<RandomAccessFile> truncate(int length) async {
    await file.truncate(length);
    owner.note('truncate', length);
    return this;
  }

  @override
  Future<Uint8List> read(int count) async {
    final bytes = await file.read(count);
    owner.note('read', bytes.length);
    return bytes;
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) async {
    final count = await file.readInto(buffer, start, end);
    owner.note('read', count);
    return count;
  }

  @override
  Future<int> readByte() async {
    final byte = await file.readByte();
    owner.note('read', byte < 0 ? 0 : 1);
    return byte;
  }

  @override
  Future<RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    await file.writeFrom(buffer, start, end);
    owner.note('write', (end ?? buffer.length) - start);
    return this;
  }

  @override
  Future<RandomAccessFile> writeString(
    String string, {
    Encoding encoding = utf8,
  }) async {
    await file.writeString(string, encoding: encoding);
    owner.note('write', encoding.encode(string).length);
    return this;
  }

  @override
  Future<RandomAccessFile> writeByte(int value) async {
    await file.writeByte(value);
    owner.note('write', 1);
    return this;
  }

  @override
  Future<RandomAccessFile> lock([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) async {
    await file.lock(mode, start, end);
    return this;
  }

  @override
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) async {
    await file.unlock(start, end);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Untraced RandomAccessFile API: ${invocation.memberName}',
  );
}

final class _TraceDirectory implements Directory {
  _TraceDirectory(this.directory, this.trace);
  final Directory directory;
  final SaveDiskTrace trace;
  @override
  String get path => directory.path;
  @override
  Uri get uri => directory.uri;
  @override
  Directory get absolute => Directory(p.absolute(path));
  @override
  Directory get parent => directory.parent;
  @override
  Future<bool> exists() => directory.exists();
  @override
  Future<FileStat> stat() => directory.stat();
  @override
  Future<String> resolveSymbolicLinks() => directory.resolveSymbolicLinks();
  @override
  Future<Directory> create({bool recursive = false}) async {
    await directory.create(recursive: recursive);
    return this;
  }

  @override
  Future<Directory> delete({bool recursive = false}) async {
    await directory.delete(recursive: recursive);
    return this;
  }

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) {
    trace.record('$path/', recursive ? 'listRecursive' : 'list');
    return directory
        .list(recursive: recursive, followLinks: followLinks)
        .map(
          (entity) => switch (entity) {
            File file => _TraceFile(file, trace),
            Directory child => _TraceDirectory(child, trace),
            _ => entity,
          },
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Untraced Directory API: ${invocation.memberName}',
  );
}
