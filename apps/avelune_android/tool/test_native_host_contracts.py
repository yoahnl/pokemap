import re
import unittest
from pathlib import Path

from publish_play import PACKAGE as PLAY_PACKAGE
from verify_release_bundle import PACKAGE as RELEASE_PACKAGE


REPOSITORY = Path(__file__).resolve().parents[3]
STORE_IDENTITY = "com.yoahnl.avelune.player"


def source(path):
    return (REPOSITORY / path).read_text()


class NativeHostContractsTest(unittest.TestCase):
    def test_swiftui_host_preserves_the_configurable_app_store_identity(self):
        project = source("apps/Avelune iOS/project.yml")
        xcode_project = source("apps/Avelune iOS/AveluneiOS.xcodeproj/project.pbxproj")
        self.assertRegex(
            project,
            rf"(?m)^\s+AVELUNE_APP_BUNDLE_ID:\s+{re.escape(STORE_IDENTITY)}\s*$",
        )
        self.assertIn('PRODUCT_BUNDLE_IDENTIFIER: "$(AVELUNE_APP_BUNDLE_ID)"', project)
        self.assertIn('PRODUCT_BUNDLE_IDENTIFIER: "$(AVELUNE_APP_BUNDLE_ID).tests"', project)
        self.assertIn('PRODUCT_BUNDLE_IDENTIFIER: "$(AVELUNE_APP_BUNDLE_ID).uitests"', project)
        defaults = re.findall(r"AVELUNE_APP_BUNDLE_ID = ([^;]+);", xcode_project)
        self.assertTrue(defaults)
        self.assertEqual(set(defaults), {STORE_IDENTITY})
        identities = set(re.findall(r"PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);", xcode_project))
        self.assertEqual(
            identities,
            {
                '"$(AVELUNE_APP_BUNDLE_ID)"',
                '"$(AVELUNE_APP_BUNDLE_ID).tests"',
                '"$(AVELUNE_APP_BUNDLE_ID).uitests"',
            },
        )
        self.assertIn("import SwiftUI", source("apps/Avelune iOS/AveluneiOS/AveluneApp.swift"))
        self.assertIn("struct AveluneApp: App", source("apps/Avelune iOS/AveluneiOS/AveluneApp.swift"))
        self.assertIn(
            "path: flutter_runtime/build/swift-package/FlutterNativeIntegration",
            project,
        )

    def test_kotlin_host_preserves_the_configurable_play_identity(self):
        gradle = source("apps/avelune_android/app/build.gradle.kts")
        self.assertRegex(gradle, rf'namespace\s*=\s*"{re.escape(STORE_IDENTITY)}"')
        self.assertRegex(
            gradle,
            rf'applicationId\s*=\s*providers\.gradleProperty\("aveluneApplicationId"\)'
            rf'\s*\.orElse\("{re.escape(STORE_IDENTITY)}"\)\.get\(\)',
        )
        self.assertIn("com.yoahnl.avelune.runtime.android:flutter_release:1.0", gradle)
        manifest = source("apps/avelune_android/app/src/main/AndroidManifest.xml")
        self.assertIn('android:name=".AveluneApplication"', manifest)
        self.assertIn('android:name=".presentation.MainActivity"', manifest)
        activity = source(
            "apps/avelune_android/app/src/main/kotlin/com/yoahnl/avelune/player/"
            "presentation/MainActivity.kt"
        )
        self.assertIn("class MainActivity : ComponentActivity()", activity)
        self.assertIn("setContent {", activity)
        self.assertEqual(PLAY_PACKAGE, STORE_IDENTITY)
        self.assertEqual(RELEASE_PACKAGE, STORE_IDENTITY)

    def test_both_native_hosts_embed_the_shared_game_runtime(self):
        for host in ("Avelune iOS", "avelune_android"):
            with self.subTest(host=host):
                module = source(f"apps/{host}/flutter_runtime/pubspec.yaml")
                self.assertRegex(module, r"(?m)^  pokemap_hub:\s*\n    path: ../../pokemap_hub\s*$")
                entrypoint = source(f"apps/{host}/flutter_runtime/lib/main.dart")
                self.assertIn("package:pokemap_hub/avelune_embedded_runtime.dart", entrypoint)
                self.assertIn("runAveluneEmbeddedRuntime()", entrypoint)
        self.assertIn(
            "HubInstalledGamePlayer(",
            source("apps/pokemap_hub/lib/embedding/avelune_runtime_app.dart"),
        )
        self.assertIn(
            "InstallGamePackageUseCase",
            source("apps/pokemap_hub/lib/embedding/avelune_library_bridge.dart"),
        )

    def test_retired_flutter_mobile_hosts_have_no_distribution_runners(self):
        for runner in (
            "apps/pokemap_hub/ios/Runner.xcodeproj/project.pbxproj",
            "apps/pokemap_hub/android/app/build.gradle.kts",
            "apps/pokemap_hub/lib/main.dart",
        ):
            with self.subTest(runner=runner):
                self.assertFalse((REPOSITORY / runner).exists(), runner)

    def test_android_distribution_uses_the_native_release_pipeline(self):
        workflow = source(".github/workflows/avelune_android_release.yml")
        self.assertIn("apps/avelune_android/tool/build_runtime.sh release", workflow)
        self.assertIn("apps/avelune_android/tool/publish_play.py", workflow)
        self.assertIn("apps/avelune_android/tool/verify_release_bundle.py", workflow)
        self.assertIn("python3 -m unittest discover -s apps/avelune_android/tool", workflow)
        self.assertIn("apps/avelune_android/tool/build_android.sh", workflow)
        self.assertIn(":app:bundleRelease", workflow)

    def test_quick_checks_watch_only_the_shared_hub_library(self):
        workflow = source(".github/workflows/pokemap_quick_checks.yml")
        filters = re.findall(
            r"(?m)^\s+-\s*['\"]?apps/pokemap_hub/lib/\*\*['\"]?\s*$",
            workflow,
        )
        self.assertEqual(len(filters), 2)
        for trigger, next_section in (("pull_request", "push"), ("push", "permissions")):
            with self.subTest(trigger=trigger):
                section = workflow.split(f"  {trigger}:", 1)[1].split(f"{next_section}:", 1)[0]
                self.assertIn("apps/pokemap_hub/lib/**", section)
                self.assertIn("apps/Avelune iOS/**", section)
                self.assertIn("apps/avelune_android/**", section)
        self.assertIsNone(
            re.search(r"(?m)^\s+-\s*['\"]?apps/pokemap_hub/\*\*['\"]?\s*$", workflow),
            "Quick checks must watch the embedded library without selecting the retired Hub app",
        )

    def test_quick_checks_and_certification_execute_the_native_host_contracts(self):
        for name in ("pokemap_quick_checks.yml", "pokemap_product_certification.yml"):
            with self.subTest(workflow=name):
                workflow = source(f".github/workflows/{name}").replace("\\\n", " ")
                self.assertIsNotNone(
                    re.search(
                        r"python3\s+-m\s+unittest\s+discover\s+"
                        r"-s\s+apps/avelune_android/tool\s+"
                        r"-p\s+['\"]test_native_host_contracts\.py['\"]",
                        workflow,
                    ),
                    f"{name} must execute the native host contracts",
                )

    def test_workflows_do_not_run_the_retired_hub_application(self):
        forbidden = (
            r"(?m)^\s*working-directory:\s*['\"]?apps/pokemap_hub(?:/|['\"]|\s|$)",
            r"(?m)^\s*cd\s+['\"]?apps/pokemap_hub(?:/|['\"]|\s|$)",
            r"flutter\s+build\s+(?:ios|appbundle)\b",
        )
        workflows = sorted((REPOSITORY / ".github/workflows").glob("*.yml"))
        self.assertTrue(workflows)
        for workflow in workflows:
            with self.subTest(workflow=workflow.name):
                content = workflow.read_text()
                for pattern in forbidden:
                    self.assertIsNone(
                        re.search(pattern, content),
                        f"{workflow.name} contains a retired application command: {pattern}",
                    )


if __name__ == "__main__":
    unittest.main()
