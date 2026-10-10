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
COMMAND_MEMORY_PRESSURE = '''final class _CommandMemoryPressure implements Finalizable {
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
COMMAND_FIELDS = '''  final GpuContext _gpuContext;
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
PATCHED_SUBMISSION = ORIGINAL_SUBMISSION.replace('''    _submitted = true;
  }''', '''    _submitted = true;
    if (_nativeAllocation == null && _nativeCommandCount > 0) {
      _nativeAllocation = _CommandMemoryPressure(_nativeCommandCount);
    }
  }''')
ORIGINAL_DRAWS = {}
PATCHED_DRAWS = {}
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
    PATCHED_DRAWS[method] = ORIGINAL_DRAWS[method][:-3] + '''    _commandBuffer._recordDraw();
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


def replace_fragment(source, original, patched):
    if source.count(patched) == 1:
        return source
    if source.count(original) != 1:
        raise ValueError("Unsupported Flutter GPU command lifecycle; review the patch before building")
    return source.replace(original, patched, 1)


def replace_method(source, name, original, patched):
    pattern = re.compile(r"  void " + name + r"\([^\n]*\) \{.*?\n  \}", re.DOTALL)
    matches = list(pattern.finditer(source))
    if len(matches) != 1:
        raise ValueError("Unsupported Flutter GPU command lifecycle; review the patch before building")
    match = matches[0]
    method = normalize(match.group())
    if method == normalize(patched):
        return source
    if method != normalize(original):
        raise ValueError("Unsupported Flutter GPU command lifecycle; review the patch before building")
    return source[:match.start()] + patched + source[match.end():]


def patch_command_source(source):
    source = replace_fragment(source, "  final GpuContext _gpuContext;", COMMAND_FIELDS)
    source = replace_method(source, "submit", ORIGINAL_SUBMISSION, PATCHED_SUBMISSION)
    if COMMAND_MEMORY_PRESSURE not in source:
        if "class _CommandMemoryPressure" in source:
            raise ValueError("Unsupported Flutter GPU native memory accounting")
        source += "\n" + COMMAND_MEMORY_PRESSURE + "\n"
    return source


def patch_render_pass_source(source):
    header = "base class RenderPass extends NativeFieldWrapperClass1 {"
    source = replace_fragment(source, header, header + "\n  final CommandBuffer _commandBuffer;")
    original = "  ) {\n    renderTarget._validateAttachments();"
    patched = "  ) : _commandBuffer = commandBuffer {\n    renderTarget._validateAttachments();"
    source = replace_fragment(source, original, patched)
    for method in ORIGINAL_DRAWS:
        source = replace_method(source, method, ORIGINAL_DRAWS[method], PATCHED_DRAWS[method])
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
        print("Flutter GPU HostBuffer block reuse, upload bounds and native command accounting patched")
    except (OSError, ValueError) as error:
        parser.exit(1, f"Flutter GPU patch failed: {error}\n")


if __name__ == "__main__":
    main()
