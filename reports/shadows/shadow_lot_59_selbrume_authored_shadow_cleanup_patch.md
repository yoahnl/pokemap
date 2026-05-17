# Shadow-59 — Selbrume Authored Shadow Cleanup Patch / Explicit Data Review

## 1. Résumé exécutif

Shadow-59 a neutralisé explicitement les ombres authorées des 5 éléments Selbrume validés par Shadow-57 / Shadow-58 :

- `panneau`
- `lampadaire`
- `arbre_pixellab_1`
- `arbre_pixellab_2`
- `selbrume_maison_5`

Action appliquée dans `/Users/karim/Desktop/selbrume/project.json` : remplacement de la valeur non-null du champ `shadow` par `null` pour ces 5 éléments uniquement.

Aucun code du repo n'a été modifié. Aucun placement, aucun `shadowOverride`, aucun asset et aucun fichier `/Users/karim/Desktop/selbrume/maps/Selbrume.json` n'a été modifié.

Résultat principal :

```text
Éléments avec shadow : 25 -> 20
Inventaire statique estimé : 112 -> 11
projectedPolygon estimé : 112 -> 11
genericProjection estimé : 97 -> 0
Cibles arbre/panneau/lampadaire/maison_5 : toutes à 0 instruction après patch
```

Écart avec la référence attendue `111 -> environ 10` : l'audit réel trouve un élément authoré supplémentaire `test` avec 1 placement et une ombre restante. Il est hors des 5 cibles autorisées, donc Shadow-59 ne l'a pas modifié.

## 2. Rappel Shadow-57 / Shadow-58

Shadow-56 a supprimé le runtime auto-apply. Shadow-57 a montré que les grandes plaques restantes venaient de configs authorées dangereuses dans Selbrume. Shadow-58 a durci la policy pour ne plus recréer automatiquement ces defaults dangereux.

Shadow-59 applique maintenant le nettoyage authoré limité aux 5 éléments validés.

## 3. Autorisation et périmètre

Autorisé :

```text
/Users/karim/Desktop/selbrume/project.json
```

Créés :

```text
/Users/karim/Desktop/selbrume/project.shadow59.before.json
reports/shadows/shadow_lot_59_selbrume_authored_shadow_cleanup_patch.md
reports/shadows/shadow_lot_59_selbrume_project_json_external_diff.diff
```

Interdits et non modifiés :

```text
/Users/karim/Desktop/selbrume/maps/Selbrume.json
packages/map_core/**
packages/map_editor/**
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
assets / tilesets / images
```

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Commande :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

AGENTS applicable : `/Users/karim/Project/pokemonProject/AGENTS.md`, fourni dans le prompt. Le lot autorise explicitement la modification externe de Selbrume `project.json` et interdit les opérations Git write ; j'ai donc exécuté sans worktree et sans commit.

## 5. Hashes initiaux Selbrume

Commande :

```bash
shasum -a 256 /Users/karim/Desktop/selbrume/project.json /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie :

```text
d3784bcb94ff1267bacd7bd46e902038389a601f023a981e840a92a8fba7efb5  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

## 6. Backup créé

Commande :

```bash
cp /Users/karim/Desktop/selbrume/project.json /Users/karim/Desktop/selbrume/project.shadow59.before.json
cmp /Users/karim/Desktop/selbrume/project.json /Users/karim/Desktop/selbrume/project.shadow59.before.json
```

Sortie :

```text
backup cmp: identical
```

Backup :

```text
/Users/karim/Desktop/selbrume/project.shadow59.before.json
```

## 7. Audit initial des 5 éléments ciblés

Commande :

```bash
jq -r '.elements[] | select(.id=="panneau" or .id=="lampadaire" or .id=="arbre_pixellab_1" or .id=="arbre_pixellab_2" or .id=="selbrume_maison_5") | [.id, .name, (.shadow == null), (.shadow.castsShadow // "null"), (.shadow.shadowProfileId // "null"), (.shadow.family // "null")] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Sortie avant patch :

```text
selbrume_maison_5	selbrume maison 5	false	true	default-ground-soft-ellipse	null
lampadaire	lampadaire	false	true	default-ground-contact-blob	tallProp
arbre_pixellab_1	arbre  pixelLab 1	false	true	default-ground-soft-ellipse	null
arbre_pixellab_2	arbre  pixelLab 2	false	true	default-ground-soft-ellipse	null
panneau	panneau	false	true	default-ground-wide-ellipse	null
```

Commande :

```bash
jq -r '[.elements[] | select(.id=="panneau" or .id=="lampadaire" or .id=="arbre_pixellab_1" or .id=="arbre_pixellab_2" or .id=="selbrume_maison_5")] | length' /Users/karim/Desktop/selbrume/project.json
```

Sortie :

```text
5
```

Comptes shadow avant patch :

```bash
jq -r '([.elements[] | select(.shadow != null)] | length), ([.elements[] | select(.shadow == null)] | length)' /Users/karim/Desktop/selbrume/project.json
```

```text
25
38
```

## 8. Audit initial des placements ciblés

Commande :

```bash
jq -r '[.. | objects | select(has("elementId"))] as $placed | [$placed|length, ($placed|map(select(.elementId=="panneau"))|length), ($placed|map(select(.elementId=="lampadaire"))|length), ($placed|map(select(.elementId=="arbre_pixellab_1"))|length), ($placed|map(select(.elementId=="arbre_pixellab_2"))|length), ($placed|map(select(.elementId=="selbrume_maison_5"))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie :

```text
2105	1	4	46	49	1
```

La référence Shadow-58 est confirmée pour les 5 cibles.

## 9. Méthode de patch

Méthode utilisée : script temporaire `/tmp/shadow59_selbrume_cleanup.py`.

Le script :

- parse `project.json` pour valider la structure ;
- vérifie les 5 IDs ciblés ;
- localise textuellement la valeur top-level du champ `shadow` dans chaque objet élément ;
- remplace uniquement la valeur par `null` ;
- reparses le JSON après patch ;
- compare les structures avant/après en autorisant seulement `shadow -> null` pour les 5 cibles.

Il ne reserialize pas tout le fichier.

## 10. Dry-run avant écriture

Commande :

```bash
python3 /tmp/shadow59_selbrume_cleanup.py --project /Users/karim/Desktop/selbrume/project.json --dry-run
```

Sortie :

```text
shadow59 dry-run
target ids found: 5
id=selbrume_maison_5 element_index=11 range=233714..234034 shadow_before={"castsShadow": true, "family": null, "shadowProfileId": "default-ground-soft-ellipse"} action=replace-shadow-value-with-null
id=lampadaire element_index=18 range=394898..395316 shadow_before={"castsShadow": true, "family": "tallProp", "shadowProfileId": "default-ground-contact-blob"} action=replace-shadow-value-with-null
id=arbre_pixellab_1 element_index=24 range=432677..432997 shadow_before={"castsShadow": true, "family": null, "shadowProfileId": "default-ground-soft-ellipse"} action=replace-shadow-value-with-null
id=arbre_pixellab_2 element_index=25 range=456725..457044 shadow_before={"castsShadow": true, "family": null, "shadowProfileId": "default-ground-soft-ellipse"} action=replace-shadow-value-with-null
id=panneau element_index=62 range=485235..485625 shadow_before={"castsShadow": true, "family": null, "shadowProfileId": "default-ground-wide-ellipse"} action=replace-shadow-value-with-null
replacements planned: 5
no other changes planned: true
```

## 11. Patch appliqué

Commande :

```bash
python3 /tmp/shadow59_selbrume_cleanup.py --project /Users/karim/Desktop/selbrume/project.json --apply
```

Sortie :

```text
shadow59 apply
backup required: /Users/karim/Desktop/selbrume/project.shadow59.before.json exists
replacements applied: 5
json valid after: true
only targeted shadows changed: true
```

## 12. Diff externe du project.json

Fichier créé :

```text
reports/shadows/shadow_lot_59_selbrume_project_json_external_diff.diff
```

Commande :

```bash
diff -u /Users/karim/Desktop/selbrume/project.shadow59.before.json /Users/karim/Desktop/selbrume/project.json > reports/shadows/shadow_lot_59_selbrume_project_json_external_diff.diff || true
wc -l reports/shadows/shadow_lot_59_selbrume_project_json_external_diff.diff
```

Sortie :

```text
     109 reports/shadows/shadow_lot_59_selbrume_project_json_external_diff.diff
```

Contenu complet du diff externe :

```diff
--- /Users/karim/Desktop/selbrume/project.shadow59.before.json	2026-05-17 21:55:20
+++ /Users/karim/Desktop/selbrume/project.json	2026-05-17 21:56:53
@@ -2816,18 +2816,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-soft-ellipse",
-        "offsetY": -6.0,
-        "opacity": 0.22,
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 0.96,
-          "footprintWidthRatio": 0.68,
-          "footprintHeightRatio": 0.08
-        }
-      },
+      "shadow": null,
       "groupId": "group_1777757343053",
       "recommendedLayerId": null,
       "tags": [],
@@ -6188,22 +6177,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-contact-blob",
-        "offsetX": 0.0,
-        "offsetY": 0.0,
-        "scaleX": 0.8,
-        "scaleY": 0.55,
-        "opacity": 0.2,
-        "family": "tallProp",
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 1.0,
-          "footprintWidthRatio": 0.28,
-          "footprintHeightRatio": 0.05
-        }
-      },
+      "shadow": null,
       "groupId": null,
       "recommendedLayerId": null,
       "tags": [],
@@ -6815,18 +6789,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-soft-ellipse",
-        "offsetY": -10.0,
-        "opacity": 0.25,
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 0.92,
-          "footprintWidthRatio": 0.58,
-          "footprintHeightRatio": 0.1
-        }
-      },
+      "shadow": null,
       "groupId": null,
       "recommendedLayerId": null,
       "tags": [],
@@ -7004,18 +6967,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-soft-ellipse",
-        "offsetY": -10.0,
-        "opacity": 0.25,
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 0.92,
-          "footprintWidthRatio": 0.5,
-          "footprintHeightRatio": 0.1
-        }
-      },
+      "shadow": null,
       "groupId": null,
       "recommendedLayerId": null,
       "tags": [],
@@ -8069,21 +8021,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-wide-ellipse",
-        "offsetX": 0.0,
-        "offsetY": 0.0,
-        "scaleX": 0.92,
-        "scaleY": 0.75,
-        "opacity": 0.27,
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 0.95,
-          "footprintWidthRatio": 0.72,
-          "footprintHeightRatio": 0.1
-        }
-      },
+      "shadow": null,
       "groupId": null,
       "recommendedLayerId": null,
       "tags": [],
```

## 13. Vérifications JSON après patch

Commande :

```bash
jq -r '([.elements[] | select(.shadow != null)] | length), ([.elements[] | select(.shadow == null)] | length)' /Users/karim/Desktop/selbrume/project.json
```

Sortie :

```text
20
43
```

Commande :

```bash
jq -r '.elements[] | select(.id=="panneau" or .id=="lampadaire" or .id=="arbre_pixellab_1" or .id=="arbre_pixellab_2" or .id=="selbrume_maison_5") | [.id, (.shadow == null)] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Sortie :

```text
selbrume_maison_5	true
lampadaire	true
arbre_pixellab_1	true
arbre_pixellab_2	true
panneau	true
```

Commande :

```bash
jq empty /Users/karim/Desktop/selbrume/project.json && jq empty /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie :

```text
json valid: project and Selbrume map
```

## 14. Hashes finaux Selbrume

Commande :

```bash
shasum -a 256 /Users/karim/Desktop/selbrume/project.json /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie :

```text
3c3669a8274e31087b617fd46337c28aef6593f376a7d0a54c2d9fb8e31b389d  /Users/karim/Desktop/selbrume/project.json
8fd1f7efdc02413106a21068e3af310b3149c07023cfad64ddaa101f2c2cac63  /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Conclusion : `project.json` a changé ; `Selbrume.json` a exactement le même hash qu'avant.

## 15. Runtime instruction inventory before/after

Méthode : script temporaire `/tmp/shadow59_selbrume_instruction_inventory.py`.

Le script lit `project.json` et `Selbrume.json`, liste récursivement les objets avec `elementId`, puis compte une instruction statique estimée par placement dont l'élément source porte `shadow != null` et `castsShadow == true`. Dans l'état actuel de la chaîne runtime Shadow, ces instructions statiques sont rendues en `projectedPolygon`. `genericProjection` est compté lorsque `shadow.family` est absent/null ou explicitement `genericProjection`.

Commande :

```bash
python3 /tmp/shadow59_selbrume_instruction_inventory.py /Users/karim/Desktop/selbrume/project.shadow59.before.json /Users/karim/Desktop/selbrume/maps/Selbrume.json before
python3 /tmp/shadow59_selbrume_instruction_inventory.py /Users/karim/Desktop/selbrume/project.json /Users/karim/Desktop/selbrume/maps/Selbrume.json after
```

Sortie :

```text
inventory before
project=/Users/karim/Desktop/selbrume/project.shadow59.before.json
placements_total=2105
static_instructions_total=112
projectedPolygon_total=112
genericProjection_total=97
building_family_total=11
target panneau instructions=1 genericProjection=1
target lampadaire instructions=4 genericProjection=0
target arbre_pixellab_1 instructions=46 genericProjection=46
target arbre_pixellab_2 instructions=49 genericProjection=49
target selbrume_maison_5 instructions=1 genericProjection=1
top_shadow_elements=[["arbre_pixellab_2", 49], ["arbre_pixellab_1", 46], ["lampadaire", 4], ["selbrum_maison_4", 2], ["kiosque_l_gumes", 1], ["le_puits", 1], ["panneau", 1], ["selbrum_maison_1", 1], ["selbrum_maison_2", 1], ["selbrum_maison_3", 1], ["selbrum_maison_7", 1], ["selbrum_maison_8", 1], ["selbrume_centre_pok_mon", 1], ["selbrume_maison_5", 1], ["test", 1]]

inventory after
project=/Users/karim/Desktop/selbrume/project.json
placements_total=2105
static_instructions_total=11
projectedPolygon_total=11
genericProjection_total=0
building_family_total=11
target panneau instructions=0 genericProjection=0
target lampadaire instructions=0 genericProjection=0
target arbre_pixellab_1 instructions=0 genericProjection=0
target arbre_pixellab_2 instructions=0 genericProjection=0
target selbrume_maison_5 instructions=0 genericProjection=0
top_shadow_elements=[["selbrum_maison_4", 2], ["kiosque_l_gumes", 1], ["le_puits", 1], ["selbrum_maison_1", 1], ["selbrum_maison_2", 1], ["selbrum_maison_3", 1], ["selbrum_maison_7", 1], ["selbrum_maison_8", 1], ["selbrume_centre_pok_mon", 1], ["test", 1]]
```

Conclusion : toutes les instructions des 5 cibles tombent à zéro. `genericProjection` tombe à zéro. Il reste 11 instructions authorées hors cibles, dont un élément `test` avec 1 placement.

## 16. Validation PokeMap manifest load

Script temporaire : `/tmp/shadow59_validate_selbrume_manifest_test.dart`.

Commande :

```bash
cd packages/map_runtime && flutter test /tmp/shadow59_validate_selbrume_manifest_test.dart --plain-name 'shadow59 validate selbrume manifest'
```

Sortie complète :

```text
00:00 +0: loading /tmp/shadow59_validate_selbrume_manifest_test.dart
00:00 +0: shadow59 validate selbrume manifest
00:00 +1: All tests passed!
```

## 17. Tests de régression repo

Commande :

```bash
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +0: loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
00:00 +1: loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
00:00 +2: loadProjectManifestFromFile authored shadow manifest preserves manual and disabled shadows
00:00 +3: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat final exact :

```text
00:05 +233: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final exact :

```text
00:01 +284: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Résultat final exact :

```text
00:00 +96: All tests passed!
```

## 18. Ce qui n’a volontairement pas été modifié

Aucun :

- code de production ;
- test repo ;
- renderer ;
- profile Shadow ;
- modèle Shadow ;
- codec ;
- géométrie projection/contact ledge ;
- placement Selbrume ;
- `shadowOverride` ;
- asset ;
- fichier `/Users/karim/Desktop/selbrume/maps/Selbrume.json`.

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
```

`git diff --stat` ne liste pas les fichiers non suivis. Les livrables repo créés sont listés dans `git status final`.

## 20. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
```

## 21. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text
```

## 22. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/shadow_lot_59_selbrume_authored_shadow_cleanup_patch.md
?? reports/shadows/shadow_lot_59_selbrume_project_json_external_diff.diff
```

## 23. Risques / réserves

- Shadow-59 ne rend pas automatiquement toutes les ombres Pokémon-like. Il retire les cinq sources validées de grandes plaques dangereuses.
- L'inventaire after conserve 11 instructions statiques authorées hors périmètre, principalement des bâtiments/contact ledge et un élément `test`.
- Le patch modifie un fichier externe hors Git. La sauvegarde `project.shadow59.before.json` est donc la référence de rollback manuel si besoin.
- Le runtime inventory est une reconstruction déterministe à partir des données authorées et de la règle actuelle un placement shadow actif = une instruction statique. Il ne remplace pas un futur screenshot QA.

## 24. Auto-critique

- Ai-je modifié uniquement `/Users/karim/Desktop/selbrume/project.json` côté données Selbrume ? oui.
- Ai-je créé une sauvegarde avant écriture ? oui.
- Ai-je remplacé uniquement les 5 champs `shadow` ciblés ? oui, prouvé par diff et validation structurelle du script.
- Ai-je évité de modifier `Selbrume.json` ? oui, hash inchangé.
- Ai-je évité de modifier le code repo ? oui.
- Ai-je vérifié le manifest load après patch ? oui.
- Ai-je documenté l'écart `112 -> 11` au lieu de forcer `111 -> 10` ? oui.
- Ai-je évité tout commit ? oui.

## 25. Regard critique sur le prompt

Le prompt est sain pour ce stade : il donne une autorisation très limitée, impose une sauvegarde, interdit la réécriture massive, et demande un before/after. Le seul point à surveiller est la référence attendue `111 -> environ 10`, qui n'était pas exactement l'état réel actuel : l'inventaire trouve `112 -> 11` à cause d'un élément authoré supplémentaire `test`, hors périmètre des 5 cibles.

## 26. Prochain lot recommandé

Prochain lot recommandé :

```text
Shadow-60 — Selbrume Remaining Static Shadow Visual Review / Contact Ledge Cleanup Decision
```

Objectif : vérifier visuellement les 11 instructions restantes après nettoyage, identifier si `test` doit être neutralisé ou si certains contact ledges bâtiment doivent être ajustés/supprimés. Ce lot doit partir d'un screenshot/probe runtime après Shadow-59, pas d'une nouvelle calibration à l'aveugle.

## 27. Inventaire complet des fichiers créés/modifiés

Fichiers externes modifiés :

```text
/Users/karim/Desktop/selbrume/project.json
```

Fichiers externes créés :

```text
/Users/karim/Desktop/selbrume/project.shadow59.before.json
```

Fichiers repo créés :

```text
reports/shadows/shadow_lot_59_selbrume_authored_shadow_cleanup_patch.md
reports/shadows/shadow_lot_59_selbrume_project_json_external_diff.diff
```

Fichiers repo modifiés :

```text
Aucun
```

Fichiers repo supprimés :

```text
Aucun
```

Fichiers Selbrume non modifiés explicitement :

```text
/Users/karim/Desktop/selbrume/maps/Selbrume.json
assets / tilesets / images sous /Users/karim/Desktop/selbrume
```

## 28. Contenu complet des fichiers créés/modifiés par le lot

### `/tmp/shadow59_selbrume_cleanup.py`

Script temporaire hors repo, conservé dans le rapport pour preuve :

```python
#!/usr/bin/env python3
import argparse
import copy
import json
import pathlib
import sys

TARGETS = [
    "panneau",
    "lampadaire",
    "arbre_pixellab_1",
    "arbre_pixellab_2",
    "selbrume_maison_5",
]


def decode(text):
    return json.loads(text)


def string_end(text, quote_index):
    i = quote_index + 1
    escaped = False
    while i < len(text):
        ch = text[i]
        if escaped:
            escaped = False
        elif ch == "\\":
            escaped = True
        elif ch == '"':
            return i + 1
        i += 1
    raise ValueError("unterminated string")


def skip_ws(text, i):
    while i < len(text) and text[i] in " \t\r\n":
        i += 1
    return i


def matching_brace(text, start):
    if text[start] not in "{[":
        raise ValueError("matching_brace start is not brace")
    opening = text[start]
    closing = "}" if opening == "{" else "]"
    depth = 0
    i = start
    in_string = False
    escaped = False
    while i < len(text):
        ch = text[i]
        if in_string:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
        else:
            if ch == '"':
                in_string = True
            elif ch == opening:
                depth += 1
            elif ch == closing:
                depth -= 1
                if depth == 0:
                    return i + 1
        i += 1
    raise ValueError("no matching brace")


def value_end(text, start):
    start = skip_ws(text, start)
    ch = text[start]
    if ch in "{[":
        return matching_brace(text, start)
    if ch == '"':
        return string_end(text, start)
    i = start
    while i < len(text) and text[i] not in ",}\n\r\t ":
        i += 1
    return i


def object_ranges_in_elements(text):
    elements_key = '"elements"'
    key_pos = text.find(elements_key)
    if key_pos < 0:
        raise ValueError("elements key not found")
    colon = text.find(":", key_pos)
    array_start = text.find("[", colon)
    array_end = matching_brace(text, array_start)
    ranges = []
    i = array_start + 1
    while i < array_end - 1:
        i = skip_ws(text, i)
        if i >= array_end - 1:
            break
        if text[i] == ",":
            i += 1
            continue
        if text[i] != "{":
            raise ValueError(f"unexpected token in elements at {i}: {text[i:i+20]!r}")
        end = matching_brace(text, i)
        ranges.append((i, end))
        i = end
    return ranges


def top_level_property_value_range(object_text, property_name):
    key = json.dumps(property_name)
    i = 0
    depth = 0
    in_string = False
    escaped = False
    while i < len(object_text):
        ch = object_text[i]
        if in_string:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            if depth == 1 and object_text.startswith(key, i):
                after_key = i + len(key)
                j = skip_ws(object_text, after_key)
                if j < len(object_text) and object_text[j] == ":":
                    value_start = skip_ws(object_text, j + 1)
                    return value_start, value_end(object_text, value_start)
            in_string = True
            i += 1
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        i += 1
    raise ValueError(f"top-level property {property_name!r} not found")


def make_replacements(text, data):
    element_ranges = object_ranges_in_elements(text)
    replacements = []
    seen = set()
    elements = data.get("elements", [])
    target_elements = [element for element in elements if element.get("id") in TARGETS]
    if len(target_elements) != len(TARGETS):
        found = [element.get("id") for element in target_elements]
        missing = [target for target in TARGETS if target not in found]
        raise ValueError(f"expected {len(TARGETS)} target elements, found {len(target_elements)}; missing={missing}")
    if len({element.get("id") for element in target_elements}) != len(TARGETS):
        raise ValueError("target ids are not unique")

    for index, (start, end) in enumerate(element_ranges):
        object_text = text[start:end]
        id_value_start, id_value_end = top_level_property_value_range(object_text, "id")
        element_id = json.loads(object_text[id_value_start:id_value_end])
        if element_id not in TARGETS:
            continue
        if element_id in seen:
            raise ValueError(f"duplicate target id in text scan: {element_id}")
        seen.add(element_id)
        shadow_start, shadow_end = top_level_property_value_range(object_text, "shadow")
        absolute_start = start + shadow_start
        absolute_end = start + shadow_end
        shadow_text = text[absolute_start:absolute_end]
        shadow_before = json.loads(shadow_text)
        if shadow_before is None:
            raise ValueError(f"target {element_id} already has shadow null; refusing ambiguous patch")
        replacements.append({
            "id": element_id,
            "element_index": index,
            "start": absolute_start,
            "end": absolute_end,
            "shadow_before": shadow_before,
        })

    if set(seen) != set(TARGETS):
        raise ValueError(f"text scan targets mismatch: seen={sorted(seen)}")
    return sorted(replacements, key=lambda item: item["start"])


def apply_replacements(text, replacements):
    patched = text
    for item in sorted(replacements, key=lambda item: item["start"], reverse=True):
        patched = patched[:item["start"]] + "null" + patched[item["end"]:]
    return patched


def validate_only_targeted_shadows_changed(before_data, after_data):
    normalized_before = copy.deepcopy(before_data)
    for element in normalized_before["elements"]:
        if element.get("id") in TARGETS:
            element["shadow"] = None
    return normalized_before == after_data


def print_replacements(prefix, replacements):
    print(prefix)
    print(f"target ids found: {len(replacements)}")
    for item in replacements:
        summary = {
            "castsShadow": item["shadow_before"].get("castsShadow"),
            "shadowProfileId": item["shadow_before"].get("shadowProfileId"),
            "family": item["shadow_before"].get("family"),
        }
        print(
            f"id={item['id']} element_index={item['element_index']} "
            f"range={item['start']}..{item['end']} "
            f"shadow_before={json.dumps(summary, ensure_ascii=False, sort_keys=True)} "
            f"action=replace-shadow-value-with-null"
        )
    print(f"replacements planned: {len(replacements)}")
    print("no other changes planned: true")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dry-run", action="store_true")
    group.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    project_path = pathlib.Path(args.project)
    text = project_path.read_text(encoding="utf-8")
    before_data = decode(text)
    replacements = make_replacements(text, before_data)

    if args.dry_run:
        print_replacements("shadow59 dry-run", replacements)
        return 0

    backup_path = project_path.with_name("project.shadow59.before.json")
    if not backup_path.exists():
        raise FileNotFoundError(f"required backup missing: {backup_path}")
    backup_text = backup_path.read_text(encoding="utf-8")
    if backup_text != text:
        raise ValueError("backup does not match current project before apply")

    patched = apply_replacements(text, replacements)
    after_data = decode(patched)
    if not validate_only_targeted_shadows_changed(before_data, after_data):
        raise ValueError("patched JSON differs beyond targeted shadow fields")
    project_path.write_text(patched, encoding="utf-8")
    print("shadow59 apply")
    print(f"backup required: {backup_path} exists")
    print(f"replacements applied: {len(replacements)}")
    print("json valid after: true")
    print("only targeted shadows changed: true")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

### `/tmp/shadow59_selbrume_instruction_inventory.py`

Script temporaire hors repo, conservé dans le rapport pour preuve :

```python
#!/usr/bin/env python3
import json
import pathlib
import sys

TARGETS = [
    "panneau",
    "lampadaire",
    "arbre_pixellab_1",
    "arbre_pixellab_2",
    "selbrume_maison_5",
]


def placed_objects(node):
    if isinstance(node, dict):
        if "elementId" in node:
            yield node
        for value in node.values():
            yield from placed_objects(value)
    elif isinstance(node, list):
        for value in node:
            yield from placed_objects(value)


def inventory(project_path, map_path, label):
    project = json.loads(pathlib.Path(project_path).read_text(encoding="utf-8"))
    map_data = json.loads(pathlib.Path(map_path).read_text(encoding="utf-8"))
    elements = {element["id"]: element for element in project["elements"]}
    placements = list(placed_objects(map_data))
    counts_by_element = {}
    generic_by_element = {}
    building_by_element = {}
    static_total = 0
    generic_total = 0
    building_total = 0
    for placed in placements:
        element_id = placed.get("elementId")
        element = elements.get(element_id)
        if not element:
            continue
        shadow = element.get("shadow")
        if not shadow or shadow.get("castsShadow") is not True:
            continue
        static_total += 1
        counts_by_element[element_id] = counts_by_element.get(element_id, 0) + 1
        family = shadow.get("family")
        if family is None or family == "genericProjection":
            generic_total += 1
            generic_by_element[element_id] = generic_by_element.get(element_id, 0) + 1
        if family == "building":
            building_total += 1
            building_by_element[element_id] = building_by_element.get(element_id, 0) + 1

    print(f"inventory {label}")
    print(f"project={project_path}")
    print(f"placements_total={len(placements)}")
    print(f"static_instructions_total={static_total}")
    print(f"projectedPolygon_total={static_total}")
    print(f"genericProjection_total={generic_total}")
    print(f"building_family_total={building_total}")
    for target in TARGETS:
        print(f"target {target} instructions={counts_by_element.get(target, 0)} genericProjection={generic_by_element.get(target, 0)}")
    top = sorted(counts_by_element.items(), key=lambda item: (-item[1], item[0]))[:20]
    print("top_shadow_elements=" + json.dumps(top, ensure_ascii=False))


def main():
    if len(sys.argv) != 4:
        print("usage: inventory PROJECT MAP LABEL", file=sys.stderr)
        return 2
    inventory(sys.argv[1], sys.argv[2], sys.argv[3])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

### `/tmp/shadow59_validate_selbrume_manifest_test.dart`

Test temporaire hors repo, conservé dans le rapport pour preuve :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

void main() {
  test('shadow59 validate selbrume manifest', () async {
    final manifest = await loadProjectManifestFromFile(
      '/Users/karim/Desktop/selbrume/project.json',
    );
    final elementsById = {
      for (final element in manifest.elements) element.id: element,
    };
    const targets = <String>[
      'panneau',
      'lampadaire',
      'arbre_pixellab_1',
      'arbre_pixellab_2',
      'selbrume_maison_5',
    ];
    for (final id in targets) {
      expect(elementsById[id], isNotNull, reason: id);
      expect(elementsById[id]!.shadow, isNull, reason: id);
    }
    final remainingShadowElements = manifest.elements
        .where((element) => element.shadow != null)
        .map((element) => element.id)
        .toList();
    expect(remainingShadowElements.length, 20);
    expect(remainingShadowElements, isNotEmpty);
  });
}
```

### `reports/shadows/shadow_lot_59_selbrume_project_json_external_diff.diff`

```diff
--- /Users/karim/Desktop/selbrume/project.shadow59.before.json	2026-05-17 21:55:20
+++ /Users/karim/Desktop/selbrume/project.json	2026-05-17 21:56:53
@@ -2816,18 +2816,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-soft-ellipse",
-        "offsetY": -6.0,
-        "opacity": 0.22,
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 0.96,
-          "footprintWidthRatio": 0.68,
-          "footprintHeightRatio": 0.08
-        }
-      },
+      "shadow": null,
       "groupId": "group_1777757343053",
       "recommendedLayerId": null,
       "tags": [],
@@ -6188,22 +6177,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-contact-blob",
-        "offsetX": 0.0,
-        "offsetY": 0.0,
-        "scaleX": 0.8,
-        "scaleY": 0.55,
-        "opacity": 0.2,
-        "family": "tallProp",
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 1.0,
-          "footprintWidthRatio": 0.28,
-          "footprintHeightRatio": 0.05
-        }
-      },
+      "shadow": null,
       "groupId": null,
       "recommendedLayerId": null,
       "tags": [],
@@ -6815,18 +6789,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-soft-ellipse",
-        "offsetY": -10.0,
-        "opacity": 0.25,
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 0.92,
-          "footprintWidthRatio": 0.58,
-          "footprintHeightRatio": 0.1
-        }
-      },
+      "shadow": null,
       "groupId": null,
       "recommendedLayerId": null,
       "tags": [],
@@ -7004,18 +6967,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-soft-ellipse",
-        "offsetY": -10.0,
-        "opacity": 0.25,
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 0.92,
-          "footprintWidthRatio": 0.5,
-          "footprintHeightRatio": 0.1
-        }
-      },
+      "shadow": null,
       "groupId": null,
       "recommendedLayerId": null,
       "tags": [],
@@ -8069,21 +8021,7 @@
         "manualAddedCells": [],
         "manualRemovedCells": []
       },
-      "shadow": {
-        "castsShadow": true,
-        "shadowProfileId": "default-ground-wide-ellipse",
-        "offsetX": 0.0,
-        "offsetY": 0.0,
-        "scaleX": 0.92,
-        "scaleY": 0.75,
-        "opacity": 0.27,
-        "footprint": {
-          "anchorXRatio": 0.5,
-          "anchorYRatio": 0.95,
-          "footprintWidthRatio": 0.72,
-          "footprintHeightRatio": 0.1
-        }
-      },
+      "shadow": null,
       "groupId": null,
       "recommendedLayerId": null,
       "tags": [],
```

### `/Users/karim/Desktop/selbrume/project.json`

Le fichier externe a été modifié par patch textuel minimal. Le diff complet du changement est inclus ci-dessus et montre l'intégralité des modifications appliquées : les cinq valeurs `shadow` ciblées remplacées par `null`, sans autre changement.
