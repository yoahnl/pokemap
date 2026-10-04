import io
import struct
import unittest
import zipfile
from pathlib import Path
from unittest.mock import Mock

from publish_play import API, UPLOAD, PlayPublisher
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
        self.assertTrue(any(call.args[1] == API + "/edit:commit" for call in calls))
        publisher.request.assert_called_with("DELETE", API + "/verify")


if __name__ == "__main__":
    unittest.main()
