import json
import plistlib
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import package_studio_macos_engine as packager


DART_REVISION = "a" * 40
GIT_REVISION = "b" * 40
PATCHED_SOURCE = """
- (void)presentSurfaces:(NSArray*)surfaces
                 atTime:(CFTimeInterval)presentationTime
                 notify:(dispatch_block_t)notify {
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  [commandBuffer commit];
  [commandBuffer waitUntilCompleted];
  CGSize size = GetRequiredFrameSize(surfaces);
}
"""


class FakeTools:
    def __init__(self):
        self.commands = []
        self.app_architectures = "arm64 x86_64"
        self.framework_architectures = "arm64 x86_64"
        self.fail_verification = False
        self.fail_signing = False
        self.strip_entitlements = False
        self.fail_attribute_removal = False
        self.input_attributes = {}
        self.staged_attributes = {}
        self.staged_app = None
        self.entitlements = {
            "com.apple.security.app-sandbox": True,
            "com.apple.security.files.user-selected.read-write": True,
        }

    def __call__(self, command, **kwargs):
        self.commands.append(command)
        self.assert_arguments(kwargs)
        stdout, stderr, code = "", "", 0
        if command[0] == "lipo":
            stdout = (
                self.app_architectures
                if command[-1].endswith("/MacOS/Runner")
                else self.framework_architectures
            )
        elif command[0] == "git":
            stdout = GIT_REVISION + "\n"
        elif command[:3] == ["xattr", "-r", "-s"]:
            self.staged_app = Path(command[-1])
            self.staged_attributes = {
                relative: set(attributes)
                for relative, attributes in self.input_attributes.items()
            }
            stdout = "\n".join(
                f"{self.staged_app / relative}: {attribute}"
                for relative, attributes in self.staged_attributes.items()
                for attribute in sorted(attributes)
            )
        elif command[:3] == ["xattr", "-d", "-s"]:
            attribute, path = command[3], Path(command[4])
            if self.fail_attribute_removal:
                code, stderr = 1, "Attribute removal failed"
            else:
                relative = path.relative_to(self.staged_app).as_posix()
                self.staged_attributes[relative].remove(attribute)
        elif command[:2] == ["codesign", "-d"]:
            entitlements = self.entitlements
            if self.strip_entitlements and ".engine-" in command[-1]:
                entitlements = {}
            stdout = plistlib.dumps(entitlements).decode()
        elif command[:2] == ["codesign", "--verify"]:
            if self.fail_verification:
                code, stderr = 1, "Signature verification failed"
        elif command[:2] == ["codesign", "--force"]:
            target = Path(command[-1])
            if target.suffix == ".app":
                (target / "Contents/MacOS/Runner").write_bytes(b"signed runner")
                if self.fail_signing:
                    code, stderr = 1, "Signing failed after writing staged executable"
            else:
                (target / "Codesign.fake").write_bytes(b"signed framework")
        else:
            raise AssertionError(command)
        return subprocess.CompletedProcess(command, code, stdout, stderr)

    def assert_arguments(self, kwargs):
        if kwargs != {"capture_output": True, "text": True, "check": False}:
            raise AssertionError(kwargs)


class PackageStudioMacosEngineTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.app = self.root / "Original.app"
        self.output = self.root / "Patched.app"
        self.framework = self.root / "built/FlutterMacOS.framework"
        self.engine = self.root / "engine-source"
        self.sdk = self.root / "producer-sdk"
        self.binary = self.app / "Contents/MacOS/Runner"
        self.binary.parent.mkdir(parents=True)
        self.binary.write_bytes(b"original runner")
        (self.app / "Contents/Info.plist").write_bytes(
            plistlib.dumps({"CFBundleExecutable": "Runner"})
        )
        self.original_framework = self.app / "Contents/Frameworks/FlutterMacOS.framework"
        self.make_framework(self.original_framework, b"old engine")
        self.make_framework(self.framework, b"new engine")
        for checkout in (self.engine, self.sdk):
            checkout.mkdir()
            (checkout / "DEPS").write_text(f"vars = {{'dart_revision': '{DART_REVISION}'}}\n")
        self.source = self.engine / "engine/src/flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.mm"
        self.source.parent.mkdir(parents=True)
        self.source.write_text(PATCHED_SOURCE)
        self.tools = FakeTools()
        self.before = packager.tree_digest(self.app)

    def make_framework(self, path, contents):
        binary = path / "Versions/A/FlutterMacOS"
        binary.parent.mkdir(parents=True)
        binary.write_bytes(contents)
        (path / "Versions/Current").symlink_to("A", target_is_directory=True)
        (path / "FlutterMacOS").symlink_to("Versions/Current/FlutterMacOS")

    def run_package(self, **overrides):
        arguments = {
            "app": self.app,
            "output": self.output,
            "framework": self.framework,
            "engine_source": self.engine,
            "producer_flutter_sdk": self.sdk,
            "mode": "profile",
            "runner": self.tools,
        }
        arguments.update(overrides)
        return packager.package_app(**arguments)

    def assert_original_unchanged(self):
        self.assertEqual(packager.tree_digest(self.app), self.before)
        self.assertFalse(self.output.exists())
        self.assertEqual(list(self.root.glob(".Patched.engine-*")), [])

    def test_refuses_unpatched_source_before_running_tools(self):
        self.source.write_text(PATCHED_SOURCE.replace("[commandBuffer waitUntilCompleted];", ""))
        with self.assertRaisesRegex(packager.PackagingError, "completion fence"):
            self.run_package()
        self.assertEqual(self.tools.commands, [])
        self.assert_original_unchanged()

    def test_commented_fence_is_not_accepted(self):
        self.source.write_text(
            PATCHED_SOURCE.replace(
                "[commandBuffer waitUntilCompleted];",
                "// [commandBuffer waitUntilCompleted];",
            )
        )
        with self.assertRaisesRegex(packager.PackagingError, "completion fence"):
            self.run_package()
        self.assert_original_unchanged()

    def test_refuses_different_dart_revision(self):
        (self.sdk / "DEPS").write_text(f"vars = {{'dart_revision': '{'c' * 40}'}}\n")
        with self.assertRaisesRegex(packager.PackagingError, "Dart revision differs"):
            self.run_package()
        self.assertEqual(self.tools.commands, [])
        self.assert_original_unchanged()

    def test_refuses_framework_missing_an_app_architecture(self):
        self.tools.framework_architectures = "arm64"
        with self.assertRaisesRegex(packager.PackagingError, "do not cover"):
            self.run_package()
        self.assert_original_unchanged()

    def test_failed_verification_preserves_original_and_removes_staging(self):
        self.tools.fail_verification = True
        with self.assertRaisesRegex(packager.PackagingError, "Signature verification failed"):
            self.run_package()
        self.assert_original_unchanged()

    def test_failed_signing_after_staged_mutation_preserves_original(self):
        self.tools.fail_signing = True
        with self.assertRaisesRegex(packager.PackagingError, "Signing failed"):
            self.run_package()
        self.assert_original_unchanged()

    def test_failed_copy_preserves_original(self):
        real_copy = shutil.copytree
        def fail_framework_copy(source, destination, *args, **kwargs):
            if Path(source) == self.framework:
                raise OSError("Interrupted framework copy")
            return real_copy(source, destination, *args, **kwargs)

        with patch.object(packager.shutil, "copytree", side_effect=fail_framework_copy):
            with self.assertRaisesRegex(OSError, "Interrupted framework copy"):
                self.run_package()
        self.assert_original_unchanged()

    def test_refuses_lost_entitlements(self):
        self.tools.strip_entitlements = True
        with self.assertRaisesRegex(packager.PackagingError, "retain its original entitlements"):
            self.run_package()
        self.assert_original_unchanged()

    def test_success_publishes_only_new_app_and_signed_receipt(self):
        receipt = self.run_package()
        self.assertEqual(packager.tree_digest(self.app), self.before)
        self.assertEqual(self.binary.read_bytes(), b"original runner")
        packaged = self.output / "Contents/Frameworks/FlutterMacOS.framework"
        self.assertEqual((packaged / "FlutterMacOS").read_bytes(), b"new engine")
        self.assertEqual((self.output / "Contents/MacOS/Runner").read_bytes(), b"signed runner")
        self.assertTrue((packaged / "Versions/Current").is_symlink())
        receipt_path = self.output / "Contents/Resources/avelune-native-engine-receipt.json"
        self.assertEqual(json.loads(receipt_path.read_text()), receipt)
        self.assertEqual(receipt["dartRevision"], DART_REVISION)
        self.assertEqual(receipt["engineRevision"], GIT_REVISION)
        self.assertEqual(receipt["mode"], "profile")
        self.assertEqual(receipt["appArchitectures"], ["arm64", "x86_64"])
        self.assertEqual(receipt["originalFramework"], packager.tree_digest(self.original_framework))
        self.assertEqual(receipt["packagedFramework"], packager.tree_digest(packaged))
        signed = [command for command in self.tools.commands if command[:2] == ["codesign", "--force"]]
        self.assertEqual(len(signed), 2)
        self.assertTrue(all(str(self.app) != command[-1] for command in signed))
        self.assertEqual(list(self.root.glob(".Patched.engine-*")), [])

    def test_refuses_symlink_escaping_replacement_framework(self):
        (self.framework / "escape").symlink_to("../../producer-sdk/DEPS")
        with self.assertRaisesRegex(packager.PackagingError, "escapes"):
            self.run_package()
        self.assert_original_unchanged()

    def test_refuses_absolute_internal_symlink_that_would_point_to_source_after_copy(self):
        (self.app / "Contents/absolute").symlink_to(self.binary)
        changed_before = packager.tree_digest(self.app)
        with self.assertRaisesRegex(packager.PackagingError, "Absolute bundle symlink"):
            self.run_package()
        self.assertEqual(packager.tree_digest(self.app), changed_before)
        self.assertFalse(self.output.exists())

    def test_refuses_existing_output_without_replacing_it(self):
        self.output.mkdir()
        marker = self.output / "keep"
        marker.write_text("existing output")
        with self.assertRaisesRegex(packager.PackagingError, "new, absent"):
            self.run_package()
        self.assertEqual(marker.read_text(), "existing output")
        self.assertEqual(packager.tree_digest(self.app), self.before)

    def test_refuses_sdk_and_applications_destinations(self):
        destinations = [
            self.sdk / "Patched.app",
            self.engine / "Patched.app",
            self.app / "Patched.app",
            self.root / "Applications/Patched.app",
        ]
        destinations[-1].parent.mkdir()
        for destination in destinations:
            with self.subTest(destination=destination):
                with self.assertRaisesRegex(packager.PackagingError, "outside Applications"):
                    self.run_package(output=destination)
                self.assertFalse(destination.exists())
        self.assert_original_unchanged()

    def test_refuses_symlinked_output_parent(self):
        alias = self.root / "alias"
        alias.symlink_to(self.sdk, target_is_directory=True)
        with self.assertRaisesRegex(packager.PackagingError, "canonical"):
            self.run_package(output=alias / "Patched.app")
        self.assert_original_unchanged()

    def test_refuses_destination_in_another_detectable_flutter_sdk(self):
        another = self.root / "another-sdk"
        (another / "bin").mkdir(parents=True)
        (another / "bin/flutter").write_text("flutter")
        (another / "DEPS").write_text("deps")
        with self.assertRaisesRegex(packager.PackagingError, "outside Applications"):
            self.run_package(output=another / "Patched.app")
        self.assert_original_unchanged()

    def test_refuses_deps_symlink_outside_checkout(self):
        deps = self.engine / "DEPS"
        deps.unlink()
        deps.symlink_to("../producer-sdk/DEPS")
        with self.assertRaisesRegex(packager.PackagingError, "Missing Flutter DEPS"):
            self.run_package()
        self.assert_original_unchanged()

    def test_strips_only_signing_detritus_from_staged_root_and_files(self):
        attributes = {
            ".": {"com.apple.FinderInfo", "com.apple.ResourceFork", "com.apple.metadata:test"},
            "Contents/MacOS/Runner": {"com.apple.FinderInfo", "com.apple.quarantine"},
            "Contents/Frameworks/FlutterMacOS.framework/Versions/A/FlutterMacOS": {
                "com.apple.ResourceFork", "com.example.retained",
            },
            "Contents/Frameworks/FlutterMacOS.framework/FlutterMacOS": {
                "com.apple.FinderInfo",
            },
        }
        self.tools.input_attributes = {
            relative: set(values) for relative, values in attributes.items()
        }

        receipt = self.run_package()

        self.assertEqual(self.tools.input_attributes, attributes)
        self.assertEqual(self.tools.staged_attributes["."], {"com.apple.metadata:test"})
        self.assertEqual(
            self.tools.staged_attributes["Contents/MacOS/Runner"],
            {"com.apple.quarantine"},
        )
        self.assertEqual(
            self.tools.staged_attributes[
                "Contents/Frameworks/FlutterMacOS.framework/Versions/A/FlutterMacOS"
            ],
            {"com.example.retained"},
        )
        self.assertEqual(
            self.tools.staged_attributes["Contents/Frameworks/FlutterMacOS.framework/FlutterMacOS"],
            {"com.apple.FinderInfo"},
        )
        self.assertEqual(packager.tree_digest(self.app), self.before)
        self.assertEqual(len(receipt["removedSigningAttributes"]), 4)
        deletions = [
            command for command in self.tools.commands
            if command[:3] == ["xattr", "-d", "-s"]
        ]
        self.assertEqual(len(deletions), 4)
        self.assertEqual(
            {command[3] for command in deletions},
            {"com.apple.FinderInfo", "com.apple.ResourceFork"},
        )
        self.assertTrue(all(
            packager.contained(Path(command[4]), self.tools.staged_app)
            for command in deletions
        ))
        self.assertEqual(receipt["removedSigningAttributes"][0]["path"], ".")

    def test_attribute_removal_failure_does_not_mutate_input_or_publish(self):
        self.tools.input_attributes = {".": {"com.apple.FinderInfo"}}
        self.tools.fail_attribute_removal = True

        with self.assertRaisesRegex(packager.PackagingError, "Attribute removal failed"):
            self.run_package()

        self.assertEqual(self.tools.input_attributes, {".": {"com.apple.FinderInfo"}})
        self.assert_original_unchanged()


if __name__ == "__main__":
    unittest.main()
