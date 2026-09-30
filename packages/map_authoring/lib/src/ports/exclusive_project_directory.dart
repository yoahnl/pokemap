import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

typedef _AllocateNative = Pointer<Void> Function(IntPtr);
typedef _Allocate = Pointer<Void> Function(int);
typedef _FreeNative = Void Function(Pointer<Void>);
typedef _Free = void Function(Pointer<Void>);
typedef _MkdirNative = Int32 Function(Pointer<Uint8>, Uint32);
typedef _Mkdir = int Function(Pointer<Uint8>, int);
typedef _CreateDirectoryNative = Int32 Function(Pointer<Uint16>, Pointer<Void>);
typedef _CreateDirectory = int Function(Pointer<Uint16>, Pointer<Void>);

void createExclusiveProjectDirectory(String path) {
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    throw const FileSystemException(
        'La création native est indisponible sur cette plateforme.');
  }
  final library = Platform.isWindows
      ? DynamicLibrary.open('msvcrt.dll')
      : DynamicLibrary.process();
  final allocate = library.lookupFunction<_AllocateNative, _Allocate>('malloc');
  final free = library.lookupFunction<_FreeNative, _Free>('free');
  final bytes = utf8.encode(path);
  final units = path.codeUnits;
  final memory =
      allocate(Platform.isWindows ? (units.length + 1) * 2 : bytes.length + 1);
  if (memory == nullptr) {
    throw const FileSystemException('Mémoire insuffisante.');
  }
  try {
    late final bool created;
    if (Platform.isWindows) {
      final nativePath = memory.cast<Uint16>();
      nativePath.asTypedList(units.length + 1).setAll(0, [...units, 0]);
      final create = DynamicLibrary.open('kernel32.dll')
          .lookupFunction<_CreateDirectoryNative, _CreateDirectory>(
              'CreateDirectoryW');
      created = create(nativePath, nullptr) != 0;
    } else {
      final nativePath = memory.cast<Uint8>();
      nativePath.asTypedList(bytes.length + 1).setAll(0, [...bytes, 0]);
      final mkdir = library.lookupFunction<_MkdirNative, _Mkdir>('mkdir');
      created = mkdir(nativePath, 0x1c0) == 0;
    }
    if (!created) {
      throw FileSystemException(
          'Le dossier existe déjà ou sa création est refusée.', path);
    }
  } finally {
    free(memory);
  }
}
