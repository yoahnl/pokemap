# Rapport Lot 2 — Fichiers JSON racines de la base Pokémon locale

## 1. Résumé exécutif

### Ce qui a été fait

Ce lot crée uniquement les premiers fichiers JSON racines pour la future base Pokémon locale dans `data/pokemon/` :

- 11 fichiers de catalogues vides dans `data/pokemon/catalogs/`
- 1 manifeste racine léger dans `data/pokemon/pokemon_data_manifest.json`

Le format retenu est volontairement minimal :

- `schemaVersion`
- `kind`
- `catalog` pour les fichiers catalogue
- `entries: []`
- un index simple des chemins dans le manifeste

### Ce qui n'a pas été fait

Ce lot n'ajoute volontairement rien d'autre :

- aucun modèle Dart
- aucun repository
- aucun service
- aucun parser
- aucune UI
- aucune logique runtime
- aucun import Showdown / PokeAPI
- aucune vraie donnée Pokémon
- aucun fichier espèce / learnset / évolution métier
- aucune modification de `project.json`

### Pourquoi ce lot reste petit

L'objectif ici est strictement structurel. On prépare les points d'entrée des futurs catalogues sans commencer prématurément la modélisation métier ni le code applicatif. Le lot reste donc facile à relire, facile à corriger et sans ambiguïté.

## 2. Liste exacte des fichiers créés

### Fichiers JSON créés

- `data/pokemon/pokemon_data_manifest.json`
- `data/pokemon/catalogs/moves.json`
- `data/pokemon/catalogs/abilities.json`
- `data/pokemon/catalogs/items.json`
- `data/pokemon/catalogs/types.json`
- `data/pokemon/catalogs/growth_rates.json`
- `data/pokemon/catalogs/natures.json`
- `data/pokemon/catalogs/egg_groups.json`
- `data/pokemon/catalogs/habitats.json`
- `data/pokemon/catalogs/generations.json`
- `data/pokemon/catalogs/version_groups.json`
- `data/pokemon/catalogs/encounter_rules.json`

### Autre changement de fichier

- suppression de `data/pokemon/catalogs/.gitkeep`

Cette suppression est volontaire et saine : le dossier `catalogs/` n'est plus vide, donc le placeholder n'a plus d'utilité.

## 3. Contenu exact des fichiers JSON créés

### `data/pokemon/pokemon_data_manifest.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_data_manifest",
  "catalogFiles": {
    "moves": "catalogs/moves.json",
    "abilities": "catalogs/abilities.json",
    "items": "catalogs/items.json",
    "types": "catalogs/types.json",
    "growthRates": "catalogs/growth_rates.json",
    "natures": "catalogs/natures.json",
    "eggGroups": "catalogs/egg_groups.json",
    "habitats": "catalogs/habitats.json",
    "generations": "catalogs/generations.json",
    "versionGroups": "catalogs/version_groups.json",
    "encounterRules": "catalogs/encounter_rules.json"
  }
}
```

### `data/pokemon/catalogs/moves.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "moves",
  "entries": []
}
```

### `data/pokemon/catalogs/abilities.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "abilities",
  "entries": []
}
```

### `data/pokemon/catalogs/items.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "items",
  "entries": []
}
```

### `data/pokemon/catalogs/types.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "types",
  "entries": []
}
```

### `data/pokemon/catalogs/growth_rates.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "growth_rates",
  "entries": []
}
```

### `data/pokemon/catalogs/natures.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "natures",
  "entries": []
}
```

### `data/pokemon/catalogs/egg_groups.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "egg_groups",
  "entries": []
}
```

### `data/pokemon/catalogs/habitats.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "habitats",
  "entries": []
}
```

### `data/pokemon/catalogs/generations.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "generations",
  "entries": []
}
```

### `data/pokemon/catalogs/version_groups.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "version_groups",
  "entries": []
}
```

### `data/pokemon/catalogs/encounter_rules.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "encounter_rules",
  "entries": []
}
```

## 4. Explication du format choisi

Le format choisi est volontairement petit et stable.

### Pourquoi `schemaVersion`

Il permet d'indiquer dès maintenant un point d'ancrage pour de futures évolutions de format, sans introduire de logique applicative.

### Pourquoi `kind`

Il évite l'ambiguïté si, plus tard, plusieurs familles de JSON cohabitent dans `data/pokemon/`. Cela reste léger et lisible.

### Pourquoi `catalog`

Ce champ rend chaque fichier auto-descriptif. Si un fichier est ouvert hors contexte, son rôle reste évident.

### Pourquoi `entries: []`

Le besoin produit parle de fichiers vides ou quasi vides, mais déjà prêts pour la suite. Un tableau vide correspond exactement à cet objectif sans inventer de champs métier spéculatifs.

### Pourquoi ajouter un manifeste racine

Le manifeste apporte une vraie valeur structurelle dès maintenant :

- point d'entrée unique des catalogues
- index explicite des chemins
- séparation claire entre l'index global et le contenu de chaque catalogue

Il reste volontairement minimal et n'introduit aucune logique métier.

## 5. Vérifications effectuées

### Vérification de l'arborescence et des fichiers

J'ai vérifié l'état de `data/pokemon/` avant création puis après création pour confirmer :

- la présence des nouveaux JSON
- l'absence d'autres fichiers métier non demandés
- le maintien des autres dossiers (`species`, `learnsets`, `evolutions`, `media`) sans démarrage prématuré de contenu

### Vérification de la validité JSON

Les 12 fichiers JSON créés ont été relus et validés via un chargement JSON réel.

Résultat :

```text
validated 12 json files
```

### Vérification que `project.json` n'a pas été touché

Commande exécutée :

```text
git status --short -- '**/project.json'
```

Sortie réelle :

```text
<aucune sortie>
```

Donc aucun `project.json` n'a été modifié.

### Vérification qu'aucun code applicatif n'a été modifié

Commande exécutée :

```text
git status --short -- . ':(exclude)data/pokemon' ':(exclude)reports/pokemon-data-lot-2-report.md'
```

Sortie réelle :

```text
<aucune sortie>
```

Donc ce lot n'a modifié aucun code applicatif.

## 6. Git diff / état Git

### `git status --short`

Sortie réelle au moment du lot avant création du rapport :

```text
 D data/pokemon/catalogs/.gitkeep
?? data/pokemon/catalogs/abilities.json
?? data/pokemon/catalogs/egg_groups.json
?? data/pokemon/catalogs/encounter_rules.json
?? data/pokemon/catalogs/generations.json
?? data/pokemon/catalogs/growth_rates.json
?? data/pokemon/catalogs/habitats.json
?? data/pokemon/catalogs/items.json
?? data/pokemon/catalogs/moves.json
?? data/pokemon/catalogs/natures.json
?? data/pokemon/catalogs/types.json
?? data/pokemon/catalogs/version_groups.json
?? data/pokemon/pokemon_data_manifest.json
```

### État Git ciblé sur le lot

Commande exécutée :

```text
git ls-files --others --exclude-standard -- data/pokemon reports/pokemon-data-lot-2-report.md
```

Sortie réelle :

```text
data/pokemon/catalogs/abilities.json
data/pokemon/catalogs/egg_groups.json
data/pokemon/catalogs/encounter_rules.json
data/pokemon/catalogs/generations.json
data/pokemon/catalogs/growth_rates.json
data/pokemon/catalogs/habitats.json
data/pokemon/catalogs/items.json
data/pokemon/catalogs/moves.json
data/pokemon/catalogs/natures.json
data/pokemon/catalogs/types.json
data/pokemon/catalogs/version_groups.json
data/pokemon/pokemon_data_manifest.json
```

### `git diff --stat -- data/pokemon reports/pokemon-data-lot-2-report.md`

Sortie réelle :

```text
 data/pokemon/catalogs/.gitkeep | 1 -
 1 file changed, 1 deletion(-)
```

Important :

- `git diff --stat` n'affiche ici que la suppression du `.gitkeep` car les nouveaux JSON sont encore non suivis
- c'est normal avec Git
- les nouveaux fichiers sont visibles dans `git status --short` et `git ls-files --others --exclude-standard`

## 7. Commandes réellement exécutées

Voici la liste des commandes réellement lancées pour ce lot :

```text
find . -name AGENTS.md -print
find data/pokemon -maxdepth 3 \( -type d -o -type f \) | sort
ls -la review_bundle.sh
git status --short
find data/pokemon -maxdepth 2 \( -type f -o -type d \) | sort
for f in data/pokemon/pokemon_data_manifest.json data/pokemon/catalogs/*.json; do echo '---' $f; cat "$f"; echo; done
sed -n '1,220p' review_bundle.sh
python3 - <<'PY'
import json, pathlib
files = [pathlib.Path('data/pokemon/pokemon_data_manifest.json'), *sorted(pathlib.Path('data/pokemon/catalogs').glob('*.json'))]
for path in files:
    with path.open() as fh:
        json.load(fh)
print(f'validated {len(files)} json files')
PY
git status --short -- data/pokemon reports/pokemon-data-lot-2-report.md project.json '**/project.json'
./review_bundle.sh
cat .review/review-20260408-205135.txt
git status --short
git diff --stat -- data/pokemon reports/pokemon-data-lot-2-report.md
git diff --name-only -- data/pokemon reports/pokemon-data-lot-2-report.md
git status --short -- . ':(exclude)data/pokemon' ':(exclude)reports/pokemon-data-lot-2-report.md'
git status --short -- '**/project.json'
git ls-files --others --exclude-standard -- data/pokemon reports/pokemon-data-lot-2-report.md
```

En plus de ces commandes, les fichiers JSON et ce rapport ont été ajoutés via l'outil d'édition local du workspace.

## 8. `./review_bundle.sh` obligatoire

### Commande exécutée

```text
./review_bundle.sh
```

### Résultat

La commande a réussi.

Chemin du fichier généré :

```text
.review/review-20260408-205135.txt
```

### Contenu intégral du fichier généré

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 20:51:35
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: c41fe7e193eb012febd35c14069563181f0b24eb

## GIT STATUS --SHORT

 D data/pokemon/catalogs/.gitkeep
?? data/pokemon/catalogs/abilities.json
?? data/pokemon/catalogs/egg_groups.json
?? data/pokemon/catalogs/encounter_rules.json
?? data/pokemon/catalogs/generations.json
?? data/pokemon/catalogs/growth_rates.json
?? data/pokemon/catalogs/habitats.json
?? data/pokemon/catalogs/items.json
?? data/pokemon/catalogs/moves.json
?? data/pokemon/catalogs/natures.json
?? data/pokemon/catalogs/types.json
?? data/pokemon/catalogs/version_groups.json
?? data/pokemon/pokemon_data_manifest.json

## GIT DIFF --STAT

 data/pokemon/catalogs/.gitkeep | 1 -
 1 file changed, 1 deletion(-)

## CHANGED FILES

data/pokemon/catalogs/.gitkeep

## RECENT COMMITS

c41fe7e Add data and assets folder structure with .gitkeep placeholders for future Pokémon content
3d81349 Add tests to confirm grid-based collision granularity limitations and document runtime constraints
8675f74 Add migration for broken legacy manual collision profiles
59dce2a Audit runtime collision logic to validate `cells` as the active source of truth
2aa52f4 Fix collision base model to support authored shapes and resolve padding-based overcapture issues
fc7cf31 Enhance polygon rasterization logic and add backend cell preview to collision editor
fe5da3e Add tests for project collision profile persistence and enhance UI behavior in element collision editor
5d65444 Add element collision editor UI and rasterization services
e63e6cf Add element collision authoring services and padding-based workflow
5f714b5 Persist last opened project state and add auto-restore support
7a137dd Remove LOT 50 demo scenario and inject logic; add FPS overlay support
13127d3 Implement runtime completion gating for cutscenes in Step Studio
0587713 Implement defensive validation for Step Studio document persistence
650270b Implement auto-fix for completion normalization and enhance save validation in Step Studio
27ab0c1 Add detailed tracing for world changes in Step Studio

## FULL DIFF

diff --git a/data/pokemon/catalogs/.gitkeep b/data/pokemon/catalogs/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/data/pokemon/catalogs/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
```

### Interprétation utile du bundle

Le bundle reflète bien l'état Git, mais il a une limite importante :

- il compare contre `HEAD`
- il montre donc la suppression du `.gitkeep`
- il ne liste pas les nouveaux fichiers non suivis dans les sections `GIT DIFF --STAT`, `CHANGED FILES` et `FULL DIFF`
- en revanche, ces nouveaux fichiers apparaissent bien dans `GIT STATUS --SHORT`

Le rapport principal compense explicitement cette limite avec `git status --short` et `git ls-files --others --exclude-standard`.

## 9. Validation finale

### Le lot reste bien dans le périmètre

Oui.

- seulement des fichiers JSON racines de catalogues
- un manifeste racine léger
- aucun dépassement vers les espèces, learnsets, évolutions métier

### Aucun code applicatif n'a été ajouté

Oui.

- pas de Dart
- pas de logique runtime
- pas d'UI
- pas de repository
- pas de parser

### `project.json` n'a pas été touché

Oui. Vérifié explicitement via Git.

### Aucune donnée Pokémon réelle n'a été ajoutée

Oui. Tous les tableaux `entries` sont vides.

### Le format est prêt pour la suite sans spéculation excessive

Oui. Le format est :

- lisible
- minimal
- stable
- évolutif

sans sur-ingénierie.

### Aucune opération Git d'écriture n'a été faite

Oui.

- pas de commit
- pas d'amend
- pas de merge
- pas de rebase
- pas de push
- pas de tag
- pas de reset
- pas de stash

## Conclusion

Le lot 2 livre exactement ce qui était demandé :

- les premiers fichiers JSON racines pour la base Pokémon locale
- un format minimal cohérent
- aucun code applicatif
- aucune donnée métier réelle
- un rapport complet
- le contenu intégral du fichier généré par `./review_bundle.sh`

La suite pourra maintenant construire les prochains lots sur une base JSON locale claire, sans mélanger contenu Pokémon et `project.json`.
