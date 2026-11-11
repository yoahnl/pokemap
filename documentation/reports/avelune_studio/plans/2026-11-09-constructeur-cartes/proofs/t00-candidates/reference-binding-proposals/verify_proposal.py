import hashlib
import json
import struct
from datetime import datetime, timezone
from pathlib import Path


BASE = Path(__file__).resolve().parent
PROPOSAL = BASE / "rui019-rui075.proposed-bindings.json"
SESSION_STATES = {"S01": "readonly", "S02": "recovery", "S03": "conflict", "S04": "draft"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def png_dimensions(path):
    data = path.read_bytes()
    require(data[:8] == b"\x89PNG\r\n\x1a\n", "PNG signature mismatch: " + str(path))
    require(data[12:16] == b"IHDR", "PNG IHDR missing: " + str(path))
    return struct.unpack(">II", data[16:24])


def verify():
    proposal = json.loads(PROPOSAL.read_text())
    require(proposal["proposalOnly"] is True, "Not a proposal-only artifact")
    require(proposal["status"] == "proposal_only_unapproved", "Unexpected approval status")
    require(proposal["coverage"]["approvedBindingCount"] == 0, "Implicit approval count")
    require(proposal["canonicalRegistryWrittenByThisTask"] is False, "Canonical write claimed")
    require(proposal["sharedPlanModifiedByThisTask"] is False, "Shared plan write claimed")
    require(proposal["lotStatusChangedByThisTask"] is False, "Lot acceptance claimed")
    require(proposal["imagesCreatedOrModified"] is False, "Image mutation claimed")
    plan_path = Path(proposal["sourcePlan"]["path"])
    plan = json.loads(plan_path.read_text())
    lots = {lot["id"]: lot for lot in plan["lots"]}
    required = {
        (lot_id, state["id"], profile)
        for lot_id in proposal["scope"]["lotIds"]
        for state in lots[lot_id]["requiredEvidence"]
        for profile in state["profiles"]
    }
    sources = {source["id"]: source for source in proposal["sourceSets"]}
    manifests = {}
    for source_id, source in sources.items():
        path = Path(source["manifestPath"])
        require(digest(path) == source["manifestSha256"], "Source manifest changed: " + source_id)
        manifest = json.loads(path.read_text())
        require(manifest["status"] == "candidate_only_not_approved", "Source candidate status differs")
        for field in ["projectId", "componentId", "revisionId"]:
            require(manifest[field] == source[field], "Provenance mismatch: " + field)
        require(manifest["viewportCssPixels"] == source["viewport"], "Viewport provenance mismatch")
        require(manifest["devicePixelRatio"] == source["dpr"], "DPR provenance mismatch")
        manifests[source_id] = manifest
    bindings = proposal["proposedBindings"]
    require(len(bindings) == 18, "Unexpected proposed binding count")
    require(len({binding["id"] for binding in bindings}) == len(bindings), "Duplicate proposal ID")
    require(len({binding["referenceId"] for binding in bindings}) == len(bindings), "Duplicate reference ID")
    actual = set()
    verified = []
    for binding in bindings:
        key = (binding["lotId"], binding["stateId"], binding["profile"])
        require(key not in actual, "Duplicate lot/state/profile")
        actual.add(key)
        require(binding["approvalStatus"] == "unapproved_proposal", "Unexpected binding status")
        require(binding["approved"] is False, "Binding was approved")
        require(binding["approvedBy"] is None and binding["approvedAt"] is None, "Implicit approval metadata")
        source = sources[binding["sourceSetId"]]
        require(source["lotId"] == binding["lotId"], "Cross-lot source")
        manifest = manifests[source["id"]]
        image = Path(binding["capturePath"]).resolve()
        candidate_root = Path(source["manifestPath"]).parent.resolve()
        require(candidate_root in image.parents, "Image outside its source candidate")
        captures = [capture for capture in manifest["screenshots"] if (candidate_root / capture["path"]).resolve() == image]
        require(len(captures) == 1, "Capture does not resolve uniquely")
        capture = captures[0]
        require(capture["profile"] == binding["profile"], "Profile mismatch")
        require(capture["state"] == binding["sourceCaptureState"], "State provenance mismatch")
        if binding["lotId"] == "RUI-019":
            require(capture["state"] == SESSION_STATES[binding["stateId"]], "Session state mapping mismatch")
        else:
            require(capture["code"] == binding["stateId"], "Species state mapping mismatch")
        state = next(state for state in lots[binding["lotId"]]["requiredEvidence"] if state["id"] == binding["stateId"])
        require(state["title"] == binding["stateTitle"], "Current required-state title differs")
        require(digest(image) == binding["sha256"] == capture["sha256"], "Image hash mismatch")
        dimensions = png_dimensions(image)
        require(dimensions == (binding["pixelWidth"], binding["pixelHeight"]), "Actual image dimensions differ")
        require(dimensions == (capture["pixelWidth"], capture["pixelHeight"]), "Source dimensions differ")
        require(binding["viewport"] == source["viewport"] and binding["dpr"] == source["dpr"], "Binding viewport/DPR differ")
        require(dimensions == tuple(binding["viewport"][axis] * binding["dpr"] for axis in ("width", "height")), "Logical/pixel dimensions differ")
        visual = binding["visualCorrespondence"]
        require(visual["status"] == "candidate_matches_named_state_family_not_design_acceptance", "Visual acceptance inferred")
        require(visual["nativeFidelityScoreAssigned"] is False, "Native fidelity score inferred")
        require(visual["visibleEvidence"] and visual["profileEvidence"] and binding["limitations"], "Missing visual scope/limits")
        verified.append({"lotId": key[0], "stateId": key[1], "profile": key[2], "sha256": binding["sha256"], "pixelWidth": dimensions[0], "pixelHeight": dimensions[1]})
    require(actual == required, "Coverage differs from current required state/profiles")
    recorded = {(item["lotId"], item["stateId"], item["profile"]) for item in proposal["expectedPairs"]}
    require(recorded == required, "Recorded required-state inventory differs")
    require(proposal["coverage"]["missingCandidatePairs"] == [], "Unexpected missing candidate pairs")
    require(proposal["coverage"]["requiredPairCount"] == len(required), "Coverage count mismatch")
    pending = {(item["lotId"], item["stateId"], item["profile"]) for item in proposal["coverage"]["pairsWithoutApprovedTarget"]}
    require(pending == required, "An unapproved pair disappeared from the pending list")
    report = {
        "verifiedAt": datetime.now(timezone.utc).isoformat(),
        "status": "verified_local_proposal_unapproved",
        "proposalPath": str(PROPOSAL),
        "proposalSha256": digest(PROPOSAL),
        "verifierSha256": digest(Path(__file__).resolve()),
        "requiredPairs": len(required),
        "verifiedBindings": len(verified),
        "approvedBindingsInProposal": 0,
        "missingCandidatePairs": [],
        "currentCanonicalRegistryBindingCount": len(plan.get("referenceBindings", [])),
        "currentPlanSha256": digest(plan_path),
        "planChangedSinceProposalRead": digest(plan_path) != proposal["sourcePlan"]["sha256AtRead"],
        "requiredPairsMatchCurrentPlan": True,
        "sourceImageHashesAndDimensionsVerified": True,
        "visualCorrespondence": "Recorded manual observations are not automated design approval or native fidelity measurement.",
        "verificationWrites": [str(BASE / "verification.json")],
        "sourcesAndSharedPlanWritten": False,
        "bindings": verified,
    }
    output = BASE / "verification.json"
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({key: value for key, value in report.items() if key != "bindings"}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    verify()
