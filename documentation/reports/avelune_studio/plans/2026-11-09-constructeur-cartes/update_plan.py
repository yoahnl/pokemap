import argparse
import datetime
import difflib
import hashlib
import json
import math
import re
import shutil
import struct
import subprocess
import sys
import zlib
from functools import lru_cache
from pathlib import Path
from urllib.parse import unquote, urljoin, urlparse

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
DECODER_REPO = REPO
PLAN = ROOT / "ui-replacement-plan.json"
WEIGHTS = {"structure": 40, "typography": 15, "spacing": 15, "controls": 15, "states": 15}
METRICS = {"layoutMaxShiftLogicalPx": 8, "panelWidthRelativeError": 0.02, "textMaxDeltaLogicalPx": 1, "spacingMaxDeltaLogicalPx": 4}
RETIREMENT_KINDS = {**{f"RUI-{number:03}": "retirement" for number in range(5, 10)}, "RUI-010": "retirement_gate"}
LOT_KINDS = {
    "RUI-001": "preparation", "RUI-002": "preparation",
    "RUI-003": "design_baseline", "RUI-004": "evidence_framework",
    **RETIREMENT_KINDS,
    **{f"RUI-{number:03}": "native_ui" for number in range(11, 85)},
    **{f"RUI-{number:03}": "native_acceptance" for number in range(85, 88)},
    "RUI-088": "final_gate",
}
RETIREMENT_CAPTURES = {("RUI-006", "S01"), ("RUI-008", "S02"), ("RUI-010", "S01")}
STATE_PROFILE_EXCEPTIONS = {("RUI-013", "S02"): {"twoD"}, ("RUI-013", "S03"): {"threeD"}}
REQUIREMENTS_REVISION = "2026-11-11-retirement-decoupled-from-visual-targets-v1"
REQUIREMENTS_SHA256 = "7ffffaf8a26950efc4470e2e2f3e3886749adb0bb623829e10e1f713d257256b"
G0_TOOL_FILES = {"apps/avelune_studio/tools/" + name for name in ("t01_check_g0.dart", "t01_retirement_gate.dart", "t01_dependency_graph.dart", "t01_dart_lexing.dart", "t01_consumer_entries.dart", "t01_validate_screenshot.dart")}
DOC_MARKER = '<a id="27-remplacement-ui"></a>'


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def local_path(value):
    path = (ROOT / value).resolve()
    if path != ROOT and ROOT not in path.parents:
        raise ValueError("Preuve hors dossier : " + str(value))
    return path


def file_proof(item):
    path = local_path(item["path"])
    if not path.is_file():
        raise ValueError("Preuve absente : " + item["path"])
    if hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
        raise ValueError("Empreinte de preuve incohérente : " + item["path"])


def retirement_lot(lot):
    expected = LOT_KINDS.get(lot["id"])
    if expected is None or lot["kind"] != expected:
        raise ValueError("Classification du lot incohérente : " + lot["id"])
    return lot["id"] in RETIREMENT_KINDS


def state_profiles(lot, state):
    profiles = state.get("profiles", ["twoD", "threeD"])
    expected = STATE_PROFILE_EXCEPTIONS.get((lot["id"], state["id"]), {"twoD", "threeD"})
    if not isinstance(profiles, list) or len(profiles) != len(expected) or not all(isinstance(profile, str) for profile in profiles) or set(profiles) != expected:
        raise ValueError("Profils requis incohérents : " + lot["id"] + "/" + state["id"])
    return expected


def check_state_matrix(lot):
    if lot["id"] == "RUI-013":
        ids = [state["id"] for state in lot["requiredEvidence"]]
        if len(ids) != 4 or set(ids) != {"S01", "S02", "S03", "S04"}:
            raise ValueError("États requis incohérents : RUI-013")
    for state in lot["requiredEvidence"]:
        state_profiles(lot, state)


def requirements_fingerprint(plan):
    projection = []
    for lot in sorted(plan["lots"], key=lambda item: item["id"]):
        check_state_matrix(lot)
        states = [
            {
                "id": state["id"],
                "title": state["title"],
                "profiles": sorted(state_profiles(lot, state)),
                "proofKind": state.get("proofKind"),
            }
            for state in sorted(lot["requiredEvidence"], key=lambda item: item["id"])
        ]
        projection.append({
            "id": lot["id"],
            "kind": lot["kind"],
            "dependencies": sorted(lot["dependencies"]),
            "states": states,
            "acceptance": lot["acceptance"],
            "cases": lot["cases"],
            "profileCases": lot.get("profileCases"),
            "minimumProofTiers": lot.get("minimumProofTiers", []),
        })
    encoded = json.dumps(projection, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def check_requirements(plan, lot=None):
    if plan.get("requirementsRevision") != REQUIREMENTS_REVISION or requirements_fingerprint(plan) != REQUIREMENTS_SHA256:
        raise ValueError("Contrat d’exigences modifié : une nouvelle révision vérifiée est nécessaire")
    if lot is not None and not any(candidate == lot for candidate in plan["lots"]):
        raise ValueError("Contrat d’exigences : lot différent du plan")


def required_proof(item, label):
    if not isinstance(item, dict) or not isinstance(item.get("path"), str) or not isinstance(item.get("sha256"), str):
        raise ValueError("Preuve absente : " + label)
    file_proof(item)


def positive_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value > 0


def image_dimensions(path):
    data = path.read_bytes()
    suffix = path.suffix.lower()
    if suffix == ".png" and data.startswith(b"\x89PNG\r\n\x1a\n"):
        offset, size, seen_data = 8, None, False
        while offset + 12 <= len(data):
            length = struct.unpack_from(">I", data, offset)[0]
            end = offset + 12 + length
            if end > len(data):
                break
            kind = data[offset + 4:offset + 8]
            payload = data[offset + 8:offset + 8 + length]
            crc = struct.unpack_from(">I", data, offset + 8 + length)[0]
            if zlib.crc32(kind + payload) & 0xffffffff != crc:
                break
            if offset == 8:
                if kind != b"IHDR" or length != 13:
                    break
                size = struct.unpack_from(">II", payload)
            if kind == b"IDAT":
                seen_data = True
            if kind == b"IEND":
                if length == 0 and end == len(data) and size and all(size) and seen_data:
                    return size
                break
            offset = end
    elif suffix in {".jpg", ".jpeg"} and data.startswith(b"\xff\xd8") and data.endswith(b"\xff\xd9"):
        offset, size = 2, None
        frames = {0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf}
        while offset + 4 <= len(data) and data[offset] == 0xff:
            while offset < len(data) and data[offset] == 0xff:
                offset += 1
            if offset >= len(data):
                break
            marker = data[offset]
            offset += 1
            if marker == 0xda:
                if offset + 2 > len(data):
                    break
                length = struct.unpack_from(">H", data, offset)[0]
                if size and all(size) and length >= 6 and offset + length < len(data) - 2:
                    return size
                break
            if marker == 0x01 or 0xd0 <= marker <= 0xd7:
                continue
            if offset + 2 > len(data):
                break
            length = struct.unpack_from(">H", data, offset)[0]
            if length < 2 or offset + length > len(data):
                break
            if marker in frames and length >= 8:
                height, width = struct.unpack_from(">HH", data, offset + 3)
                size = width, height
            offset += length
    raise ValueError("Capture native non image ou incomplète : " + str(path))


@lru_cache(maxsize=64)
def decoded_image_dimensions(path, digest):
    dart = shutil.which("dart")
    config = DECODER_REPO / "apps/avelune_studio/.dart_tool/package_config.json"
    decoder = DECODER_REPO / "apps/avelune_studio/tools/t01_validate_screenshot.dart"
    if not dart or not config.is_file() or not decoder.is_file():
        raise ValueError("Décodeur de capture ou configuration Dart indisponible")
    args = [dart, "--disable-dart-dev", "--packages=" + str(config), str(decoder), path]
    try:
        process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            stdout, _ = process.communicate(timeout=20)
        except subprocess.TimeoutExpired:
            process.kill()
            process.communicate()
            raise
        if process.returncode != 0:
            raise ValueError("Capture native impossible à décoder")
        decoded = json.loads(stdout)
    except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError) as error:
        raise ValueError("Décodeur de capture indisponible ou sortie invalide") from error
    if not isinstance(decoded, dict) or not all(isinstance(decoded.get(key), int) and not isinstance(decoded[key], bool) and decoded[key] > 0 for key in ("width", "height")):
        raise ValueError("Dimensions de capture décodée invalides")
    return decoded["width"], decoded["height"]


def check_native_capture(capture, profile):
    if not isinstance(capture, dict) or capture.get("profile") != profile or not capture.get("capturedBy") or not capture.get("observation"):
        raise ValueError("Capture native ou provenance absente : " + profile)
    viewport = capture.get("viewport")
    if not isinstance(viewport, dict) or not all(positive_number(viewport.get(k)) for k in ("width", "height")) or not positive_number(capture.get("dpr")):
        raise ValueError("Viewport ou DPR natif invalide : " + profile)
    screenshot = capture.get("screenshot")
    required_proof(screenshot, "capture native " + profile)
    image_path = local_path(screenshot["path"])
    width, height = image_dimensions(image_path)
    if decoded_image_dimensions(str(image_path), screenshot["sha256"]) != (width, height):
        raise ValueError("Dimensions de capture décodée incohérentes : " + profile)
    if (abs(width - viewport["width"] * capture["dpr"]) > 1 or
            abs(height - viewport["height"] * capture["dpr"]) > 1):
        raise ValueError("Capture native : dimensions incohérentes avec viewport et DPR : " + profile)


def check_local_packages(config_path, require_studio=False):
    if not config_path.is_file():
        raise ValueError("Configuration Dart absente : " + str(config_path))
    config = read_json(config_path)
    packages = config.get("packages")
    if not isinstance(packages, list):
        raise ValueError("Configuration Dart invalide : " + str(config_path))
    expected = {
        "avelune_studio": "apps/avelune_studio",
        "avelune_design_system": "packages/avelune_design_system",
        "avelune_gen5_sprite_native": "packages/avelune_gen5_sprite_native",
        "avelune_rendering": "packages/avelune_rendering",
        "map_authoring": "packages/map_authoring",
        "map_battle": "packages/map_battle",
        "map_core": "packages/map_core",
        "map_distribution": "packages/map_distribution",
        "map_editor": "packages/map_editor",
        "map_gameplay": "packages/map_gameplay",
        "map_player_ui": "packages/map_player_ui",
        "map_render_3d": "packages/map_render_3d",
        "map_runtime": "packages/map_runtime",
        "pokemap_hub": "apps/pokemap_hub",
    }
    for group in ("apps", "packages"):
        for manifest in (REPO / group).glob("*/pubspec.yaml"):
            match = re.search(r"(?m)^name:\s*['\"]?([A-Za-z0-9_]+)['\"]?\s*$", manifest.read_text(encoding="utf-8"))
            if not match:
                continue
            name = match.group(1)
            if group == "packages" and not name.startswith(("avelune_", "map_", "pokemap_")):
                continue
            relative = str(manifest.parent.relative_to(REPO))
            if name in expected and expected[name] != relative:
                raise ValueError("Package local ambigu : " + name)
            expected[name] = relative
    seen = set()
    for package in packages:
        if not isinstance(package, dict) or package.get("name") not in expected:
            continue
        name = package["name"]
        if name in seen or not isinstance(package.get("rootUri"), str):
            raise ValueError("Package local ambigu : " + name)
        seen.add(name)
        uri = urlparse(urljoin(config_path.as_uri(), package["rootUri"]))
        if uri.scheme != "file" or uri.netloc not in {"", "localhost"} or Path(unquote(uri.path)).resolve() != (REPO / expected[name]).resolve():
            raise ValueError("Package local hors checkout : " + name)
        package_uri = package.get("packageUri")
        if not isinstance(package_uri, str):
            raise ValueError("Répertoire lib du package absent : " + name)
        lib_uri = urlparse(urljoin(uri.geturl().rstrip("/") + "/", package_uri))
        if lib_uri.scheme != "file" or lib_uri.netloc not in {"", "localhost"} or Path(unquote(lib_uri.path)).resolve() != (REPO / expected[name] / "lib").resolve():
            raise ValueError("Package local hors checkout : " + name)
    if require_studio and "avelune_studio" not in seen:
        raise ValueError("Package Studio absent de la configuration Dart")


def normalized_g0(report):
    roots = report.get("roots")
    contexts = report.get("contexts")
    exceptions = report.get("exceptions")
    if (not isinstance(roots, list) or not roots or any(not isinstance(root, str) for root in roots) or
            not isinstance(contexts, list) or not contexts or any(not isinstance(context, dict) for context in contexts) or
            not isinstance(exceptions, list)):
        raise ValueError("Périmètre du rapport G0 invalide")
    normalized_contexts = []
    for context in contexts:
        item = dict(context)
        context_roots = item.get("roots")
        if not isinstance(item.get("name"), str) or not isinstance(context_roots, list) or any(not isinstance(root, str) for root in context_roots):
            raise ValueError("Contexte du rapport G0 invalide")
        item["roots"] = sorted(context_roots)
        normalized_contexts.append(item)
    return {
        "schemaVersion": report.get("schemaVersion"), "gate": report.get("gate"),
        "proofTier": report.get("proofTier"), "passed": report.get("passed"),
        "counts": report.get("counts"), "roots": sorted(roots),
        "contexts": sorted(normalized_contexts, key=lambda item: json.dumps(item, sort_keys=True)),
        "exceptions": sorted(exceptions, key=lambda item: json.dumps(item, sort_keys=True)),
        "violations": report.get("violations"),
    }


def check_fresh_g0(plan, report):
    studio = REPO / "apps/avelune_studio"
    config = studio / ".dart_tool/package_config.json"
    checker = studio / "tools/t01_check_g0.dart"
    allowlist = ROOT / "t01-technical-exceptions.json"
    dart = g0_dart_executable()
    if not dart or not checker.is_file() or not allowlist.is_file():
        raise ValueError("Contrôleur G0, exceptions ou SDK Dart indisponible")
    check_local_packages(config, require_studio=True)
    args = [dart, "--disable-dart-dev", "--packages=" + str(config), str(checker),
            "--root", str(REPO), "--inventory", str(local_path(plan["inventoryPath"])),
            "--allowlist", str(allowlist)]
    try:
        result = subprocess.run(args, cwd=studio, capture_output=True, text=True, timeout=55, check=False)
        if result.returncode != 0:
            raise ValueError("Contrôle G0 actuel en échec")
        fresh = json.loads(result.stdout)
    except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError) as error:
        raise ValueError("Contrôle G0 actuel indisponible ou invalide") from error
    if not isinstance(fresh, dict) or fresh.get("passed") is not True or fresh.get("violations") != []:
        raise ValueError("Contrôle G0 actuel non accepté")
    if any(context.get("name") == "pokemap_hub" for context in fresh.get("contexts", []) if isinstance(context, dict)):
        check_local_packages(REPO / "apps/pokemap_hub/.dart_tool/package_config.json")
    if normalized_g0(fresh) != normalized_g0(report):
        raise ValueError("Rapport G0 différent du contrôle actuel")


def g0_dart_executable():
    return shutil.which("dart")


def check_attempt(plan, lot, attempt):
    retirement = retirement_lot(lot)
    check_state_matrix(lot)
    check_requirements(plan, lot)
    if not attempt.get("implementer"):
        raise ValueError("Implémenteur absent")
    review = attempt.get("review", {})
    if not review.get("reviewer") or review["reviewer"].strip().casefold() == attempt["implementer"].strip().casefold():
        raise ValueError("Revue distincte de l’implémenteur requise")
    if review.get("verdict") != "accepted" or not review.get("rationale"):
        raise ValueError("Verdict de revue accepté et argumenté requis")
    for check in lot["acceptance"]:
        if attempt.get("criterionResults", {}).get(check) is not True:
            raise ValueError("Critère non prouvé : " + check)
    commands = attempt.get("commands", [])
    if not commands or any(c.get("exitCode") != 0 for c in commands):
        raise ValueError("Commandes manquantes, interrompues ou en échec")
    for command in commands:
        if not command.get("command") or not command.get("finishedAt"):
            raise ValueError("Commande sans libellé ou fin connue")
        file_proof(command["log"])
    evidence = attempt.get("evidenceFiles", [])
    if not evidence:
        raise ValueError("Aucune preuve durable")
    for item in evidence:
        file_proof(item)
    documentary = lot["kind"] in {"preparation", "design_baseline", "evidence_framework"}
    fingerprints = attempt.get("codeFiles", [])
    if not fingerprints and (not documentary or lot["kind"] == "evidence_framework"):
        raise ValueError("Fingerprint du code absent")
    for item in fingerprints:
        path = (REPO / item["path"]).resolve()
        if REPO not in path.parents or not path.is_file():
            raise ValueError("Code absent/hors dépôt : " + item["path"])
        if hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
            raise ValueError("Preuve périmée, code modifié : " + item["path"])
    if documentary:
        if lot["id"] == "RUI-003":
            for candidate in plan["lots"]:
                check_state_matrix(candidate)
            required = {(l["id"], p, s["id"]) for l in plan["lots"] if l["kind"] not in {"preparation", "design_baseline", "evidence_framework"} and not retirement_lot(l) for s in l["requiredEvidence"] for p in state_profiles(l, s)}
            actual = {(b["lotId"], b["profile"], b["stateId"]) for b in plan.get("referenceBindings", []) if b.get("approvedBy") and b.get("approvedAt")}
            if not required.issubset(actual):
                raise ValueError("RUI-003 : cibles approuvées manquantes")
        return
    references = {r["id"]: r for r in plan["references"]}
    bindings = {b["id"]: b for b in plan.get("referenceBindings", [])}
    for profile in ("twoD", "threeD"):
        receipt = attempt.get("profiles", {}).get(profile)
        if not receipt:
            raise ValueError("Profil sans preuve : " + profile)
        for case in ("expected", "negative", "nonRegression"):
            result = receipt.get("functional", {}).get(case, {})
            if result.get("passed") is not True or not result.get("evidence"):
                raise ValueError("Cas fonctionnel absent : " + profile + "/" + case)
            file_proof(result["evidence"])
        if retirement:
            check_native_capture(receipt.get("neutralHost"), profile)
        state_list = receipt.get("states", [])
        if not isinstance(state_list, list) or any(not isinstance(s, dict) or not isinstance(s.get("id"), str) for s in state_list):
            raise ValueError("États invalides : " + profile)
        state_ids = [s["id"] for s in state_list]
        required_ids = {s["id"] for s in lot["requiredEvidence"] if profile in state_profiles(lot, s)}
        if len(state_ids) != len(set(state_ids)) or set(state_ids) != required_ids:
            raise ValueError("États manquants, dupliqués ou inconnus : " + profile)
        states = {s["id"]: s for s in state_list}
        for required in (s for s in lot["requiredEvidence"] if profile in state_profiles(lot, s)):
            state = states.get(required["id"])
            if not state:
                raise ValueError("État absent : " + profile + "/" + required["id"])
            if retirement:
                expected_kind = "native_capture" if (lot["id"], required["id"]) in RETIREMENT_CAPTURES else "technical_report"
                if required.get("proofKind") != expected_kind:
                    raise ValueError("Type de preuve technique incohérent : " + lot["id"] + "/" + required["id"])
                if state.get("passed") is not True or not state.get("checkedBy") or not state.get("observation") or state.get("criticalIssues") != []:
                    raise ValueError("État technique non vérifié : " + profile + "/" + required["id"])
                required_proof(state.get("evidence"), profile + "/" + required["id"])
                if expected_kind == "native_capture":
                    check_native_capture(state.get("capture"), profile)
                continue
            binding = bindings.get(state.get("targetBindingId"))
            if not binding or (binding.get("lotId"), binding.get("profile"), binding.get("stateId")) != (lot["id"], profile, required["id"]):
                raise ValueError("Cible non liée à cet état/profil")
            if not binding.get("approvedBy") or not binding.get("approvedAt"):
                raise ValueError("Cible non approuvée")
            reference = references.get(binding.get("referenceId"))
            if not reference or reference.get("designStatus") in {"known_issue", "guide_only"}:
                raise ValueError("Une fiche ou un défaut n’est pas une cible")
            file_proof(reference)
            file_proof(state["screenshot"])
            if not state.get("viewport") or not state.get("dpr") or not state.get("measuredBy"):
                raise ValueError("Viewport, DPR ou auteur des mesures absent")
            if state["viewport"] != binding.get("viewport") or state["dpr"] != binding.get("dpr"):
                raise ValueError("Taille de comparaison différente de la cible")
            if state.get("criticalIssues") != []:
                raise ValueError("Écart critique ou absence de revue")
            score = state.get("score", {})
            if set(score) != set(WEIGHTS):
                raise ValueError("Grille de score incomplète")
            if any(not isinstance(score[k], (int, float)) or not 0 <= score[k] <= WEIGHTS[k] for k in WEIGHTS):
                raise ValueError("Valeur de score invalide")
            if sum(score.values()) < 95:
                raise ValueError("État sous le seuil 95/100")
            metrics = state.get("metrics", {})
            for key, limit in METRICS.items():
                if not isinstance(metrics.get(key), (int, float)) or not 0 <= metrics[key] <= limit:
                    raise ValueError("Écart géométrique dépassé : " + key)
        for tier in lot.get("minimumProofTiers", []):
            item = receipt.get("proofTiers", {}).get(tier)
            if not item:
                raise ValueError("Niveau de preuve absent : " + profile + "/" + tier)
            file_proof(item)
    if lot["id"] in {"RUI-010", "RUI-088"}:
        gate = attempt.get("retirementGate", {})
        if any(gate.get(k) != 0 for k in ("reachableOldWidgets", "oldRoutes", "legacyFallbacks")):
            raise ValueError("Ancienne UI présente ou absence de contrôle G0/G1")
        inventory = read_json(ROOT / plan["inventoryPath"])
        if lot["id"] == "RUI-010":
            report_item = gate.get("report")
            required_proof(report_item, "rapport G0")
            if not G0_TOOL_FILES.issubset({item["path"] for item in fingerprints}):
                raise ValueError("Fingerprint des contrôleurs G0 incomplet")
            inventory_path = local_path(plan["inventoryPath"])
            if gate.get("inventorySha256") != hashlib.sha256(inventory_path.read_bytes()).hexdigest():
                raise ValueError("Inventaire G0 modifié depuis le reçu")
            allowlist = ROOT / "t01-technical-exceptions.json"
            if not allowlist.is_file() or gate.get("allowlistSha256") != hashlib.sha256(allowlist.read_bytes()).hexdigest():
                raise ValueError("Exceptions G0 modifiées depuis le reçu")
            report = read_json(local_path(report_item["path"]))
            counts = report.get("counts", {})
            if (report.get("schemaVersion") != 1 or report.get("gate") != "G0" or
                report.get("proofTier") != "static_retirement" or report.get("passed") is not True or
                not isinstance(report.get("roots"), list) or not report["roots"] or
                report.get("violations") != [] or counts.get("violations") != 0 or
                counts.get("inventoryEntries") != len(inventory["entries"]) or
                not positive_number(counts.get("reachableSources")) or not positive_number(counts.get("studioSourcesInspected"))):
                raise ValueError("Rapport G0 absent, périmé ou en échec")
        for item in inventory["entries"]:
            if item["decision"] not in {"retired_ui", "extracted_non_ui", "external_consumer_only"}:
                raise ValueError("Classement de retrait ouvert : " + item["path"])
        if lot["id"] == "RUI-010":
            check_fresh_g0(plan, report)


def validate(plan, hashes=True):
    ids = [l["id"] for l in plan["lots"]]
    if len(ids) != len(set(ids)):
        raise ValueError("Lot dupliqué")
    by_id = {l["id"]: l for l in plan["lots"]}
    references = {r["id"]: r for r in plan["references"]}
    if len(references) != len(plan["references"]):
        raise ValueError("Référence dupliquée")
    binding_keys = set()
    binding_ids = set()
    for binding in plan.get("referenceBindings", []):
        key = (binding["lotId"], binding["profile"], binding["stateId"])
        if binding["id"] in binding_ids or key in binding_keys:
            raise ValueError("Liaison de cible dupliquée")
        binding_ids.add(binding["id"])
        binding_keys.add(key)
        lot = by_id.get(binding["lotId"])
        reference = references.get(binding["referenceId"])
        state = next((s for s in lot["requiredEvidence"] if s["id"] == binding["stateId"]), None) if lot else None
        if not lot or not state or binding["profile"] not in state_profiles(lot, state):
            raise ValueError("Liaison vers un état/profil inconnu")
        if not reference or reference.get("designStatus") in {"known_issue", "guide_only"}:
            raise ValueError("Référence de cible absente ou descriptive/défectueuse")
        if binding.get("approvedBy") or binding.get("approvedAt"):
            viewport = binding.get("viewport", {})
            if not binding.get("approvedBy") or not binding.get("approvedAt") or not all(isinstance(viewport.get(k), (int, float)) and viewport[k] > 0 for k in ("width", "height")) or not isinstance(binding.get("dpr"), (int, float)) or binding["dpr"] <= 0:
                raise ValueError("Approbation sans date, viewport ou DPR valide")
    seen = set()
    for lot in plan["lots"]:
        check_state_matrix(lot)
        if retirement_lot(lot):
            for state in lot["requiredEvidence"]:
                expected_kind = "native_capture" if (lot["id"], state["id"]) in RETIREMENT_CAPTURES else "technical_report"
                if state.get("targetStatus") != "neutral_retirement_target_required" or state.get("proofKind") != expected_kind:
                    raise ValueError("Classification de preuve de retrait incohérente : " + lot["id"] + "/" + state["id"])
        if not set(lot["dependencies"]).issubset(seen):
            raise ValueError("Dépendance inconnue, cyclique ou mal ordonnée : " + lot["id"])
        seen.add(lot["id"])
        if any(r not in references for r in lot["references"]):
            raise ValueError("Référence absente : " + lot["id"])
        status = lot["execution"]["status"]
        if status not in plan["stateModel"]["statuses"]:
            raise ValueError("Statut invalide")
        if status == "accepted":
            if any(by_id[d]["execution"]["status"] != "accepted" for d in lot["dependencies"]):
                raise ValueError("Dépendance non acceptée : " + lot["id"])
            attempts = lot["execution"]["attempts"]
            if not attempts or attempts[-1].get("requestedStatus") != "accepted":
                raise ValueError("Acceptation sans tentative : " + lot["id"])
            check_attempt(plan, lot, attempts[-1])
    if [i for t in plan["themes"] for i in t["lotIds"]] != ids:
        raise ValueError("Thématiques et lots incohérents")
    check_requirements(plan)
    if hashes:
        for reference in plan["references"]:
            file_proof(reference)
        for evidence in plan["verification"].get("executionCheckpoint", {}).get("evidenceFiles", []):
            file_proof(evidence)
    return {"lots": len(ids), "themes": len(plan["themes"]), "references": len(references), "accepted": sum(l["execution"]["status"] == "accepted" for l in plan["lots"]), "attempts": sum(len(l["execution"]["attempts"]) for l in plan["lots"])}


def markdown(plan):
    checkpoint = plan["verification"].get("executionCheckpoint")
    recovery = plan["executionGuidance"].get("t00Recovery", {})
    execution_note = recovery.get("executionNote") or ("Préparation initiale : aucun code applicatif retiré/reconstruit par la création du dossier." if plan["planningOnly"] else "Exécution T01 en cours : extractions et retraits partiels ; aucun retrait intégral ni lot accepté revendiqué.")
    next_action = recovery.get("nextAction") or ("RUI-001. Aucune reconstruction avant G0." if plan["planningOnly"] else "Terminer le retrait T01 et ses preuves ; résoudre les prérequis T00 avant acceptation. Aucune reconstruction avant G0.")
    out = [DOC_MARKER, "## 27. Plan exécutoire : retrait intégral et remplacement de l’UI", "", "> Ce chapitre remplace les anciens lots D01–D14 comme ordre d’exécution. Les chapitres 1–26 restent la référence du constructeur. Les statuts du plan du 6 novembre ne valident aucune nouvelle UI.", "", "**Mandat :** " + plan["scope"], "", "**Architecture :** retirer toutes les anciennes compositions avant reconstruction ; préserver contrats, données, moteurs et commandes. Flutter/Dart restent les technologies du produit.", "", "**Suivi canonique :** [ui-replacement-plan.json](ui-replacement-plan.json). Lecture et comparaison dans l’onglet Plan de remplacement de [l’artefact](index.html#replacement).", "", "**Départ :** " + str(len(plan["lots"])) + " lots, " + str(len(plan["themes"])) + " thématiques, zéro réalisation native revendiquée par la préparation du dossier.", "", "### 27.1 Retrait et éléments protégés", ""]
    out += ["- " + x for x in plan["retirementRules"]]
    out += ["", "**Protections :**", ""] + ["- " + x for x in plan["protectedAreas"]]
    out += ["", "### 27.2 Références et priorité", "", plan["authority"], ""]
    out += ["- " + x for x in plan["referencePolicy"]["notes"]]
    out += ["", "Les 416 captures du 9 novembre et 195 références non historiques du 6 novembre sont réunies ici : 611 références. Les 54 fiches d’aide restent descriptives et les 15 captures d’audit restent des preuves de défaut. RUI-003 complète Pokémon, Histoire détaillée, régional, cinématiques/présentations, erreurs/récupération et les variantes 2D. Une cible manquante bloque la reconstruction concernée ; aucun ancien écran ne sert de secours.", "", "### 27.3 Portes et ordre", "", "| Porte | Lot | Condition |", "| --- | --- | --- |", "| G0 | RUI-010 | Zéro ancienne UI Studio et fonctionnel protégé |", "| G1 | RUI-088 | Nouvelle UI complète, deux profils et preuves à jour |", "", plan["executionGuidance"]["order"], "", "| Thématique | Phase | Lots |", "| --- | --- | --- |"]
    out += ["| " + t["id"] + " — " + t["title"] + " | " + t["phase"] + " | " + ", ".join(t["lotIds"]) + " |" for t in plan["themes"]]
    out += ["", "### 27.4 Contrat de fidélité et rejet", "", "Chaque état d’un écran reconstruit doit obtenir **au moins 95/100 dans chaque profil applicable** : structure 40, typographie 15, espacements 15, contrôles 15, états 15. Les états communs restent exigés en 2D et en 3D ; les deux états de projet actif RUI-013 s’appliquent chacun à leur profil. Revue par Yoahn ou réviseur distinct de l’implémenteur. Aucun score moyen ne compense un écran raté.", "", "Les lots de retrait RUI-005 à RUI-010 exigent les preuves techniques, les comportements protégés et les captures natives de l’hôte neutre définis dans le reçu ; ils ne reçoivent pas de score de fidélité à une interface encore absente.", "", "Seuils : déplacement de structure <=8 px logiques ; erreur de largeur de panneau <=2 % ; différence de taille de texte <=1 px logique ; différence d’espacement <=4 px logiques. Une adaptation intentionnelle modifie d’abord une cible approuvée.", "", "**Refus sans tolérance :**", ""]
    out += ["- " + x for x in plan["qualityContract"]["zeroTolerance"]]
    out += ["", "**Comparaison :**", ""] + [str(i + 1) + ". " + x for i, x in enumerate(plan["qualityContract"]["comparisonProtocol"])]
    out += ["", "**Après rejet :** garder preuves, mesures et motif ; corriger le lot ; recapturer/rejouer les cas affectés ; soumettre une nouvelle tentative. Le rejet bloque les dépendants. Un build vert ne vaut pas acceptation visuelle.", "", "### 27.5 Mise à jour durable", ""]
    out += [str(i + 1) + ". " + x for i, x in enumerate(plan["updateProtocol"])]
    out += ["", "~~~bash", "python3 documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/update_plan.py validate", "python3 documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/update_plan.py record --lot RUI-001 --receipt documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/proofs/RUI-001/attempt-001/receipt.json --emit-patch", "python3 documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/update_plan.py render --target readme --emit-patch", "python3 documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/update_plan.py render --target html --emit-patch", "~~~", "", "record/render émettent un patch à appliquer par l’outil natif d’édition ; relancer validate ensuite. La commande record ci-dessus ne s’exécute qu’après création du vrai reçu futur à ce chemin. invalidate --lot ID --reason MOTIF --emit-patch rouvre un lot et ses dépendants après changement ; les anciennes tentatives restent conservées. L’import dans la page est un brouillon tant que le JSON du dossier n’est pas remplacé et l’artefact régénéré.", "", "Le vérificateur contrôle empreintes, dépendances, scores, mesures et complétude. Il ne prouve pas qu’une mesure déclarée est honnête : la revue visuelle et les vrais scénarios restent obligatoires.", "", "### 27.6 Index des lots — détails complets dans l’artefact et le JSON", ""]
    if checkpoint:
        out += ["**Avancement vérifié :** " + checkpoint["at"] + " ; G0 " + checkpoint["G0"] + ".", ""]
        out += ["- " + item["scope"] + " : " + str(item["tests"]) + " tests, sortie " + str(item["exitCode"]) + "." for item in checkpoint["knownPassed"]]
        out += ["", "**Limites :** " + "; ".join(checkpoint["limits"]) + ".", ""]
        out += ["- [" + item.get("title", item["path"]) + "](" + item["path"] + ")" for item in checkpoint.get("evidenceFiles", [])]
        out += [""]
    lookup = {x["id"]: x for x in plan["references"]}
    for theme in plan["themes"]:
        out += ["### " + theme["id"] + " — " + theme["title"], "", "**Phase :** " + theme["phase"] + ". " + theme["summary"], ""]
        for lot in [l for l in plan["lots"] if l["theme"] == theme["id"]]:
            counts = {profile: sum(profile in state_profiles(lot, state) for state in lot["requiredEvidence"]) for profile in ("twoD", "threeD")}
            states_summary = (str(len(lot["requiredEvidence"])) + " états requis par profil" if all(count == len(lot["requiredEvidence"]) for count in counts.values()) else str(counts["twoD"]) + " états requis en 2D, " + str(counts["threeD"]) + " en 3D")
            out += ['<a id="' + lot["id"].lower() + '"></a>', "#### " + lot["id"] + " — " + lot["title"], "", "**Statut :** " + lot["execution"]["status"] + ". **Dépendances :** " + (", ".join(lot["dependencies"]) or "aucune") + ".", "", "**Objectif :** " + lot["goal"], "", "**2D :** " + lot["profiles"]["twoD"], "", "**3D :** " + lot["profiles"]["threeD"], "", "[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-" + lot["id"] + "). " + str(len(lot["steps"])) + " étapes ; " + states_summary + ". Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.", ""]
            if lot["execution"].get("progressNote"):
                out += ["**Avancement :** " + lot["execution"]["progressNote"], ""]
    out += ["### 27.7 Préparation et limites", "", "Départ sur main, HEAD " + plan["initialGit"]["head"] + ", arbre modifié et travail concurrent préservé. " + execution_note + " L’inventaire de 992 fichiers est à classer et compléter par graphe ; ce n’est pas un ordre aveugle de supprimer des dossiers.", "", "**Vérifications de préparation :** " + "; ".join(plan["verification"].get("planningChecks", [])) + ".", "", "**Revue native indépendante :** " + plan["verification"]["independentNativeReview"] + ". **Inspection visuelle du nouvel artefact :** " + plan["verification"]["browserVisualReview"] + ".", "", "**Adaptation de writing-plans :** fichiers, séquence, cas et contrats de preuve sont détaillés ; le plan ne préécrit pas des milliers de lignes de patches futurs sur des interfaces à retirer. Le code et ses tests sont ajoutés au lot concerné. Aucun commit/worktree n’est imposé par le skill.", "", "**Prochaine action :** " + next_action, ""]
    return "\n".join(out)


def patch(path, before, after):
    if before == after:
        return ""
    old, new = before.splitlines(), after.splitlines()
    matcher = difflib.SequenceMatcher(a=old, b=new, autojunk=False)
    lines = ["*** Begin Patch", "*** Update File: " + str(path)]
    for group in matcher.get_grouped_opcodes(3):
        lines.append("@@")
        for tag, i, j, k, l in group:
            if tag == "equal":
                lines.extend(" " + x for x in old[i:j])
            if tag in {"replace", "delete"}:
                lines.extend("-" + x for x in old[i:j])
            if tag in {"replace", "insert"}:
                lines.extend("+" + x for x in new[k:l])
    return "\n".join(lines + ["*** End Patch"])


def render_html(plan, before):
    section = (ROOT / "replacement-view.html").read_text()
    css = (ROOT / "replacement-view.css").read_text()
    js = (ROOT / "replacement-view.js").read_text()
    after = re.sub(r'<section id="replacement"[\s\S]*?</section>\n?', "", before)
    after = re.sub(r'<style id="replacement-style">[\s\S]*?</style>\n?', "", after)
    after = re.sub(r'<script type="application/json" id="replacement-data">[\s\S]*?</script>\n?', "", after)
    after = re.sub(r'<script id="replacement-script">[\s\S]*?</script>\n?', "", after)
    after = re.sub(r"\n+(?=</main>)", "\n", after)
    nav = '<button type="button" data-panel="replacement" aria-pressed="false">Plan de remplacement</button>'
    if nav not in after:
        after = after.replace('<nav class="tabs" aria-label="Sections du dossier">', '<nav class="tabs" aria-label="Sections du dossier">\n' + nav)
    after = after.replace("</head>", '<style id="replacement-style">' + css + "</style>\n</head>")
    after = after.replace("</main>", section + "\n</main>")
    data = json.dumps(plan, ensure_ascii=False, indent=2).replace("<", "\\u003c")
    after = after.replace("</body>", '<script type="application/json" id="replacement-data">' + data + '</script>\n<script id="replacement-script">' + js + "</script>\n</body>")
    after = after.replace("<title>Avelune — Dossier du constructeur de cartes</title>", "<title>Avelune Studio — Plan de remplacement et références UI</title>")
    after = after.replace("<h1>Le constructeur, état par état.</h1>", "<h1>Reconstruire Studio, lot par lot.</h1>")
    after = after.replace("La maquette réunie dans un dossier : captures, comportements, frontières métier et lots de réalisation. Une référence figée pour passer à la suite.", "Retirer l’ancienne UI, reconstruire les maquettes et vérifier chaque état en 2D et en 3D. Le plan et les preuves restent dans ce dossier.")
    after = after.replace("La documentation fournit 14 lots de reprise, 21 parcours de recette et les points d’entrée natifs à consulter. Ils complètent le plan de refonte existant sans réinitialiser son avancement.", "Le plan exécutoire fournit 88 lots dans 15 thématiques pour retirer toute l’ancienne UI puis reconstruire Studio en 2D et en 3D. Les 21 parcours du constructeur restent des scénarios de recette, complétés par les parcours globaux. Les 14 anciens lots de synthèse ne sont plus l’ordre d’exécution.")
    return after.rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("validate")
    render = sub.add_parser("render")
    render.add_argument("--target", choices=["readme", "html"], required=True)
    render.add_argument("--emit-patch", action="store_true", required=True)
    record = sub.add_parser("record")
    record.add_argument("--lot", required=True)
    record.add_argument("--receipt", type=Path, required=True)
    record.add_argument("--emit-patch", action="store_true", required=True)
    invalidate = sub.add_parser("invalidate")
    invalidate.add_argument("--lot", required=True)
    invalidate.add_argument("--reason", required=True)
    invalidate.add_argument("--emit-patch", action="store_true", required=True)
    args = parser.parse_args()
    plan = read_json(PLAN)
    if args.command == "validate":
        print(json.dumps(validate(plan), ensure_ascii=False))
        return
    if args.command == "invalidate":
        before = PLAN.read_text()
        affected = {args.lot}
        if args.lot not in {l["id"] for l in plan["lots"]}:
            raise ValueError("Lot inconnu")
        for lot in plan["lots"]:
            if lot["id"] in affected or affected.intersection(lot["dependencies"]):
                affected.add(lot["id"])
                if lot["execution"]["status"] != "planned":
                    lot["execution"]["status"] = "rejected"
                    lot["execution"].setdefault("invalidations", []).append({"at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "reason": args.reason, "sourceLot": args.lot})
        print(patch(PLAN, before, json.dumps(plan, ensure_ascii=False, indent=2) + "\n"))
        return
    if args.command == "record":
        before = PLAN.read_text()
        receipt = read_json(args.receipt)
        lot = next(l for l in plan["lots"] if l["id"] == args.lot)
        requested, current = receipt["requestedStatus"], lot["execution"]["status"]
        if requested not in plan["stateModel"]["transitions"].get(current, []):
            raise ValueError("Transition interdite : " + current + " -> " + requested)
        if any(a["attemptId"] == receipt["attemptId"] for a in lot["execution"]["attempts"]):
            raise ValueError("Tentative déjà enregistrée")
        if not receipt.get("at") or not receipt.get("implementer"):
            raise ValueError("Date et implémenteur requis")
        lot["execution"]["attempts"].append(receipt)
        lot["execution"].update(status=requested, implementer=receipt["implementer"], blockReason=receipt.get("blockReason"), lastUpdated=receipt["at"])
        if requested == "accepted":
            if any(next(l for l in plan["lots"] if l["id"] == dep)["execution"]["status"] != "accepted" for dep in lot["dependencies"]):
                raise ValueError("Dépendance non acceptée")
            check_attempt(plan, lot, receipt)
        plan["updatedAt"] = datetime.date.today().isoformat()
        validate(plan, hashes=False)
        print(patch(PLAN, before, json.dumps(plan, ensure_ascii=False, indent=2) + "\n"))
        return
    validate(plan, hashes=False)
    if args.target == "readme":
        path = ROOT / "README.md"
        before = path.read_text()
        after = before.split(DOC_MARKER)[0].rstrip() + "\n\n" + markdown(plan)
    else:
        path = ROOT / "index.html"
        before = path.read_text()
        after = render_html(plan, before)
    print(patch(path, before, after))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, StopIteration, OSError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
