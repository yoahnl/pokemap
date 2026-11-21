import argparse
import json
import os
import urllib.error
import urllib.request
from pathlib import Path


PACKAGE = "com.yoahnl.avelune.player"
INTERNAL_TRACK = "internal"
ALPHA_TRACK = "alpha"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/edits"
UPLOAD = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE}/edits"


class PlayReviewInProgress(RuntimeError):
    pass


class PlayPublisher:
    def __init__(self, token):
        self.token = token

    def request(self, method, url, body=None, binary=False):
        data = body if binary else json.dumps(body).encode() if body is not None else None
        headers = {"Authorization": "Bearer " + self.token}
        if data is not None:
            headers["Content-Type"] = "application/octet-stream" if binary else "application/json"
        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=600) as response:
                data = response.read()
                return json.loads(data) if data else {}
        except urllib.error.HTTPError as error:
            detail = json.loads(error.read()).get("error", {})
            message = detail.get("message", "Google Play request failed")
            if error.code == 400 and any(item.get("reason") == "CHANGES_ALREADY_IN_REVIEW" for item in detail.get("details", [])):
                raise PlayReviewInProgress(message) from None
            raise RuntimeError(f"Google Play HTTP {error.code}: {message}") from None

    def commit_release(self, edit, track, release):
        self.request("PUT", f"{API}/{edit}/tracks/{track}", {
            "track": track,
            "releases": [release],
        })
        self.request("POST", f"{API}/{edit}:validate")
        self.request("POST", f"{API}/{edit}:commit?changesInReviewBehavior=ERROR_IF_IN_REVIEW")

    def maximum_code(self, edit):
        bundles = self.request("GET", f"{API}/{edit}/bundles").get("bundles", [])
        tracks = self.request("GET", f"{API}/{edit}/tracks").get("tracks", [])
        codes = [int(bundle["versionCode"]) for bundle in bundles]
        codes.extend(int(code) for track in tracks for release in track.get("releases", []) for code in release.get("versionCodes", []))
        return max([2, *codes])

    def next_code(self):
        edit = self.request("POST", API, {})["id"]
        try:
            code = self.maximum_code(edit) + 1
            if code > 2100000000:
                raise ValueError("Android versionCode limit reached")
            return code
        finally:
            self.request("DELETE", f"{API}/{edit}")

    def publish(self, bundle, code, name):
        edit = self.request("POST", API, {})["id"]
        committed = False
        try:
            if code <= self.maximum_code(edit):
                raise ValueError("The version code must be newer than every existing Play artifact")
            uploaded = self.request("POST", f"{UPLOAD}/{edit}/bundles?uploadType=media", bundle.read_bytes(), binary=True)
            if int(uploaded["versionCode"]) != code:
                raise ValueError("Google Play uploaded an unexpected bundle version")
            self.commit_release(edit, INTERNAL_TRACK, {
                "name": f"Avelune {name} ({code}) — Kotlin",
                "versionCodes": [str(code)],
                "status": "completed",
                "releaseNotes": [{
                    "language": "fr-FR",
                    "text": "Nouvelle application Android native avec le runtime Avelune partagé et la prise en charge des deux écrans sur AYN Thor.",
                }],
            })
            committed = True
        finally:
            if not committed:
                self.request("DELETE", f"{API}/{edit}")
        verification = self.request("POST", API, {})["id"]
        try:
            track = self.request("GET", f"{API}/{verification}/tracks/{INTERNAL_TRACK}")
            if not any(str(code) in release.get("versionCodes", []) and release.get("status") == "completed" for release in track.get("releases", [])):
                raise RuntimeError("The committed internal release could not be verified")
            return {"package": PACKAGE, "track": INTERNAL_TRACK, "versionCode": code, "status": "completed"}
        finally:
            self.request("DELETE", f"{API}/{verification}")

    def promote_alpha(self):
        edit = self.request("POST", API, {})["id"]
        committed = False
        result = {"package": PACKAGE, "track": ALPHA_TRACK}
        try:
            internal = self.request("GET", f"{API}/{edit}/tracks/{INTERNAL_TRACK}").get("releases", [])
            candidates = (
                (int(code), release)
                for release in internal if release.get("status") == "completed"
                for code in release.get("versionCodes", [])
            )
            code, source = max(candidates, key=lambda candidate: candidate[0], default=(None, None))
            if source is None:
                return {**result, "status": "no_internal_release"}
            result["versionCode"] = code

            alpha = self.request("GET", f"{API}/{edit}/tracks/{ALPHA_TRACK}").get("releases", [])
            if any(release.get("status") != "completed" for release in alpha):
                return {**result, "status": "alpha_release_in_progress"}
            if any(int(current) >= code for release in alpha for current in release.get("versionCodes", [])):
                return {**result, "status": "up_to_date"}

            release = {
                "name": source.get("name") or f"Avelune ({code})",
                "versionCodes": [str(code)],
                "status": "completed",
                "releaseNotes": source.get("releaseNotes", []),
            }
            self.commit_release(edit, ALPHA_TRACK, release)
            committed = True
            return {**result, "status": "committed"}
        except PlayReviewInProgress:
            return {**result, "status": "review_in_progress"}
        finally:
            if not committed:
                self.request("DELETE", f"{API}/{edit}")


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("next-code")
    commands.add_parser("promote-alpha")
    publish = commands.add_parser("publish")
    publish.add_argument("bundle", type=Path)
    publish.add_argument("--version-code", required=True, type=int)
    publish.add_argument("--version-name", required=True)
    args = parser.parse_args()
    publisher = PlayPublisher(os.environ["GOOGLE_ACCESS_TOKEN"])
    if args.command == "next-code":
        print(publisher.next_code())
    elif args.command == "promote-alpha":
        print(json.dumps(publisher.promote_alpha(), indent=2))
    else:
        print(json.dumps(publisher.publish(args.bundle, args.version_code, args.version_name), indent=2))


if __name__ == "__main__":
    main()
