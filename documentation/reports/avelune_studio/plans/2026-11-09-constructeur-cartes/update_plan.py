import argparse
import datetime
import difflib
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
PLAN = ROOT / "ui-replacement-plan.json"
WEIGHTS = {"structure": 40, "typography": 15, "spacing": 15, "controls": 15, "states": 15}
METRICS = {"layoutMaxShiftLogicalPx": 8, "panelWidthRelativeError": 0.02, "textMaxDeltaLogicalPx": 1, "spacingMaxDeltaLogicalPx": 4}
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


def check_attempt(plan, lot, attempt):
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
            required = {(l["id"], p, s["id"]) for l in plan["lots"] if l["kind"] not in {"preparation", "design_baseline", "evidence_framework"} for p in ("twoD", "threeD") for s in l["requiredEvidence"]}
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
        states = {s["id"]: s for s in receipt.get("states", [])}
        for required in lot["requiredEvidence"]:
            state = states.get(required["id"])
            if not state:
                raise ValueError("État absent : " + profile + "/" + required["id"])
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
        for item in inventory["entries"]:
            if item["decision"] not in {"retired_ui", "extracted_non_ui", "external_consumer_only"}:
                raise ValueError("Classement de retrait ouvert : " + item["path"])


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
        if not lot or binding["profile"] not in {"twoD", "threeD"} or binding["stateId"] not in {s["id"] for s in lot["requiredEvidence"]}:
            raise ValueError("Liaison vers un état/profil inconnu")
        if not reference or reference.get("designStatus") in {"known_issue", "guide_only"}:
            raise ValueError("Référence de cible absente ou descriptive/défectueuse")
        if binding.get("approvedBy") or binding.get("approvedAt"):
            viewport = binding.get("viewport", {})
            if not binding.get("approvedBy") or not binding.get("approvedAt") or not all(isinstance(viewport.get(k), (int, float)) and viewport[k] > 0 for k in ("width", "height")) or not isinstance(binding.get("dpr"), (int, float)) or binding["dpr"] <= 0:
                raise ValueError("Approbation sans date, viewport ou DPR valide")
    seen = set()
    for lot in plan["lots"]:
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
    out += ["", "### 27.4 Contrat de fidélité et rejet", "", "Chaque état requis doit obtenir **au moins 95/100 dans chacun des deux profils** : structure 40, typographie 15, espacements 15, contrôles 15, états 15. Revue par Yoahn ou réviseur distinct de l’implémenteur. Aucun score moyen ne compense un écran raté.", "", "Seuils : déplacement de structure <=8 px logiques ; erreur de largeur de panneau <=2 % ; différence de taille de texte <=1 px logique ; différence d’espacement <=4 px logiques. Une adaptation intentionnelle modifie d’abord une cible approuvée.", "", "**Refus sans tolérance :**", ""]
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
            out += ['<a id="' + lot["id"].lower() + '"></a>', "#### " + lot["id"] + " — " + lot["title"], "", "**Statut :** " + lot["execution"]["status"] + ". **Dépendances :** " + (", ".join(lot["dependencies"]) or "aucune") + ".", "", "**Objectif :** " + lot["goal"], "", "**2D :** " + lot["profiles"]["twoD"], "", "**3D :** " + lot["profiles"]["threeD"], "", "[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-" + lot["id"] + "). " + str(len(lot["steps"])) + " étapes ; " + str(len(lot["requiredEvidence"])) + " états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.", ""]
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
