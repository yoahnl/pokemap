import argparse
import csv
import hashlib
import json
import os
import re
import shutil
import signal
import subprocess
import tempfile
import time
import zipfile
from pathlib import Path, PurePosixPath


def process_table():
    output = subprocess.run(
        ["ps", "-axo", "pid=,ppid=,lstart=,command="],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    result = {}
    for line in output.splitlines():
        parts = line.strip().split(None, 7)
        if len(parts) == 8 and parts[0].isdigit() and parts[1].isdigit():
            result[int(parts[0])] = (int(parts[1]), tuple(parts[2:7]), parts[7])
    return result


def owned_descendants(rows, parent):
    found = {}
    for pid, data in rows.items():
        cursor = pid
        visited = set()
        while cursor in rows and cursor not in visited and cursor not in (parent, 1):
            visited.add(cursor)
            cursor = rows[cursor][0]
        if cursor == parent and pid != parent:
            found[pid] = (data[1], data[2])
    return found


def extract_project(package, destination, include_sprites):
    selected = []
    with zipfile.ZipFile(package) as archive:
        extra = set()
        if include_sprites:
            for species, side in (
                ("totodile", "backStatic"),
                ("chikorita", "backStatic"),
                ("pidgey", "frontStatic"),
            ):
                media_path = f"project/data/pokemon/media/{species}.json"
                media = json.loads(archive.read(media_path))
                asset = media["variants"][media["defaultFormId"]][side]
                path = PurePosixPath(asset)
                if path.is_absolute() or ".." in path.parts or not asset.startswith("assets/"):
                    raise ValueError("Invalid visual sample asset path")
                extra.update((media_path, f"project/{asset}"))
        names = set()
        for info in archive.infolist():
            name = info.filename
            if (name != "project/data/pokemon/catalogs/moves.json"
                and not name.startswith("project/data/pokemon/battle_recipes/")
                and name not in extra):
                continue
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts or name in names:
                raise ValueError("Invalid or duplicate package path")
            names.add(name)
            if info.is_dir():
                continue
            if info.file_size > 64 * 1024 * 1024:
                raise ValueError("Recipe file exceeds the audit limit")
            target = destination.joinpath(*path.parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(info) as source, target.open("wb") as output:
                shutil.copyfileobj(source, output)
            selected.append(name)
    if "project/data/pokemon/catalogs/moves.json" not in selected:
        raise ValueError("The package has no move catalogue")
    return len(selected)


def run():
    parser = argparse.ArgumentParser(
        description="Contrôle les attaques d'un export HGSS dans le runtime Flutter."
    )
    parser.add_argument("--package", type=Path, required=True, help="Paquet .avelunegame à lire")
    parser.add_argument("--workspace", type=Path, required=True, help="Dossier temporaire autorisé")
    parser.add_argument("--report", type=Path, required=True, help="Nouveau rapport JSON")
    parser.add_argument("--csv", type=Path, help="Nouveau tableau des anomalies")
    parser.add_argument("--orientation", choices=("portrait", "landscape"), default="portrait")
    parser.add_argument("--move", action="append", default=[], help="Identifiant à tester, répétable")
    parser.add_argument("--captures", type=Path, help="Nouveau dossier de captures pour les attaques sélectionnées")
    args = parser.parse_args()
    if any(not re.fullmatch(r"[a-z0-9_-]+", move) for move in args.move):
        parser.error("Move IDs must contain only lowercase letters, digits, underscores or hyphens")
    if args.captures and not args.move:
        parser.error("Select representative moves when requesting captures")
    package = args.package.resolve(strict=True)
    workspace = args.workspace.resolve()
    report = args.report.absolute()
    if report.exists() or report.is_symlink():
        parser.error("The report already exists; choose another path")
    if args.csv and (args.csv.exists() or args.csv.is_symlink()):
        parser.error("The CSV report already exists; choose another path")
    if args.csv and args.csv.absolute() == report:
        parser.error("JSON and CSV reports need different paths")
    if args.captures and (args.captures.exists() or args.captures.is_symlink()):
        parser.error("The capture directory already exists; choose another path")
    workspace.mkdir(parents=True, exist_ok=True)
    report.parent.mkdir(parents=True, exist_ok=True)
    if args.captures:
        args.captures.mkdir(parents=True)
    with package.open("rb") as source:
        package_sha256 = hashlib.file_digest(source, "sha256").hexdigest()
    package_root = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix="bw2-audit-", dir=workspace) as temporary:
        temp = Path(temporary)
        extracted = extract_project(package, temp, include_sprites=args.captures is not None)
        environment = os.environ.copy()
        environment.update({
            "TMPDIR": str(temp),
            "AVELUNE_BW2_AUDIT_ROOT": str(temp / "project"),
            "AVELUNE_BW2_AUDIT_REPORT": str(report),
            "AVELUNE_BW2_AUDIT_ORIENTATION": args.orientation,
            "AVELUNE_BW2_AUDIT_MOVES": ",".join(args.move),
        })
        if args.captures:
            environment["AVELUNE_BW2_AUDIT_CAPTURES"] = str(args.captures.resolve())
        log = temp / "flutter-test.log"
        with log.open("w") as output:
            runner = subprocess.Popen([
                "flutter", "test", "--no-pub", "--concurrency=1",
                "test/battle_verified_recipe_sound_test.dart",
                "--plain-name", "audits exported HGSS source animations in a tracked turn",
                "-r", "expanded",
            ], cwd=package_root, env=environment, stdout=output, stderr=subprocess.STDOUT)
            print(f"Test runner: {runner.pid}; extracted files: {extracted}", flush=True)
            seen = {}
            last_progress = -1
            while runner.poll() is None:
                seen.update(owned_descendants(process_table(), runner.pid))
                if report.exists():
                    try:
                        data = json.loads(report.read_text())
                        processed = data["processed"]
                        if processed == data["total"] or processed // 25 > last_progress:
                            last_progress = processed // 25
                            print(f"Processed: {processed}/{data['total']}", flush=True)
                    except (OSError, ValueError, KeyError):
                        pass
                time.sleep(0.5)
            code = runner.wait()
        remaining = process_table()
        leftovers = []
        for pid, signature in seen.items():
            row = remaining.get(pid)
            if row and (row[1], row[2]) == signature and any(
                name in row[2] for name in ("flutter_tester", "frontend_server_aot")
            ):
                leftovers.append(pid)
                os.kill(pid, signal.SIGTERM)
        print(f"Test exit: {code}; owned leftover harnesses stopped: {leftovers}", flush=True)
        if code != 0:
            print("\n".join(log.read_text().splitlines()[-35:]), flush=True)
            return code
    if not report.exists():
        raise RuntimeError("The runtime test did not write its report")
    data = json.loads(report.read_text())
    data["packageSha256"] = package_sha256
    report.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    if args.csv:
        statuses = {
            "fallback": "Repli",
            "error": "Erreur pendant la simulation",
            "timeout": "Simulation trop longue",
            "untested": "Non concluant",
        }
        reasons = {
            "unbound": "Aucune recette associée",
            "silentAudioSelectionRejected": "Recette silencieuse refusée par le Player",
            "unsupportedSourceEmitterMotion": "Mouvement de particules non pris en charge",
            "sourcePreparationRejected": "Préparation BW2 refusée",
            "sourcePlaybackFailed": "Lecture BW2 interrompue",
            "sourcePlaybackNotCompleted": "Lecture BW2 non terminée",
            "syntheticTurnHasNoTarget": "Aucune cible dans le combat simulé",
        }
        args.csv.parent.mkdir(parents=True, exist_ok=True)
        with args.csv.open("w", encoding="utf-8-sig", newline="") as output:
            writer = csv.writer(output)
            writer.writerow(["Attaque", "Identifiant", "Statut", "Motif", "Détails"])
            for row in data["anomalies"]:
                writer.writerow([
                    row["name"], row["id"], statuses.get(row["status"], row["status"]),
                    reasons.get(row["reason"], row["reason"]),
                    " | ".join(row.get("diagnostics", [])),
                ])
    print(json.dumps({"processed": data["processed"], "counts": data["counts"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
