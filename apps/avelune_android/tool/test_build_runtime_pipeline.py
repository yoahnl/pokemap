import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


SOURCE_ROOT = pathlib.Path(__file__).resolve().parents[1]
IOS_TOOL = SOURCE_ROOT.parent / "Avelune iOS/tool"
sys.path.insert(0, str(IOS_TOOL))
import patch_flutter_gpu
from test_flutter_gpu_host_buffer import original_sdk_sources
sys.path.pop(0)


STUB = r'''#!/usr/bin/env python3
import importlib.util
import json
import os
import pathlib
import sys

command = pathlib.Path(sys.argv[0]).name
arguments = sys.argv[1:]
if command == "pipeline_stub":
    command = arguments.pop(0)
gpu_patch_ready = None
if command == "flutter":
    properties = pathlib.Path(os.environ["RUNTIME_ROOT"]) / "flutter_runtime/.android/local.properties"
    properties.parent.mkdir(parents=True, exist_ok=True)
    properties.write_text("flutter.sdk=" + os.environ["RUNTIME_SDK"] + "\n")
if command == "gradlew":
    spec = importlib.util.spec_from_file_location("gpu_patch", os.environ["GPU_PATCH_TOOL"])
    patch = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(patch)
    directory = pathlib.Path(os.environ["RUNTIME_SDK"]) / "bin/cache/pkg/flutter_gpu/lib/src"
    gpu_patch_ready = all(
        (source := (directory / name).read_text()) == transform(source)
        for name, transform in [
            ("buffer.dart", patch.patch_source),
            ("command_buffer.dart", patch.patch_command_source),
            ("render_pass.dart", patch.patch_render_pass_source),
        ]
    )
with open(os.environ["PIPELINE_LOG"], "a") as log:
    log.write(json.dumps({"command": command, "arguments": arguments, "gpu_patch_ready": gpu_patch_ready}) + "\n")
'''


class AndroidRuntimePipelineTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="avelune-android-pipeline-")
        self.addCleanup(self.directory.cleanup)
        self.fixture = pathlib.Path(self.directory.name)
        self.root = self.fixture / "apps/avelune_android"
        self.tool = self.root / "tool"
        self.tool.mkdir(parents=True)
        (self.root / "flutter_runtime").mkdir()
        shutil.copy2(SOURCE_ROOT / "tool/build_runtime.sh", self.tool / "build_runtime.sh")
        ios_tool = self.root.parent / "Avelune iOS/tool"
        ios_tool.mkdir(parents=True)
        shutil.copy2(IOS_TOOL / "patch_flutter_gpu.py", ios_tool / "patch_flutter_gpu.py")
        self.sdk = self.fixture / "Flutter SDK with spaces"
        self.sources = self.sdk / "bin/cache/pkg/flutter_gpu/lib/src"
        self.sources.mkdir(parents=True)
        for name, source in original_sdk_sources().items():
            (self.sources / name).write_text(source)
        self.flutter = self.sdk / "bin/flutter"
        self.flutter.write_text(STUB)
        self.flutter.chmod(0o755)
        gradle = self.root / "gradlew"
        gradle.write_text('#!/bin/bash\nexec "$RUNTIME_ROOT/tool/pipeline_stub" gradlew "$@"\n')
        gradle.chmod(0o755)
        stub = self.tool / "pipeline_stub"
        stub.write_text(STUB)
        stub.chmod(0o755)
        self.decoy = self.fixture / "decoy/bin"
        self.decoy.mkdir(parents=True)
        decoy_flutter = self.decoy / "flutter"
        decoy_flutter.write_text("#!/bin/bash\nexit 31\n")
        decoy_flutter.chmod(0o755)
        self.log = self.fixture / "events.jsonl"
        self.environment = {
            **os.environ,
            "PATH": str(self.decoy) + os.pathsep + os.environ["PATH"],
            "AVELUNE_FLUTTER_BIN": str(self.flutter),
            "RUNTIME_ROOT": str(self.root),
            "RUNTIME_SDK": str(self.sdk),
            "GPU_PATCH_TOOL": str(ios_tool / "patch_flutter_gpu.py"),
            "PIPELINE_LOG": str(self.log),
        }

    def run_pipeline(self, mode="debug"):
        return subprocess.run(
            ["/bin/bash", str(self.tool / "build_runtime.sh"), mode],
            env=self.environment,
            text=True,
            capture_output=True,
            timeout=20,
        )

    def events(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_each_mode_patches_the_generated_sdk_before_gradle(self):
        for mode in ["debug", "profile", "release"]:
            with self.subTest(mode=mode):
                self.log.unlink(missing_ok=True)
                result = self.run_pipeline(mode)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                events = self.events()
                self.assertEqual([event["command"] for event in events], ["flutter", "gradlew"])
                self.assertEqual(events[0]["arguments"], ["pub", "get"])
                self.assertTrue(events[1]["gpu_patch_ready"])
                self.assertIn("-Pflutter-root=" + str(self.sdk), events[1]["arguments"])
                self.assertEqual(events[1]["arguments"][-1], "assembleAar" + mode.title())

    def test_repeated_build_keeps_gpu_patch_idempotent(self):
        first = self.run_pipeline("profile")
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        patched = {path.name: path.read_bytes() for path in self.sources.iterdir()}
        self.assertEqual(
            (self.sources / "buffer.dart").read_text(),
            patch_flutter_gpu.patch_source((self.sources / "buffer.dart").read_text()),
        )
        second = self.run_pipeline("profile")
        self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
        self.assertIn("already applied", second.stdout)
        self.assertEqual(patched, {path.name: path.read_bytes() for path in self.sources.iterdir()})
        self.assertTrue(all(event["gpu_patch_ready"] for event in self.events() if event["command"] == "gradlew"))

    def test_unsupported_gpu_sdk_stops_before_gradle_without_partial_writes(self):
        (self.sources / "render_pass.dart").write_text("unsupported Flutter GPU lifecycle")
        original = {path.name: path.read_bytes() for path in self.sources.iterdir()}
        result = self.run_pipeline("release")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("Unsupported Flutter GPU", result.stderr)
        self.assertEqual([event["command"] for event in self.events()], ["flutter"])
        self.assertEqual(original, {path.name: path.read_bytes() for path in self.sources.iterdir()})

    def test_unsupported_mode_stops_before_pub_get(self):
        result = self.run_pipeline("custom")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(self.events(), [])


if __name__ == "__main__":
    unittest.main()
