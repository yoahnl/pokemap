import io
import struct
import subprocess
import sys
import tempfile
import unittest
import urllib.error
import zipfile
from pathlib import Path
from unittest.mock import Mock, patch

from publish_play import API, UPLOAD, PlayPublisher, PlayReviewInProgress
from read_app_version import read_app_version
from verify_release_bundle import PACKAGE, verify_elf_alignment, verify_libraries, verify_manifest


def manifest():
    return f'''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="{PACKAGE}" android:versionCode="3" android:versionName="1.0.1">
        <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="36"/>
        <application android:name="{PACKAGE}.AveluneApplication">
            <activity android:name="{PACKAGE}.presentation.MainActivity">
                <intent-filter><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
            </activity>
            <activity android:name="{PACKAGE}.runtime.SurfaceProbeActivity" android:enabled="false"/>
            <activity android:name="{PACKAGE}.runtime.SurfaceProbeCompanionActivity" android:enabled="false"/>
        </application>
    </manifest>'''


def library(alignment=16384):
    data = bytearray(120)
    data[:6] = b"\x7fELF\x02\x01"
    struct.pack_into("<Q", data, 32, 64)
    struct.pack_into("<HH", data, 54, 56, 1)
    struct.pack_into("<I", data, 64, 1)
    struct.pack_into("<Q", data, 112, alignment)
    return bytes(data)


class SharedAppVersionTest(unittest.TestCase):
    def test_reads_the_version_from_the_shared_xcode_configuration(self):
        with tempfile.TemporaryDirectory() as directory:
            configuration = Path(directory) / "version.xcconfig"
            configuration.write_text("MARKETING_VERSION = 2.4.6\n", encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(Path(__file__).with_name("read_app_version.py")), str(configuration)],
                capture_output=True,
                text=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "2.4.6")

    def test_rejects_missing_ambiguous_or_non_numeric_versions(self):
        with tempfile.TemporaryDirectory() as directory:
            configuration = Path(directory) / "version.xcconfig"
            for source in [
                "",
                "MARKETING_VERSION = 1.0\n",
                "MARKETING_VERSION = 1.0.2-beta\n",
                "MARKETING_VERSION = 1.0.2\nMARKETING_VERSION = 1.0.3\n",
                "CURRENT_PROJECT_VERSION = 20\n",
            ]:
                with self.subTest(source=source):
                    configuration.write_text(source, encoding="utf-8")
                    with self.assertRaisesRegex(ValueError, "single numeric MARKETING_VERSION"):
                        read_app_version(configuration)

    def test_missing_configuration_does_not_fall_back_to_an_old_version(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(FileNotFoundError):
                read_app_version(Path(directory) / "missing.xcconfig")


class BundleVerificationTest(unittest.TestCase):
    def test_native_identity_and_version(self):
        verify_manifest(manifest(), 3, "1.0.1")

    def test_wrong_identity_version_or_native_host_is_rejected(self):
        for original, replacement in [
            (PACKAGE, "another.application"),
            ('versionCode="3"', 'versionCode="2"'),
            ('versionName="1.0.1"', 'versionName="0.1.0"'),
            ('minSdkVersion="24"', 'minSdkVersion="26"'),
            ('targetSdkVersion="36"', 'targetSdkVersion="35"'),
            (".AveluneApplication", ".FlutterApplication"),
            (".presentation.MainActivity", ".FlutterActivity"),
            ('enabled="false"', 'enabled="true"'),
            ('<application android:name=', '<application android:debuggable="true" android:name='),
        ]:
            with self.subTest(replacement=replacement), self.assertRaises(ValueError):
                verify_manifest(manifest().replace(original, replacement), 3, "1.0.1")

    def test_16kb_elf_alignment(self):
        verify_elf_alignment(library())
        with self.assertRaises(ValueError):
            verify_elf_alignment(library(4096))
        data = bytearray(library())
        struct.pack_into("<Q", data, 72, 4096)
        with self.assertRaises(ValueError):
            verify_elf_alignment(data)

    def test_all_previously_supported_abis_are_required(self):
        archive = io.BytesIO()
        with zipfile.ZipFile(archive, "w") as bundle:
            for abi in ["armeabi-v7a", "arm64-v8a", "x86_64"]:
                for name in ["libapp.so", "libflutter.so"]:
                    bundle.writestr(f"base/lib/{abi}/{name}", library())
        with zipfile.ZipFile(archive) as bundle:
            self.assertEqual(len(verify_libraries(bundle)), 4)
        with zipfile.ZipFile(io.BytesIO(), "w") as bundle, self.assertRaises(ValueError):
            verify_libraries(bundle)


class PlayPublicationTest(unittest.TestCase):
    def publisher(self, responses):
        publisher = PlayPublisher("test-token")
        publisher.request = Mock(side_effect=responses)
        return publisher

    def test_next_code_includes_other_tracks_and_deletes_the_read_edit(self):
        publisher = self.publisher([
            {"id": "read"}, {"bundles": [{"versionCode": 2}]},
            {"tracks": [{"releases": [{"versionCodes": ["7"]}]}]}, {},
        ])
        self.assertEqual(publisher.next_code(), 8)
        publisher.request.assert_called_with("DELETE", API + "/read")

    def test_duplicate_code_is_rejected_before_upload(self):
        publisher = self.publisher([{"id": "edit"}, {"bundles": [{"versionCode": 3}]}, {}, {}])
        with self.assertRaises(ValueError):
            publisher.publish(Path("unused.aab"), 3, "1.0.1")
        self.assertFalse(any(UPLOAD in call.args[1] for call in publisher.request.call_args_list))
        publisher.request.assert_called_with("DELETE", API + "/edit")

    def test_upload_failure_discards_the_edit(self):
        publisher = self.publisher([{"id": "edit"}, {}, {}, RuntimeError("upload failed"), {}])
        bundle = Mock()
        bundle.read_bytes.return_value = b"bundle"
        with self.assertRaisesRegex(RuntimeError, "upload failed"):
            publisher.publish(bundle, 3, "1.0.1")
        publisher.request.assert_called_with("DELETE", API + "/edit")

    def test_publish_validates_commits_and_verifies_only_the_internal_track(self):
        publisher = self.publisher([
            {"id": "edit"}, {}, {}, {"versionCode": 3}, {}, {}, {},
            {"id": "verify"}, {"releases": [{"versionCodes": ["3"], "status": "completed"}]}, {},
        ])
        bundle = Mock()
        bundle.read_bytes.return_value = b"bundle"
        result = publisher.publish(bundle, 3, "1.0.1")
        self.assertEqual(result["status"], "completed")
        calls = publisher.request.call_args_list
        update = next(call for call in calls if call.args[0] == "PUT")
        self.assertEqual(update.args[1], API + "/edit/tracks/internal")
        self.assertEqual(update.args[2]["releases"][0]["versionCodes"], ["3"])
        self.assertTrue(any(call.args[1] == API + "/edit:validate" for call in calls))
        self.assertTrue(any(call.args[1] == API + "/edit:commit?changesInReviewBehavior=ERROR_IF_IN_REVIEW" for call in calls))
        publisher.request.assert_called_with("DELETE", API + "/verify")

    def test_promote_alpha_reuses_latest_completed_internal_bundle(self):
        release = {"name": "Avelune 1.0.5 (340)", "versionCodes": ["340"], "status": "completed", "releaseNotes": []}
        publisher = self.publisher([
            {"id": "edit"},
            {"releases": [{"versionCodes": ["341"], "status": "draft"}, release]},
            {"releases": [{"versionCodes": ["4"], "status": "completed"}]},
            {}, {}, {},
        ])

        result = publisher.promote_alpha()

        self.assertEqual(result, {"package": "com.yoahnl.avelune.player", "track": "alpha", "versionCode": 340, "status": "committed"})
        self.assertEqual(publisher.request.call_args_list[3].args, (
            "PUT", API + "/edit/tracks/alpha", {"track": "alpha", "releases": [release]},
        ))
        self.assertEqual(publisher.request.call_args_list[4].args[1], API + "/edit:validate")
        self.assertEqual(publisher.request.call_args_list[5].args[1], API + "/edit:commit?changesInReviewBehavior=ERROR_IF_IN_REVIEW")
        self.assertEqual(publisher.request.call_count, 6)

    def test_promote_alpha_does_not_rollback_or_replace_a_draft(self):
        for code, status, expected in ((340, "completed", "up_to_date"), (342, "completed", "up_to_date"), (4, "draft", "alpha_release_in_progress")):
            with self.subTest(code=code, status=status):
                publisher = self.publisher([
                    {"id": "edit"},
                    {"releases": [{"versionCodes": ["340"], "status": "completed"}]},
                    {"releases": [{"versionCodes": [str(code)], "status": status}]},
                    {},
                ])

                self.assertEqual(publisher.promote_alpha()["status"], expected)
                self.assertEqual(publisher.request.call_count, 4)
                publisher.request.assert_called_with("DELETE", API + "/edit")

    def test_promote_alpha_defers_when_google_is_reviewing_another_change(self):
        publisher = self.publisher([
            {"id": "edit"},
            {"releases": [{"versionCodes": ["340"], "status": "completed"}]},
            {"releases": [{"versionCodes": ["4"], "status": "completed"}]},
            {}, {},
            PlayReviewInProgress("changes in review"),
            {},
        ])

        self.assertEqual(publisher.promote_alpha()["status"], "review_in_progress")
        publisher.request.assert_called_with("DELETE", API + "/edit")

    def test_request_parses_google_review_conflict(self):
        error_body = b'{"error":{"message":"Changes in review","details":[{"reason":"CHANGES_ALREADY_IN_REVIEW"}]}}'
        error = urllib.error.HTTPError(API, 400, "Bad Request", {}, io.BytesIO(error_body))
        self.addCleanup(error.close)
        with patch("publish_play.urllib.request.urlopen", side_effect=error):
            with self.assertRaisesRegex(PlayReviewInProgress, "Changes in review"):
                PlayPublisher("test-token").request("POST", API)


if __name__ == "__main__":
    unittest.main()
