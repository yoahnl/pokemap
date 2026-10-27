import argparse
import pathlib
import re
import shutil


ALLOCATION_METHOD = re.compile(
    r"  BufferView _allocateEmplacement\(ByteData bytes\) \{.*?\n  \}",
    re.DOTALL,
)
ORIGINAL_ALLOCATION = '''  BufferView _allocateEmplacement(ByteData bytes) {
    if (bytes.lengthInBytes > blockLengthInBytes) {
      return BufferView(
        _allocateNewBlock(bytes.lengthInBytes),
        offsetInBytes: 0,
        lengthInBytes: bytes.lengthInBytes,
      );
    }

    int padding =
        _gpuContext.minimumUniformByteAlignment -
        (_offsetCursor % _gpuContext.minimumUniformByteAlignment);
    padding %= _gpuContext.minimumUniformByteAlignment;
    if (_offsetCursor + padding >= blockLengthInBytes) {
      DeviceBuffer buffer = _allocateNewBlock(blockLengthInBytes);
      _buffers[_frameCursor].add(buffer);
      _bufferCursor++;
      _offsetCursor = bytes.lengthInBytes;

      return BufferView(
        buffer,
        offsetInBytes: 0,
        lengthInBytes: blockLengthInBytes,
      );
    }

    _offsetCursor += padding;
    final view = BufferView(
      _buffers[_frameCursor][_bufferCursor],
      offsetInBytes: _offsetCursor,
      lengthInBytes: bytes.lengthInBytes,
    );
    _offsetCursor += bytes.lengthInBytes;
    return view;
  }'''
PATCHED_ALLOCATION = '''  BufferView _allocateEmplacement(ByteData bytes) {
    if (bytes.lengthInBytes > blockLengthInBytes) {
      return BufferView(
        _allocateNewBlock(bytes.lengthInBytes),
        offsetInBytes: 0,
        lengthInBytes: bytes.lengthInBytes,
      );
    }

    final alignment = _gpuContext.minimumUniformByteAlignment;
    final padding = (alignment - (_offsetCursor % alignment)) % alignment;
    if (_offsetCursor + padding + bytes.lengthInBytes > blockLengthInBytes) {
      _bufferCursor++;
      final frame = _buffers[_frameCursor];
      if (_bufferCursor == frame.length) {
        frame.add(_allocateNewBlock(blockLengthInBytes));
      }
      _offsetCursor = 0;
    } else {
      _offsetCursor += padding;
    }

    final view = BufferView(
      _buffers[_frameCursor][_bufferCursor],
      offsetInBytes: _offsetCursor,
      lengthInBytes: bytes.lengthInBytes,
    );
    _offsetCursor += bytes.lengthInBytes;
    return view;
  }'''
LEGACY_COMMAND_MEMORY_PRESSURE = '''final class _CommandMemoryPressure implements Finalizable {
  static final _library = DynamicLibrary.process();
  static final _allocate = _library.lookupFunction<
      Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('malloc');
  static final _finalizer = NativeFinalizer(
    _library.lookup<NativeFunction<Void Function(Pointer<Void>)>>('free'),
  );

  _CommandMemoryPressure(int commandCount)
      : estimatedBytes = commandCount * 1024 {
    final token = _allocate(1);
    if (token == nullptr) {
      throw StateError('Could not account for Flutter GPU command memory');
    }
    _finalizer.attach(this, token, externalSize: estimatedBytes);
  }

  final int estimatedBytes;
}'''
LEGACY_COMMAND_FIELDS = '''  final GpuContext _gpuContext;
  int _nativeCommandCount = 0;
  _CommandMemoryPressure? _nativeAllocation;

  void _recordDraw() {
    _nativeCommandCount++;
  }'''
ORIGINAL_SUBMISSION = '''  void submit({CompletionCallback? completionCallback}) {
    if (_submitted) {
      throw StateError('CommandBuffer has already been submitted.');
    }
    String? error = _submit(completionCallback);
    if (error != null) {
      throw Exception(error);
    }
    _submitted = true;
  }'''
LEGACY_SUBMISSION = ORIGINAL_SUBMISSION.replace('''    _submitted = true;
  }''', '''    _submitted = true;
    if (_nativeAllocation == null && _nativeCommandCount > 0) {
      _nativeAllocation = _CommandMemoryPressure(_nativeCommandCount);
    }
  }''')
ORIGINAL_DRAWS = {}
LEGACY_DRAWS = {}
for method, count in [("draw", "vertexCount"), ("drawIndexed", "indexCount")]:
    ORIGINAL_DRAWS[method] = f'''  void {method}(int {count}, {{int instanceCount = 1}}) {{
    RangeError.checkNotNegative({count}, '{count}');
    RangeError.checkNotNegative(instanceCount, 'instanceCount');
    if ({count} == 0 || instanceCount == 0) {{
      return;
    }}
    _validateVertexBindings();
    if (!_{method}({count}, instanceCount)) {{
      throw Exception("Failed to append {method}");
    }}
  }}'''
    LEGACY_DRAWS[method] = ORIGINAL_DRAWS[method][:-3] + '''    _commandBuffer._recordDraw();
  }'''


def normalize(source):
    return re.sub(r"\s+", "", re.sub(r"//[^\n]*", "", source))


def patch_source(source):
    matches = list(ALLOCATION_METHOD.finditer(source))
    if len(matches) != 1:
        raise ValueError("Flutter GPU HostBuffer allocator could not be identified")
    match = matches[0]
    allocator = normalize(match.group())
    if allocator == normalize(PATCHED_ALLOCATION):
        return source
    if allocator != normalize(ORIGINAL_ALLOCATION):
        raise ValueError("Unsupported Flutter GPU HostBuffer allocator; review the patch before building")
    return source[:match.start()] + PATCHED_ALLOCATION + source[match.end():]


def restore_fragment(source, legacy, original):
    if source.count(legacy) == 1:
        return source.replace(legacy, original, 1)
    if source.count(legacy) > 1 or source.count(original) != 1:
        raise ValueError("Unsupported Flutter GPU command lifecycle; review the patch before building")
    return source


def restore_method(source, name, legacy, original):
    pattern = re.compile(r"  void " + name + r"\([^\n]*\) \{.*?\n  \}", re.DOTALL)
    matches = list(pattern.finditer(source))
    if len(matches) != 1:
        raise ValueError("Unsupported Flutter GPU command lifecycle; review the patch before building")
    match = matches[0]
    method = normalize(match.group())
    if method == normalize(original):
        return source
    if method != normalize(legacy):
        raise ValueError("Unsupported Flutter GPU command lifecycle; review the patch before building")
    return source[:match.start()] + original + source[match.end():]


def patch_command_source(source):
    source = restore_fragment(source, LEGACY_COMMAND_FIELDS, "  final GpuContext _gpuContext;")
    source = restore_method(source, "submit", LEGACY_SUBMISSION, ORIGINAL_SUBMISSION)
    legacy_accounting = "\n" + LEGACY_COMMAND_MEMORY_PRESSURE + "\n"
    if source.count(legacy_accounting) == 1:
        source = source.replace(legacy_accounting, "", 1)
    if "_CommandMemoryPressure" in source:
        raise ValueError("Unsupported Flutter GPU native memory accounting")
    return source


def patch_render_pass_source(source):
    header = "base class RenderPass extends NativeFieldWrapperClass1 {"
    source = restore_fragment(source, header + "\n  final CommandBuffer _commandBuffer;", header)
    source = restore_fragment(
        source,
        "  ) : _commandBuffer = commandBuffer {\n    renderTarget._validateAttachments();",
        "  ) {\n    renderTarget._validateAttachments();",
    )
    for method in ORIGINAL_DRAWS:
        source = restore_method(source, method, LEGACY_DRAWS[method], ORIGINAL_DRAWS[method])
    return source


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--flutter-root", type=pathlib.Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = args.flutter_root
    if root is None:
        executable = shutil.which("flutter")
        if executable is None:
            parser.exit(1, "Flutter executable not found\n")
        root = pathlib.Path(executable).resolve().parents[1]
    try:
        directory = root / "bin/cache/pkg/flutter_gpu/lib/src"
        changes = []
        for name, transform in [
            ("buffer.dart", patch_source),
            ("command_buffer.dart", patch_command_source),
            ("render_pass.dart", patch_render_pass_source),
        ]:
            path = directory / name
            source = path.read_text()
            patched = transform(source)
            if patched != source:
                changes.append((path, patched))
        if not changes:
            print("Flutter GPU memory patch already applied")
            return
        if args.check:
            parser.exit(1, "Flutter GPU memory patch must be applied before building\n")
        for path, patched in changes:
            path.write_text(patched)
        print("Flutter GPU HostBuffer block reuse and upload bounds patched; native command accounting removed")
    except (OSError, ValueError) as error:
        parser.exit(1, f"Flutter GPU patch failed: {error}\n")


if __name__ == "__main__":
    main()
