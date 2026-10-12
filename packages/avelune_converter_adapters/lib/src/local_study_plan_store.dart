import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'converter_study_plan_recipe.dart';
import 'converter_workflow.dart';

final class LocalStudyPlanStore {
  const LocalStudyPlanStore();

  Future<ConverterStudyPlanRecipe> read(String selectedPath) async {
    final parent = await _parent(selectedPath);
    final name = path.basename(selectedPath);
    final directory = _openParent(parent);
    var file = -1;
    try {
      file =
          _withName(name, (p) => _native.openat(directory, p, 0x01000104, 0));
      if (file < 0) throw _storeFailure();
      final before = _stat(file);
      if (before.mode & 0xf000 != 0x8000) throw _storeFailure();
      if (before.size < 0 ||
          before.size > ConverterStudyPlanRecipe.maxFileBytes) {
        throw _quota();
      }
      final buffer = calloc<Uint8>(65536);
      final bytes = BytesBuilder(copy: false);
      try {
        while (true) {
          final count = _native.read(file, buffer, 65536);
          if (count < 0) throw _storeFailure();
          if (count == 0) break;
          if (bytes.length + count > ConverterStudyPlanRecipe.maxFileBytes) {
            throw _quota();
          }
          bytes.add(Uint8List.fromList(buffer.asTypedList(count)));
        }
      } finally {
        calloc.free(buffer);
      }
      if (_stat(file).token != before.token || bytes.length != before.size) {
        throw _storeFailure();
      }
      _checkParent(parent, directory);
      try {
        return ConverterStudyPlanRecipe.decode(utf8.decode(bytes.takeBytes()));
      } on FormatException {
        throw _storeFailure();
      }
    } finally {
      if (file >= 0) _native.close(file);
      _native.close(directory);
    }
  }

  Future<void> writeNew(
      ConverterStudyPlanRecipe recipe, String selectedPath) async {
    final bytes = utf8.encode('${recipe.encode()}\n');
    if (bytes.length > ConverterStudyPlanRecipe.maxFileBytes) throw _quota();
    final parent = await _parent(selectedPath);
    final source =
        await Directory(recipe.sourceSelection.rootPath).resolveSymbolicLinks();
    if (parent == source || path.isWithin(source, parent)) {
      throw const ConverterWorkflowFailure('workflow.recipe.source_overlap',
          'A study plan must be written outside its read-only source.');
    }
    final nativeDestination =
        path.join(await Directory(recipe.settings.parentPath).resolveSymbolicLinks(),
            recipe.settings.folderName);
    final canonicalSelectedPath = path.join(parent, path.basename(selectedPath));
    if (path.equals(canonicalSelectedPath, nativeDestination) ||
        path.isWithin(nativeDestination, canonicalSelectedPath)) {
      throw const ConverterWorkflowFailure(
          'workflow.recipe.destination_overlap',
          'A study plan must remain separate from the native project.');
    }
    final directory = _openParent(parent);
    var file = -1;
    try {
      file = _withName(path.basename(selectedPath),
          (p) => _native.openat(directory, p, 0x01000b01, 0x180));
      if (file < 0) {
        throw const ConverterWorkflowFailure('workflow.recipe.conflict',
            'Choose a new regular plan file; existing paths are never replaced.');
      }
      final buffer = calloc<Uint8>(bytes.length);
      try {
        buffer.asTypedList(bytes.length).setAll(0, bytes);
        var offset = 0;
        while (offset < bytes.length) {
          final count =
              _native.write(file, buffer + offset, bytes.length - offset);
          if (count <= 0) throw _storeFailure();
          offset += count;
        }
        if (_native.fsync(file) != 0 || _native.fsync(directory) != 0) {
          throw _storeFailure();
        }
        if (_stat(file).size != bytes.length) throw _storeFailure();
        _checkParent(parent, directory);
      } finally {
        calloc.free(buffer);
      }
    } finally {
      if (file >= 0) _native.close(file);
      _native.close(directory);
    }
  }
}

Future<String> _parent(String selectedPath) async {
  if (!Platform.isMacOS ||
      !const [Abi.macosArm64, Abi.macosX64].contains(Abi.current())) {
    throw const ConverterWorkflowFailure('workflow.recipe.platform_unsupported',
        'Safe plan file access requires macOS arm64 or x64.');
  }
  if (!path.isAbsolute(selectedPath) ||
      selectedPath.length > 4096 ||
      selectedPath.contains('\u0000') ||
      path.normalize(selectedPath) != selectedPath ||
      path.extension(selectedPath).toLowerCase() != '.json') {
    throw _storeFailure();
  }
  try {
    return await Directory(path.dirname(selectedPath)).resolveSymbolicLinks();
  } on FileSystemException {
    throw _storeFailure();
  }
}

int _openParent(String parent) {
  final fd = _withName(parent, (p) => _native.open(p, 0x21100000));
  if (fd < 0) throw _storeFailure();
  return fd;
}

void _checkParent(String parent, int directory) {
  final current = _openParent(parent);
  try {
    if (_stat(current).identity != _stat(directory).identity) {
      throw _storeFailure();
    }
  } finally {
    _native.close(current);
  }
}

({int size, int mode, String identity, String token}) _stat(int fd) {
  final buffer = calloc<Uint8>(144);
  try {
    if (_native.fstat(fd, buffer) != 0) throw _storeFailure();
    final b = ByteData.sublistView(buffer.asTypedList(144));
    final identity =
        '${b.getInt32(0, Endian.host)}:${b.getUint64(8, Endian.host)}:${b.getUint32(120, Endian.host)}';
    return (
      size: b.getInt64(96, Endian.host),
      mode: b.getUint16(4, Endian.host),
      identity: identity,
      token:
          '$identity:${b.getInt64(48, Endian.host)}:${b.getInt64(56, Endian.host)}:${b.getInt64(64, Endian.host)}:${b.getInt64(72, Endian.host)}:${b.getInt64(96, Endian.host)}'
    );
  } finally {
    calloc.free(buffer);
  }
}

T _withName<T>(String name, T Function(Pointer<Utf8>) operation) {
  final pointer = name.toNativeUtf8();
  try {
    return operation(pointer);
  } finally {
    calloc.free(pointer);
  }
}

ConverterWorkflowFailure _storeFailure() => const ConverterWorkflowFailure(
    'workflow.recipe.store_invalid',
    'Choose a stable regular JSON plan file in an existing directory.');
ConverterWorkflowFailure _quota() => const ConverterWorkflowFailure(
    'workflow.recipe.quota', 'Study plan file exceeds its 4 MiB byte budget.');
final _native = _PlanNative();

final class _PlanNative {
  _PlanNative() {
    if (!Platform.isMacOS) return;
    final library = DynamicLibrary.open('/usr/lib/libSystem.B.dylib');
    final suffix = Abi.current() == Abi.macosX64 ? r'$INODE64' : '';
    open = library.lookupFunction<Int32 Function(Pointer<Utf8>, Int32),
        int Function(Pointer<Utf8>, int)>('open');
    openat = library.lookupFunction<
        Int32 Function(Int32, Pointer<Utf8>, Int32, VarArgs<(Uint32,)>),
        int Function(int, Pointer<Utf8>, int, int)>('openat');
    close = library
        .lookupFunction<Int32 Function(Int32), int Function(int)>('close');
    fstat = library.lookupFunction<Int32 Function(Int32, Pointer<Uint8>),
        int Function(int, Pointer<Uint8>)>('fstat$suffix');
    read = library.lookupFunction<
        IntPtr Function(Int32, Pointer<Uint8>, IntPtr),
        int Function(int, Pointer<Uint8>, int)>('read');
    write = library.lookupFunction<
        IntPtr Function(Int32, Pointer<Uint8>, IntPtr),
        int Function(int, Pointer<Uint8>, int)>('write');
    fsync = library
        .lookupFunction<Int32 Function(Int32), int Function(int)>('fsync');
  }
  late final int Function(Pointer<Utf8>, int) open;
  late final int Function(int, Pointer<Utf8>, int, int) openat;
  late final int Function(int) close;
  late final int Function(int, Pointer<Uint8>) fstat;
  late final int Function(int, Pointer<Uint8>, int) read;
  late final int Function(int, Pointer<Uint8>, int) write;
  late final int Function(int) fsync;
}
