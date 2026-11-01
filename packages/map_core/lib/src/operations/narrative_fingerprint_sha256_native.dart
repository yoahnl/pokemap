import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'narrative_fingerprint_sha256_portable.dart' as portable;

final class NarrativeSha256Context extends Struct {
  @Array(26)
  external Array<Uint32> words;
}

final class NarrativeFingerprintSha256Bindings {
  NarrativeFingerprintSha256Bindings({
    required this.finalizer,
    required this.allocate,
    required this.release,
    required this.initialize,
    required this.update,
    required this.finish,
  });

  final NativeFinalizer finalizer;
  final Pointer<Void> Function(int) allocate;
  final void Function(Pointer<Void>) release;
  final int Function(Pointer<NarrativeSha256Context>) initialize;
  final int Function(Pointer<NarrativeSha256Context>, Pointer<Uint8>, int)
  update;
  final int Function(Pointer<Uint8>, Pointer<NarrativeSha256Context>) finish;
}

NarrativeFingerprintSha256Bindings loadNarrativeFingerprintSha256Bindings() {
  final library = DynamicLibrary.open('/usr/lib/libSystem.B.dylib');
  final allocate = library
      .lookupFunction<
        Pointer<Void> Function(Size, Size),
        Pointer<Void> Function(int, int)
      >('calloc');
  return NarrativeFingerprintSha256Bindings(
    finalizer: _systemFinalizer,
    allocate: (size) => allocate(1, size),
    release: library
        .lookupFunction<
          Void Function(Pointer<Void>),
          void Function(Pointer<Void>)
        >('free'),
    initialize: library
        .lookupFunction<
          Int32 Function(Pointer<NarrativeSha256Context>),
          int Function(Pointer<NarrativeSha256Context>)
        >('CC_SHA256_Init'),
    update: library
        .lookupFunction<
          Int32 Function(
            Pointer<NarrativeSha256Context>,
            Pointer<Uint8>,
            Uint32,
          ),
          int Function(Pointer<NarrativeSha256Context>, Pointer<Uint8>, int)
        >('CC_SHA256_Update'),
    finish: library
        .lookupFunction<
          Int32 Function(Pointer<Uint8>, Pointer<NarrativeSha256Context>),
          int Function(Pointer<Uint8>, Pointer<NarrativeSha256Context>)
        >('CC_SHA256_Final'),
  );
}

bool get nativeNarrativeFingerprintSha256Available => _systemBindings != null;

ByteConversionSink createNarrativeFingerprintSha256Sink(
  Sink<Digest> output, {
  bool? macOS,
  NarrativeFingerprintSha256Bindings Function()? loadBindings,
}) {
  if (!(macOS ?? Platform.isMacOS)) {
    return portable.createNarrativeFingerprintSha256Sink(output);
  }
  NarrativeFingerprintSha256Bindings? bindings;
  try {
    bindings = loadBindings == null ? _systemBindings : loadBindings();
  } on Object {
    return portable.createNarrativeFingerprintSha256Sink(output);
  }
  if (bindings == null) {
    return portable.createNarrativeFingerprintSha256Sink(output);
  }
  return ByteConversionSink.from(
    _NativeNarrativeFingerprintSha256Sink(bindings, output),
  );
}

final NativeFinalizer _systemFinalizer = NativeFinalizer(
  DynamicLibrary.open('/usr/lib/libSystem.B.dylib').lookup('free'),
);

final NarrativeFingerprintSha256Bindings? _systemBindings =
    _loadSystemBindings();

NarrativeFingerprintSha256Bindings? _loadSystemBindings() {
  if (!Platform.isMacOS) return null;
  try {
    return loadNarrativeFingerprintSha256Bindings();
  } on Object {
    return null;
  }
}

final class _NativeNarrativeFingerprintSha256Sink
    implements Sink<List<int>>, Finalizable {
  _NativeNarrativeFingerprintSha256Sink(this._bindings, this._output) {
    try {
      _memory = _bindings.allocate(_contextBytes + _digestBytes);
      if (_memory == nullptr)
        throw StateError('SHA256 context allocation failed.');
      _bindings.finalizer.attach(
        this,
        _memory,
        detach: _contextToken,
        externalSize: _contextBytes + _digestBytes,
      );
      if (_bindings.initialize(_memory.cast()) != 1) {
        throw StateError('SHA256 initialization failed.');
      }
    } on Object {
      _closed = true;
      _dispose();
      rethrow;
    }
  }

  static const _contextBytes = 104;
  static const _digestBytes = 32;
  static const _maximumScratchBytes = 65536;
  final NarrativeFingerprintSha256Bindings _bindings;
  final Sink<Digest> _output;
  final Object _contextToken = Object();
  final Object _scratchToken = Object();
  Pointer<Void> _memory = nullptr;
  Pointer<Uint8> _scratch = nullptr;
  int _scratchBytes = 0;
  bool _closed = false;

  @override
  void add(List<int> data) {
    if (_closed) throw StateError('The SHA256 sink is closed.');
    try {
      if (data.isEmpty) return;
      final needed = min(data.length, _maximumScratchBytes);
      if (_scratchBytes < needed) {
        _releaseScratch();
        _scratch = _bindings.allocate(needed).cast();
        if (_scratch == nullptr)
          throw StateError('SHA256 scratch allocation failed.');
        _bindings.finalizer.attach(
          this,
          _scratch.cast(),
          detach: _scratchToken,
          externalSize: needed,
        );
        _scratchBytes = needed;
      }
      for (var offset = 0; offset < data.length; offset += _scratchBytes) {
        final length = min(_scratchBytes, data.length - offset);
        _scratch.asTypedList(length).setRange(0, length, data, offset);
        if (_bindings.update(_memory.cast(), _scratch, length) != 1) {
          throw StateError('SHA256 update failed.');
        }
      }
    } on Object {
      _closed = true;
      _dispose();
      rethrow;
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    try {
      final output = _memory.cast<Uint8>() + _contextBytes;
      if (_bindings.finish(output, _memory.cast()) != 1) {
        throw StateError('SHA256 finalization failed.');
      }
      final bytes = Uint8List.fromList(output.asTypedList(_digestBytes));
      _output.add(Digest(bytes));
      _output.close();
    } finally {
      _dispose();
    }
  }

  void _releaseScratch() {
    final scratch = _scratch;
    if (scratch == nullptr) return;
    _bindings.finalizer.detach(_scratchToken);
    _scratch = nullptr;
    _scratchBytes = 0;
    _bindings.release(scratch.cast());
  }

  void _dispose() {
    try {
      _releaseScratch();
    } finally {
      final memory = _memory;
      if (memory != nullptr) {
        _bindings.finalizer.detach(_contextToken);
        _memory = nullptr;
        _bindings.release(memory);
      }
    }
  }
}
