import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import urllib.parse
import urllib.request

import patch_flutter_gpu


FLUTTER_ROOT = pathlib.Path(shutil.which("flutter")).resolve().parents[1]
BUFFER_SOURCE = FLUTTER_ROOT / "bin/cache/pkg/flutter_gpu/lib/src/buffer.dart"
DART = FLUTTER_ROOT / "bin/cache/dart-sdk/bin/dart"
GPU_STUBS = r'''
import 'dart:convert';
import 'dart:typed_data';

enum StorageMode { hostVisible }

class GpuContext {
  final List<DeviceBuffer> allocations = [];
  int get minimumUniformByteAlignment => 256;

  DeviceBuffer createDeviceBuffer(StorageMode mode, int length) {
    final buffer = DeviceBuffer(length);
    allocations.add(buffer);
    return buffer;
  }
}

base class DeviceBuffer {
  DeviceBuffer(this.sizeInBytes) : data = Uint8List(sizeInBytes);
  final int sizeInBytes;
  final Uint8List data;

  bool overwrite(ByteData bytes, {int destinationOffsetInBytes = 0}) {
    if (destinationOffsetInBytes + bytes.lengthInBytes > sizeInBytes) {
      return false;
    }
    data.setRange(
      destinationOffsetInBytes,
      destinationOffsetInBytes + bytes.lengthInBytes,
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return true;
  }
}

class BufferView {
  BufferView(this.buffer, {required this.offsetInBytes, required this.lengthInBytes});
  final DeviceBuffer buffer;
  final int offsetInBytes;
  final int lengthInBytes;
}
'''


def host_buffer_source(source):
    return source[source.index("base class HostBuffer {"):]


def original_sdk_sources():
    sources = {name: BUFFER_SOURCE.with_name(name).read_text() for name in [
        "buffer.dart", "command_buffer.dart", "render_pass.dart",
    ]}
    sources["buffer.dart"] = patch_flutter_gpu.ALLOCATION_METHOD.sub(
        lambda _: patch_flutter_gpu.ORIGINAL_ALLOCATION, sources["buffer.dart"],
    )
    sources["command_buffer.dart"] = sources["command_buffer.dart"].replace(
        patch_flutter_gpu.COMMAND_FIELDS, "  final GpuContext _gpuContext;",
    ).replace(patch_flutter_gpu.PATCHED_SUBMISSION, patch_flutter_gpu.ORIGINAL_SUBMISSION)
    sources["command_buffer.dart"] = sources["command_buffer.dart"].replace(
        "\n" + patch_flutter_gpu.COMMAND_MEMORY_PRESSURE + "\n", "",
    )
    sources["render_pass.dart"] = sources["render_pass.dart"].replace(
        "\n  final CommandBuffer _commandBuffer;", "",
    ).replace(
        "  ) : _commandBuffer = commandBuffer {\n    renderTarget._validateAttachments();",
        "  ) {\n    renderTarget._validateAttachments();",
    )
    for method in patch_flutter_gpu.ORIGINAL_DRAWS:
        sources["render_pass.dart"] = sources["render_pass.dart"].replace(
            patch_flutter_gpu.PATCHED_DRAWS[method], patch_flutter_gpu.ORIGINAL_DRAWS[method],
        )
    return sources


class HostBufferRegressionTest(unittest.TestCase):
    def run_allocator(self, body):
        source = host_buffer_source(patch_flutter_gpu.patch_source(BUFFER_SOURCE.read_text()))
        main = '''
void main() {
  final context = GpuContext();
  final host = HostBuffer._initialize(context, blockLengthInBytes: 1024);
  try {
''' + body + '''
  } catch (error) {
    print(jsonEncode({'error': error.toString()}));
  }
}
'''
        with tempfile.TemporaryDirectory(prefix="avelune-host-buffer-") as directory:
            script = pathlib.Path(directory) / "allocator.dart"
            script.write_text(GPU_STUBS + source + main)
            result = subprocess.run(
                [str(DART), str(script)], text=True, capture_output=True, timeout=20,
            )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        value = json.loads(result.stdout)
        self.assertNotIn("error", value, value)
        return value

    def test_pool_stops_growing_after_all_frame_slots_are_warm(self):
        result = self.run_allocator('''
    int warmAllocations = 0;
    for (int frame = 0; frame < 2000; frame++) {
      for (int item = 0; item < 9; item++) {
        host.emplace(ByteData(256));
      }
      host.reset();
      if (frame == host.frameCount - 1) {
        warmAllocations = context.allocations.length;
      }
    }
    print(jsonEncode({'warm': warmAllocations, 'final': context.allocations.length}));
''')
        self.assertEqual(result["warm"], 12)
        self.assertEqual(result["final"], result["warm"])

    def test_write_crossing_block_end_moves_to_a_new_block(self):
        result = self.run_allocator('''
    final first = host.emplace(ByteData(700));
    final bytes = ByteData(300)..setUint8(299, 42);
    final second = host.emplace(bytes);
    print(jsonEncode({
      'sameBuffer': identical(first.buffer, second.buffer),
      'offset': second.offsetInBytes,
      'length': second.lengthInBytes,
      'lastByte': second.buffer.data[299],
    }));
''')
        self.assertEqual(result, {"sameBuffer": False, "offset": 0, "length": 300, "lastByte": 42})

    def test_overflow_view_describes_only_the_uploaded_bytes(self):
        result = self.run_allocator('''
    for (int item = 0; item < 4; item++) {
      host.emplace(ByteData(256));
    }
    final view = host.emplace(ByteData(256));
    print(jsonEncode({'offset': view.offsetInBytes, 'length': view.lengthInBytes}));
''')
        self.assertEqual(result, {"offset": 0, "length": 256})

    def test_exact_fit_and_oversized_uploads_keep_valid_ranges(self):
        result = self.run_allocator('''
    final first = host.emplace(ByteData(768));
    final exact = host.emplace(ByteData(256));
    final oversized = host.emplace(ByteData(2048));
    final next = host.emplace(ByteData(128));
    print(jsonEncode({
      'exactBuffer': identical(first.buffer, exact.buffer),
      'exactOffset': exact.offsetInBytes,
      'oversizedCapacity': oversized.buffer.sizeInBytes,
      'oversizedLength': oversized.lengthInBytes,
      'nextOffset': next.offsetInBytes,
      'nextCapacity': next.buffer.sizeInBytes,
    }));
''')
        self.assertEqual(result, {
            "exactBuffer": True, "exactOffset": 768,
            "oversizedCapacity": 2048, "oversizedLength": 2048,
            "nextOffset": 0, "nextCapacity": 1024,
        })

    def test_reuse_keeps_the_four_frame_rotation_and_alignment(self):
        result = self.run_allocator('''
    final blocks = <DeviceBuffer>[];
    for (int frame = 0; frame < host.frameCount; frame++) {
      final first = host.emplace(ByteData(1)..setUint8(0, frame + 1));
      final second = host.emplace(ByteData(1)..setUint8(0, 99));
      if (second.offsetInBytes != 256 || first.buffer.data[0] != frame + 1) {
        throw StateError('Alignment or previous upload was overwritten');
      }
      blocks.add(first.buffer);
      host.reset();
    }
    final next = host.emplace(ByteData(1));
    print(jsonEncode({
      'slots': blocks.toSet().length,
      'reused': identical(next.buffer, blocks.first),
      'offset': next.offsetInBytes,
      'allocations': context.allocations.length,
    }));
''')
        self.assertEqual(result, {"slots": 4, "reused": True, "offset": 0, "allocations": 4})


class PatchApplicationTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="avelune-gpu-patch-")
        self.addCleanup(self.directory.cleanup)
        self.root = pathlib.Path(self.directory.name)
        self.target = self.root / "bin/cache/pkg/flutter_gpu/lib/src/buffer.dart"
        self.target.parent.mkdir(parents=True)
        self.sources = original_sdk_sources()
        self.source = self.sources["buffer.dart"]
        for name, source in self.sources.items():
            self.target.with_name(name).write_text(source)

    def run_patch(self, *arguments):
        return subprocess.run(
            [sys.executable, str(pathlib.Path(__file__).with_name("patch_flutter_gpu.py")),
             "--flutter-root", str(self.root), *arguments],
            capture_output=True, text=True, timeout=10,
        )

    def test_patch_is_idempotent_and_preserves_other_sdk_code(self):
        first = self.run_patch()
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        expected = patch_flutter_gpu.ALLOCATION_METHOD.sub(
            lambda _: patch_flutter_gpu.PATCHED_ALLOCATION, self.source,
        )
        self.assertEqual(self.target.read_text(), expected)
        command = self.target.with_name("command_buffer.dart")
        render = self.target.with_name("render_pass.dart")
        self.assertNotIn("_CommandMemoryPressure", self.sources["command_buffer.dart"])
        self.assertNotIn("_commandBuffer._recordDraw()", self.sources["render_pass.dart"])
        self.assertIn(patch_flutter_gpu.COMMAND_FIELDS, command.read_text())
        self.assertIn(patch_flutter_gpu.PATCHED_SUBMISSION, command.read_text())
        self.assertIn(patch_flutter_gpu.COMMAND_MEMORY_PRESSURE, command.read_text())
        self.assertIn("final CommandBuffer _commandBuffer;", render.read_text())
        self.assertIn("_commandBuffer = commandBuffer", render.read_text())
        for method in patch_flutter_gpu.PATCHED_DRAWS.values():
            self.assertIn(method, render.read_text())
        modification_times = {p: p.stat().st_mtime_ns for p in [self.target, command, render]}
        second = self.run_patch()
        self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
        self.assertEqual({p: p.stat().st_mtime_ns for p in modification_times}, modification_times)

    def test_check_is_read_only_and_rejects_an_unpatched_sdk(self):
        result = self.run_patch("--check")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.target.read_text(), self.source)
        self.assertEqual(self.run_patch().returncode, 0)
        self.assertEqual(self.run_patch("--check").returncode, 0)

    def test_unknown_allocator_is_rejected_without_writing(self):
        unknown = self.source.replace("_offsetCursor + padding >=", "_offsetCursor + padding >")
        self.target.write_text(unknown)
        result = self.run_patch()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Unsupported", result.stderr)
        self.assertEqual(self.target.read_text(), unknown)

    def test_missing_gpu_package_is_rejected(self):
        self.target.unlink()
        result = self.run_patch()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Flutter GPU patch failed", result.stderr)

    def test_unknown_command_lifecycle_leaves_every_sdk_file_unchanged(self):
        command = self.target.with_name("command_buffer.dart")
        command.write_text("unsupported command lifecycle")
        originals = {p: p.read_text() for p in self.target.parent.glob("*.dart")}
        result = self.run_patch()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Unsupported", result.stderr)
        self.assertEqual({p: p.read_text() for p in originals}, originals)


    def test_changed_submission_control_flow_is_rejected_before_any_write(self):
        command = self.target.with_name("command_buffer.dart")
        command.write_text(command.read_text().replace(
            "String? error = _submit(completionCallback);",
            "String? error = _submit(completionCallback);\n    return;",
        ))
        originals = {p: p.read_text() for p in self.target.parent.glob("*.dart")}
        result = self.run_patch()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Unsupported", result.stderr)
        self.assertEqual({p: p.read_text() for p in originals}, originals)

    def test_changed_draw_guard_is_rejected_before_any_write(self):
        render = self.target.with_name("render_pass.dart")
        render.write_text(render.read_text().replace(
            "vertexCount == 0 || instanceCount == 0", "vertexCount == 0",
        ))
        originals = {p: p.read_text() for p in self.target.parent.glob("*.dart")}
        result = self.run_patch()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Unsupported", result.stderr)
        self.assertEqual({p: p.read_text() for p in originals}, originals)


class NativeCommandMemoryTest(unittest.TestCase):
    def test_only_successful_nonempty_draws_are_accounted_after_submission(self):
        command = patch_flutter_gpu.patch_command_source(BUFFER_SOURCE.with_name("command_buffer.dart").read_text())
        render = patch_flutter_gpu.patch_render_pass_source(BUFFER_SOURCE.with_name("render_pass.dart").read_text())
        helper = command[command.index("final class _CommandMemoryPressure implements Finalizable {"):]
        submit = re.search(r"  void submit\(\{CompletionCallback\? completionCallback\}\) \{.*?\n  \}", command, re.DOTALL).group()
        draws = [re.search(rf"  void {name}\(.*?\n  \}}", render, re.DOTALL).group() for name in ["draw", "drawIndexed"]]
        fields = patch_flutter_gpu.COMMAND_FIELDS.replace("  final GpuContext _gpuContext;", "")
        driver = '''
import 'dart:convert';
import 'dart:ffi';

typedef CompletionCallback = void Function(bool success);

class CommandBuffer {
  bool _submitted = false;
  bool failSubmission = false;
  String? _submit(CompletionCallback? callback) => failSubmission ? 'failed' : null;
''' + fields + submit + '''
}

class RenderPass {
  RenderPass(this._commandBuffer);
  final CommandBuffer _commandBuffer;
  bool failDraw = false;
  void _validateVertexBindings() {}
  bool _draw(int count, int instances) => !failDraw;
  bool _drawIndexed(int count, int instances) => !failDraw;
''' + "\n".join(draws) + '''
}

void main() {
  final command = CommandBuffer();
  final pass = RenderPass(command);
  pass.draw(0);
  pass.drawIndexed(2, instanceCount: 0);
  pass.draw(3);
  pass.drawIndexed(6);
  pass.failDraw = true;
  try { pass.draw(3); } catch (_) {}
  command.submit();
  bool secondSubmissionRejected = false;
  try { command.submit(); } catch (_) { secondSubmissionRejected = true; }
  final empty = CommandBuffer()..submit();
  final failed = CommandBuffer()..failSubmission = true;
  RenderPass(failed).draw(3);
  try { failed.submit(); } catch (_) {}
  print(jsonEncode({
    'bytes': command._nativeAllocation?.estimatedBytes,
    'commands': command._nativeCommandCount,
    'emptyAccounted': empty._nativeAllocation != null,
    'failedAccounted': failed._nativeAllocation != null,
    'secondSubmissionRejected': secondSubmissionRejected,
  }));
}
'''
        with tempfile.TemporaryDirectory(prefix="avelune-command-accounting-") as directory:
            script = pathlib.Path(directory) / "commands.dart"
            script.write_text(driver + helper)
            result = subprocess.run([str(DART), str(script)], capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(result.stdout), {
            "bytes": 2048, "commands": 2, "emptyAccounted": False,
            "failedAccounted": False, "secondSubmissionRejected": True,
        })

    def test_native_memory_is_reported_to_the_vm_and_released_after_collection(self):
        source = patch_flutter_gpu.patch_command_source(BUFFER_SOURCE.with_name("command_buffer.dart").read_text())
        helper = source[source.index("final class _CommandMemoryPressure implements Finalizable {"):]
        driver = r'''
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

_CommandMemoryPressure? pressure;

Future<void> main() async {
  final service = await developer.Service.getInfo();
  print(jsonEncode({'uri': service.serverUri.toString()}));
  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line == 'allocate') {
      pressure = _CommandMemoryPressure(8192);
      print('allocated');
    } else if (line == 'drop') {
      pressure = null;
      print('dropped');
    } else if (line == 'quit') {
      exit(0);
    }
  }
}
'''
        with tempfile.TemporaryDirectory(prefix="avelune-native-command-memory-") as directory:
            script = pathlib.Path(directory) / "native_memory.dart"
            script.write_text(driver + helper)
            process = subprocess.Popen(
                [str(DART), "--enable-vm-service=0", "--disable-service-auth-codes",
                 "--no-serve-devtools", str(script)],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            )
            try:
                uri = None
                for _ in range(8):
                    line = process.stdout.readline()
                    try:
                        uri = json.loads(line).get("uri")
                    except json.JSONDecodeError:
                        pass
                    if uri:
                        break
                self.assertIsNotNone(uri)

                def rpc(method, **arguments):
                    url = uri + method + "?" + urllib.parse.urlencode(arguments)
                    with urllib.request.urlopen(url, timeout=10) as response:
                        return json.load(response)["result"]

                isolate = rpc("getVM")["isolates"][0]["id"]

                def external_bytes():
                    return rpc("getAllocationProfile", isolateId=isolate, gc="true")["memoryUsage"]["externalUsage"]

                def send(command, expected):
                    process.stdin.write(command + "\n")
                    process.stdin.flush()
                    self.assertEqual(process.stdout.readline().strip(), expected)

                baseline = external_bytes()
                send("allocate", "allocated")
                self.assertGreaterEqual(external_bytes() - baseline, 8 * 1024 * 1024)
                send("drop", "dropped")
                self.assertLess(external_bytes() - baseline, 1024 * 1024)
            finally:
                if process.poll() is None:
                    process.stdin.write("quit\n")
                    process.stdin.flush()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.terminate()
                        process.wait(timeout=5)
                process.stdin.close()
                process.stdout.close()
                process.stderr.close()


if __name__ == "__main__":
    unittest.main()
