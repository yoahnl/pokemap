import json
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

import patch_flutter_gpu
from test_flutter_gpu_host_buffer import original_sdk_sources


SOURCE_ROOT = pathlib.Path(__file__).resolve().parents[1]
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
if command == "flutter" and arguments[:2] == ["build", "swift-package"]:
    spec = importlib.util.spec_from_file_location("gpu_patch", os.environ["GPU_PATCH_TOOL"])
    patch = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(patch)
    directory = pathlib.Path(os.environ["GPU_BUFFER_SOURCE"]).parent
    gpu_patch_ready = all(
        (source := (directory / name).read_text()) == transform(source)
        for name, transform in [
            ("buffer.dart", patch.patch_source),
            ("command_buffer.dart", patch.patch_command_source),
            ("render_pass.dart", patch.patch_render_pass_source),
        ]
    )
event = {
    "command": command,
    "arguments": arguments,
    "configuration": os.environ.get("CONFIGURATION"),
    "mode": os.environ.get("FLUTTER_BUILD_MODE"),
    "output": os.environ.get("FLUTTER_SWIFT_PACKAGE_OUTPUT"),
    "gpu_patch_ready": gpu_patch_ready,
}
with open(os.environ["PIPELINE_LOG"], "a") as log:
    log.write(json.dumps(event) + "\n")
if command == "flutter" and arguments[:2] == ["build", "swift-package"]:
    output = pathlib.Path(arguments[arguments.index("-o") + 1])
    package = output / "FlutterNativeIntegration"
    package.mkdir(parents=True, exist_ok=True)
    for mode in ["Debug", "Release"]:
        (package / mode).mkdir(exist_ok=True)
    (package / "FlutterPluginRegistrant").symlink_to("./Release")
    (package / "Package.swift").write_text('        .package(name: "FlutterNativeTools", path: "FlutterNativeTools"),\n')
    video = package / ".plugins/video_player_avfoundation/darwin/video_player_avfoundation/Package.swift"
    video.parent.mkdir(parents=True)
    video.write_text('      name: "video_player_avfoundation_objc",\n      dependencies: [\n      ],\n      name: "video_player_avfoundation_ios",\n')
    script = output / "Scripts/flutter_integration.sh"
    script.parent.mkdir(parents=True)
    script.write_text('#!/bin/bash\nexec pipeline_stub "$@"\n')
if command == "prebuild":
    if os.environ.get("FAIL_PREBUILD"):
        sys.exit(7)
    package = pathlib.Path(os.environ["FLUTTER_SWIFT_PACKAGE_OUTPUT"]) / "FlutterNativeIntegration"
    link = package / "FlutterPluginRegistrant"
    link.unlink()
    link.symlink_to("./" + os.environ["CONFIGURATION"])
if command == "xcodebuild":
    package = pathlib.Path(os.environ["FLUTTER_SWIFT_PACKAGE_OUTPUT"]) / "FlutterNativeIntegration"
    if os.readlink(package / "FlutterPluginRegistrant") != "./" + os.environ["CONFIGURATION"]:
        sys.exit(8)
'''


class BuildPipelineTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="avelune-build-pipeline-")
        self.addCleanup(self.directory.cleanup)
        self.root = pathlib.Path(self.directory.name) / "Avelune iOS"
        self.tool = self.root / "tool"
        self.tool.mkdir(parents=True)
        (self.root / "flutter_runtime").mkdir()
        for name in ["build_runtime.sh", "build_ios.sh", "patch_swift_package.py", "patch_flutter_gpu.py"]:
            source = SOURCE_ROOT / "tool" / name
            if source.exists():
                shutil.copy2(source, self.tool / name)
        self.bin = pathlib.Path(self.directory.name) / "bin"
        self.bin.mkdir()
        self.gpu_buffer = self.bin / "cache/pkg/flutter_gpu/lib/src/buffer.dart"
        self.gpu_buffer.parent.mkdir(parents=True)
        for name, source in original_sdk_sources().items():
            self.gpu_buffer.with_name(name).write_text(source)
        for command in ["flutter", "xcodegen", "xcodebuild", "pipeline_stub"]:
            stub = self.bin / command
            stub.write_text(STUB)
            stub.chmod(0o755)
        self.log = pathlib.Path(self.directory.name) / "events.jsonl"
        self.environment = {
            **os.environ,
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "PIPELINE_LOG": str(self.log),
            "GPU_PATCH_TOOL": str(self.tool / "patch_flutter_gpu.py"),
            "GPU_BUFFER_SOURCE": str(self.gpu_buffer),
        }
        self.environment.pop("CONFIGURATION", None)
        self.environment.pop("FLUTTER_BUILD_MODE", None)

    def run_script(self, name, configuration=None, arguments=(), **environment):
        script = self.tool / name
        self.assertTrue(script.exists(), f"Missing build orchestration: {name}")
        values = {**self.environment, **environment}
        if configuration is not None:
            values["CONFIGURATION"] = configuration
        return subprocess.run(
            ["/bin/bash", str(script), *arguments],
            env=values,
            text=True,
            capture_output=True,
            timeout=20,
        )

    def events(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def clear_events(self):
        self.log.unlink(missing_ok=True)

    def prepare_package(self):
        result = self.run_script("build_runtime.sh")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.clear_events()

    def test_runtime_selects_debug_after_building_both_modes(self):
        result = self.run_script("build_runtime.sh", arguments=["--no-codesign"])
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        events = self.events()
        self.assertEqual([event["command"] for event in events], ["flutter", "flutter", "prebuild", "xcodegen"])
        self.assertEqual(events[1]["arguments"].count("--build-mode"), 2)
        self.assertIn("--no-codesign", events[1]["arguments"])
        self.assertEqual(events[2]["configuration"], "Debug")
        self.assertEqual(events[2]["mode"], "debug")
        self.assertEqual(os.readlink(self.root / "flutter_runtime/build/swift-package/FlutterNativeIntegration/FlutterPluginRegistrant"), "./Debug")

    def test_runtime_selects_release_explicitly(self):
        result = self.run_script("build_runtime.sh", "Release", FLUTTER_BUILD_MODE="debug")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        prebuilds = [event for event in self.events() if event["command"] == "prebuild"]
        self.assertEqual(len(prebuilds), 1)
        prebuild = prebuilds[0]
        self.assertEqual(prebuild["configuration"], "Release")
        self.assertEqual(prebuild["mode"], "release")

    def test_runtime_applies_gpu_patch_before_compilation(self):
        result = self.run_script("build_runtime.sh")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("HostBuffer block reuse", result.stdout)
        compilation = next(event for event in self.events() if event["arguments"][:2] == ["build", "swift-package"])
        self.assertTrue(compilation["gpu_patch_ready"])
        self.assertEqual(
            self.gpu_buffer.read_text(),
            patch_flutter_gpu.patch_source(self.gpu_buffer.read_text()),
        )
        self.assertIn(
            patch_flutter_gpu.COMMAND_MEMORY_PRESSURE,
            self.gpu_buffer.with_name("command_buffer.dart").read_text(),
        )
        self.assertIn(
            "_commandBuffer._recordDraw();",
            self.gpu_buffer.with_name("render_pass.dart").read_text(),
        )

    def test_runtime_stops_before_compilation_if_gpu_patch_cannot_be_applied(self):
        self.gpu_buffer.write_text("unsupported Flutter GPU allocator")
        result = self.run_script("build_runtime.sh")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("could not be identified", result.stderr)
        self.assertEqual([event["arguments"] for event in self.events()], [["pub", "get"]])

    def test_runtime_rejects_unsupported_configuration_before_building(self):
        for configuration in ["Profile", "Debug-Custom", ""]:
            with self.subTest(configuration=configuration):
                result = self.run_script("build_runtime.sh", configuration)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertEqual(self.events(), [])

    def test_runtime_stops_when_prebuild_fails(self):
        result = self.run_script("build_runtime.sh", FAIL_PREBUILD="1")
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        self.assertNotIn("xcodegen", [event["command"] for event in self.events()])

    def test_host_selects_mode_before_xcode_package_resolution(self):
        self.prepare_package()
        for configuration, mode in [("Release", "release"), ("Debug", "debug")]:
            with self.subTest(configuration=configuration):
                self.clear_events()
                result = self.run_script("build_ios.sh", configuration, FLUTTER_BUILD_MODE="profile")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                events = self.events()
                self.assertEqual([event["command"] for event in events], ["prebuild", "xcodebuild"])
                self.assertEqual(events[0]["configuration"], configuration)
                self.assertEqual(events[0]["mode"], mode)
                arguments = events[1]["arguments"]
                self.assertEqual(arguments[arguments.index("-configuration") + 1], configuration)
                self.assertEqual(arguments[arguments.index("-destination") + 1], "generic/platform=iOS")
                self.assertIn("CODE_SIGNING_ALLOWED=NO", arguments)
                self.assertEqual(arguments[-1], "build")

    def test_host_stops_when_prebuild_fails(self):
        self.prepare_package()
        result = self.run_script("build_ios.sh", FAIL_PREBUILD="1")
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        self.assertEqual([event["command"] for event in self.events()], ["prebuild"])

    def test_host_rejects_unsupported_configuration(self):
        for configuration in ["Profile", "Release-Custom", ""]:
            with self.subTest(configuration=configuration):
                result = self.run_script("build_ios.sh", configuration)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertEqual(self.events(), [])

    def test_host_rejects_configuration_argument_override(self):
        for arguments in [
            ["-configuration", "Release"],
            ["CONFIGURATION=Release"],
            ["FLUTTER_BUILD_MODE=release"],
            ["FLUTTER_SWIFT_PACKAGE_OUTPUT=/tmp/another-package"],
        ]:
            with self.subTest(arguments=arguments):
                result = self.run_script("build_ios.sh", arguments=arguments)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertEqual(self.events(), [])

    def test_host_rejects_missing_package_before_starting_xcode(self):
        result = self.run_script("build_ios.sh")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("build_runtime.sh", result.stderr)
        self.assertEqual(self.events(), [])

    def test_simulator_pipeline_prepares_debug_before_xcode(self):
        source = (SOURCE_ROOT / "tool/build_simulator.sh").read_text()
        self.assertIn("CONFIGURATION=Debug FLUTTER_BUILD_MODE=debug", source)
        self.assertLess(source.index('flutter_integration.sh" prebuild'), source.index("xcodebuild"))

    def test_cloud_selects_release_through_runtime_pipeline(self):
        source = (SOURCE_ROOT / "ci_scripts/ci_post_clone.sh").read_text()
        self.assertIn("CONFIGURATION=Release ./tool/build_runtime.sh --no-codesign", source)
        self.assertNotIn("ln -sfn ./Release", source)


if __name__ == "__main__":
    unittest.main()
