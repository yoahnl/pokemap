import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:ffi/ffi.dart';

final class MacOsSourceTree implements SourceTreePort {
  MacOsSourceTree._(this.rootPath, this._rootFd, this._rootIdentity);

  final String rootPath;
  final int _rootFd;
  final String _rootIdentity;
  final Set<String> _excludedPaths = {};
  final Expando<bool> _readableNodes = Expando<bool>();
  bool _closed = false;

  static Future<MacOsSourceTree> open(String rootPath) async {
    if (!Platform.isMacOS ||
        !const [Abi.macosArm64, Abi.macosX64].contains(Abi.current())) {
      throw ContractError('source.platform_unsupported', r'$',
          'Source filesystem access requires macOS arm64 or x64.');
    }
    if (rootPath.contains('\u0000')) {
      throw ContractError('source.root_invalid', r'$', 'Invalid source root.');
    }
    final String canonical;
    try {
      canonical = await Directory(rootPath).resolveSymbolicLinks();
    } on FileSystemException {
      throw ContractError('source.root_invalid', r'$',
          'The selected source directory cannot be resolved.');
    }
    final fd = _openRootDirectory(canonical);
    try {
      final stat = _statFd(fd, '');
      if (stat.kind != SourceNodeKind.directory) {
        throw ContractError('source.root_invalid', r'$',
            'The selected source is not a directory.');
      }
      return MacOsSourceTree._(canonical, fd, stat.identity);
    } catch (_) {
      _native.close(fd);
      rethrow;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _native.close(_rootFd);
  }

  @override
  Stream<SourceNode> walk({
    required SourceScanPolicy policy,
    required ScanCancellation cancellation,
  }) async* {
    _check(cancellation);
    final limits = policy.limits;
    if (limits.maxEntries <= 0 ||
        limits.maxDepth < 0 ||
        limits.maxFileBytes < 0 ||
        limits.maxTotalBytes < 0 ||
        limits.maxPathCodeUnits <= 0 ||
        limits.maxTotalPathCodeUnits < 0) {
      throw ContractError(
          'source.policy_invalid', r'$', 'Invalid scan limits.');
    }
    final budget = _WalkBudget();
    final fd = _openDirectory(_rootFd, '.', '');
    try {
      if (_statFd(fd, '').identity != _rootIdentity) {
        throw _changed('');
      }
      yield* _walkDirectory(
          fd, '', 0, _rootIdentity, policy, cancellation, budget);
    } finally {
      _native.close(fd);
    }
  }

  Stream<SourceNode> _walkDirectory(
    int fd,
    String parentPath,
    int depth,
    String ancestry,
    SourceScanPolicy policy,
    ScanCancellation cancellation,
    _WalkBudget budget,
  ) async* {
    final listingFd = _openDirectory(fd, '.', parentPath);
    final directory = _native.fdopendir(listingFd);
    if (directory == nullptr) {
      _native.close(listingFd);
      throw _ioError(parentPath);
    }
    try {
      while (true) {
        _check(cancellation);
        _native.errno().value = 0;
        final entry = _native.readdir(directory);
        if (entry == nullptr) {
          if (_native.errno().value != 0) throw _ioError(parentPath);
          break;
        }
        final header = ByteData.sublistView(entry.asTypedList(21));
        final length = header.getUint16(18, Endian.host);
        final recordLength = header.getUint16(16, Endian.host);
        if (length <= 0 || length >= 1024 || recordLength <= 21 + length) {
          throw _ioError(parentPath);
        }
        final String name;
        try {
          name = utf8.decode((entry + 21).asTypedList(length));
        } on FormatException {
          throw ContractError('source.path_invalid', parentPath,
              'A source filename is not valid UTF-8.');
        }
        if (name == '.' || name == '..') continue;
        final path = parentPath.isEmpty ? name : '$parentPath/$name';
        _validatePath(path, maxCodeUnits: policy.limits.maxPathCodeUnits);
        budget.entries++;
        if (budget.entries > policy.limits.maxEntries) {
          throw ContractError(
              'source.entry_limit', path, 'Source entry limit exceeded.');
        }
        budget.totalPathCodeUnits += path.length;
        if (budget.totalPathCodeUnits > policy.limits.maxTotalPathCodeUnits) {
          throw ContractError('source.total_path_limit', path,
              'Source total path length limit exceeded.');
        }
        if (depth + 1 > policy.limits.maxDepth) {
          throw ContractError(
              'source.depth_limit', path, 'Source depth limit exceeded.');
        }
        final stat = _statAt(fd, name, path);
        final excluded = policy.isExcluded(path);
        if (excluded) _excludedPaths.add(path);
        if (!excluded && stat.kind == SourceNodeKind.file) {
          if (stat.byteLength > policy.limits.maxFileBytes) {
            throw ContractError(
                'source.file_limit', path, 'Source file size limit exceeded.');
          }
          budget.totalBytes += stat.byteLength;
          if (budget.totalBytes > policy.limits.maxTotalBytes) {
            throw ContractError('source.total_bytes_limit', path,
                'Source total byte limit exceeded.');
          }
        }
        final node = SourceNode(
            relativePath: path,
            kind: stat.kind,
            byteLength: stat.byteLength,
            token: _sourceToken(path, ancestry, stat));
        if (!excluded && stat.kind == SourceNodeKind.file) {
          _readableNodes[node] = true;
        }
        yield node;
        if (excluded || stat.kind != SourceNodeKind.directory) continue;
        _check(cancellation);
        final child = _openDirectory(fd, name, path);
        try {
          if (_statFd(child, path).token != stat.token) throw _changed(path);
          yield* _walkDirectory(child, path, depth + 1,
              '$ancestry|${stat.identity}', policy, cancellation, budget);
        } finally {
          _native.close(child);
        }
      }
    } finally {
      _native.closedir(directory);
    }
  }

  @override
  Stream<List<int>> read(
    SourceNode node, {
    required int maxBytes,
    required ScanCancellation cancellation,
  }) async* {
    _check(cancellation);
    _validatePath(node.relativePath);
    if (node.kind != SourceNodeKind.file) {
      throw ContractError('source.node_not_file', node.relativePath,
          'Only inventoried regular files can be read.');
    }
    if (_excludedPaths.any((path) =>
        node.relativePath == path || node.relativePath.startsWith('$path/'))) {
      throw ContractError('source.excluded', node.relativePath,
          'Excluded source paths cannot be read.');
    }
    if (_readableNodes[node] != true) {
      throw ContractError('source.node_unissued', node.relativePath,
          'The source file was not authorized by this source tree instance.');
    }
    if (maxBytes < 0 || node.byteLength < 0 || node.byteLength > maxBytes) {
      throw ContractError('source.file_limit', node.relativePath,
          'Source file size limit exceeded.');
    }
    var directory = _openDirectory(_rootFd, '.', '');
    int? file;
    Pointer<Uint8>? buffer;
    try {
      var ancestry = _statFd(directory, '').identity;
      if (ancestry != _rootIdentity) throw _changed(node.relativePath);
      final segments = node.relativePath.split('/');
      for (var i = 0; i < segments.length - 1; i++) {
        _check(cancellation);
        final child = _openDirectory(directory, segments[i], node.relativePath);
        _native.close(directory);
        directory = child;
        ancestry =
            '$ancestry|${_statFd(directory, node.relativePath).identity}';
      }
      final before = _statAt(directory, segments.last, node.relativePath);
      if (before.kind != SourceNodeKind.file ||
          before.byteLength != node.byteLength ||
          _sourceToken(node.relativePath, ancestry, before) != node.token) {
        throw _changed(node.relativePath);
      }
      final opened = _withPath(
          segments.last, (path) => _native.openat(directory, path, _fileFlags));
      if (opened < 0) throw _changed(node.relativePath);
      file = opened;
      if (_statFd(file, node.relativePath).token != before.token) {
        throw _changed(node.relativePath);
      }
      buffer = calloc<Uint8>(_chunkBytes);
      var consumed = 0;
      while (true) {
        _check(cancellation);
        if (_statFd(file, node.relativePath).token != before.token) {
          throw _changed(node.relativePath);
        }
        final length = _native.read(file, buffer, _chunkBytes);
        if (length < 0) {
          if (_native.errno().value == 4) continue;
          throw _ioError(node.relativePath);
        }
        if (length == 0) break;
        consumed += length;
        if (consumed > maxBytes || consumed > node.byteLength) {
          throw _changed(node.relativePath);
        }
        if (_statFd(file, node.relativePath).token != before.token) {
          throw _changed(node.relativePath);
        }
        yield Uint8List.fromList(buffer.asTypedList(length));
      }
      if (consumed != node.byteLength ||
          _statFd(file, node.relativePath).token != before.token ||
          _statAt(directory, segments.last, node.relativePath).token !=
              before.token) {
        throw _changed(node.relativePath);
      }
    } finally {
      if (buffer != null) calloc.free(buffer);
      if (file != null) _native.close(file);
      _native.close(directory);
    }
  }

  void _check(ScanCancellation cancellation) {
    cancellation.check();
    if (_closed) {
      throw ContractError('source.closed', r'$', 'The source tree is closed.');
    }
  }
}

const _directoryFlags = 0x00100000 | 0x00000100 | 0x01000000;
const _rootDirectoryFlags = 0x00100000 | 0x01000000 | 0x20000000;
const _fileFlags = 0x00000100 | 0x01000000 | 0x00000004;
const _chunkBytes = 65536;
final _native = _MacOsNative();

String _sourceToken(String path, String ancestry, _MacStat stat) =>
    jsonEncode([path, ancestry, stat.token]);

int _openRootDirectory(String canonical) {
  final fd =
      _withPath(canonical, (path) => _native.open(path, _rootDirectoryFlags));
  if (fd < 0) {
    throw ContractError('source.root_invalid', r'$',
        'The selected source directory cannot be opened safely.');
  }
  return fd;
}

int _openDirectory(int parent, String name, String path) {
  final fd = _withPath(
      name, (value) => _native.openat(parent, value, _directoryFlags));
  if (fd < 0) throw _ioError(path);
  return fd;
}

T _withPath<T>(String value, T Function(Pointer<Utf8>) operation) {
  final pointer = value.toNativeUtf8();
  try {
    return operation(pointer);
  } finally {
    calloc.free(pointer);
  }
}

void _validatePath(String path, {int maxCodeUnits = 4096}) {
  if (path.isEmpty ||
      path.length > maxCodeUnits ||
      path.startsWith('/') ||
      path.contains('\u0000') ||
      path.contains('\\') ||
      path
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw ContractError('source.path_invalid', path,
        'Expected a bounded relative source path.');
  }
  validateSourceRelativePath(path, maxCodeUnits: maxCodeUnits);
}

_MacStat _statFd(int fd, String path) =>
    _withStat(path, (buffer) => _native.fstat(fd, buffer));

_MacStat _statAt(int fd, String name, String path) => _withPath(
    name,
    (pointer) => _withStat(
        path, (buffer) => _native.fstatat(fd, pointer, buffer, 0x0020)));

_MacStat _withStat(String path, int Function(Pointer<Uint8>) operation) {
  final buffer = calloc<Uint8>(144);
  try {
    if (operation(buffer) != 0) throw _ioError(path);
    final bytes = ByteData.sublistView(buffer.asTypedList(144));
    final mode = bytes.getUint16(4, Endian.host);
    final kind = switch (mode & 0xf000) {
      0x8000 => SourceNodeKind.file,
      0x4000 => SourceNodeKind.directory,
      0xa000 => SourceNodeKind.link,
      _ => SourceNodeKind.special,
    };
    final identity = '${bytes.getInt32(0, Endian.host)}:'
        '${bytes.getUint64(8, Endian.host)}:'
        '${bytes.getUint32(120, Endian.host)}:$mode';
    final length = bytes.getInt64(96, Endian.host);
    final token = '$identity:${bytes.getUint16(6, Endian.host)}:$length:'
        '${bytes.getInt64(48, Endian.host)}:${bytes.getInt64(56, Endian.host)}:'
        '${bytes.getInt64(64, Endian.host)}:${bytes.getInt64(72, Endian.host)}:'
        '${bytes.getInt64(80, Endian.host)}:${bytes.getInt64(88, Endian.host)}';
    return _MacStat(
        kind, kind == SourceNodeKind.file ? length : 0, identity, token);
  } finally {
    calloc.free(buffer);
  }
}

ContractError _ioError(String path) => ContractError('source.io_error', path,
    'Source filesystem access failed (errno ${_native.errno().value}).');

ContractError _changed(String path) => ContractError('source.changed', path,
    'Source identity or contents changed during the scan.');

final class _WalkBudget {
  int entries = 0;
  int totalBytes = 0;
  int totalPathCodeUnits = 0;
}

final class _MacStat {
  const _MacStat(this.kind, this.byteLength, this.identity, this.token);
  final SourceNodeKind kind;
  final int byteLength;
  final String identity;
  final String token;
}

final class _MacOsNative {
  _MacOsNative() {
    final library = DynamicLibrary.open('/usr/lib/libSystem.B.dylib');
    final suffix = Abi.current() == Abi.macosX64 ? r'$INODE64' : '';
    open = library.lookupFunction<Int32 Function(Pointer<Utf8>, Int32),
        int Function(Pointer<Utf8>, int)>('open');
    openat = library.lookupFunction<Int32 Function(Int32, Pointer<Utf8>, Int32),
        int Function(int, Pointer<Utf8>, int)>('openat');
    close = library
        .lookupFunction<Int32 Function(Int32), int Function(int)>('close');
    fstat = library.lookupFunction<Int32 Function(Int32, Pointer<Uint8>),
        int Function(int, Pointer<Uint8>)>('fstat$suffix');
    fstatat = library.lookupFunction<
        Int32 Function(Int32, Pointer<Utf8>, Pointer<Uint8>, Int32),
        int Function(
            int, Pointer<Utf8>, Pointer<Uint8>, int)>('fstatat$suffix');
    fdopendir = library.lookupFunction<Pointer<Void> Function(Int32),
        Pointer<Void> Function(int)>('fdopendir$suffix');
    readdir = library.lookupFunction<Pointer<Uint8> Function(Pointer<Void>),
        Pointer<Uint8> Function(Pointer<Void>)>('readdir$suffix');
    closedir = library.lookupFunction<Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)>('closedir');
    read = library.lookupFunction<
        IntPtr Function(Int32, Pointer<Uint8>, IntPtr),
        int Function(int, Pointer<Uint8>, int)>('read');
    errno = library.lookupFunction<Pointer<Int32> Function(),
        Pointer<Int32> Function()>('__error');
  }

  late final int Function(Pointer<Utf8>, int) open;
  late final int Function(int, Pointer<Utf8>, int) openat;
  late final int Function(int) close;
  late final int Function(int, Pointer<Uint8>) fstat;
  late final int Function(int, Pointer<Utf8>, Pointer<Uint8>, int) fstatat;
  late final Pointer<Void> Function(int) fdopendir;
  late final Pointer<Uint8> Function(Pointer<Void>) readdir;
  late final int Function(Pointer<Void>) closedir;
  late final int Function(int, Pointer<Uint8>, int) read;
  late final Pointer<Int32> Function() errno;
}
