# REPO-HYGIENE-MD-001 — Audit et garde-fou Markdown

Date : 2026-08-02
Périmètre : organisation documentaire du dépôt PokeMap, rangement de la racine
et prévention de la prolifération de fichiers Markdown par les agents.
Lot mécanique `FG-*` : non applicable ; aucun comportement de fangame n'est
modifié.

## Résumé exécutif

Le désordre perçu est confirmé, mais il est concentré dans les historiques :

- état initial : **1 958 Markdown** dans le worktree ;
- **1 758 suivis**, **200 ignorés**, aucun Markdown non ignoré/non suivi ;
- `reports/` : **1 556 fichiers**, **87 092 071 octets** et **2 290 499 lignes** ;
- racine : seulement **16 fichiers**, mais 11 étaient mal rangés ;
- état après rangement : **5 Markdown contractuels à la racine** ;
- aucune suppression massive n'a été faite : aucun doublon exact suivi-vers-
  suivi n'a été prouvé et le worktree contenait déjà un chantier Smart Tiles
  important et concurrent.

Le lot apporte trois niveaux de protection : règles agents cohérentes, contrôle
local testé, et contrôle GitHub Actions. Le contrôle refuse par défaut tout
nouveau Markdown persistant, les emplacements non canoniques, les documents
ignorés non baselinés, les copies `created_files_full_content`, les nouveaux
fichiers supérieurs à 256 Kio et la création en masse.

## Scope confirmé et non-objectifs

Inclus :

- inventaire complet des Markdown présents, suivis et ignorés ;
- analyse des tailles, doublons exacts, concentrations et références littérales ;
- rangement non destructif des Markdown de racine sans contrat applicatif ;
- correction des règles qui forçaient les agents à écrire des rapports/plans ;
- script, tests et CI de non-régression documentaire ;
- classement des futurs lots de suppression par risque.

Exclus volontairement :

- aucune suppression des 1 556 rapports suivis sans validation humaine du lot ;
- aucune suppression des 85 documents ignorés de `docs/`, car ils n'ont pas
  d'historique Git et peuvent être uniques ;
- aucune modification du chantier Smart Tiles déjà présent ;
- aucun changement de code Dart/Flutter ou de contrat PokeMap ;
- aucune opération Git d'écriture (`add`, `commit`, `push`, etc.).

## Audit initial

### Répartition

| Zone | Markdown | Suivis | Ignorés | Signal |
|---|---:|---:|---:|---|
| `reports/` | 1 556 | 1 556 | 0 | foyer principal, 88,5 % des Markdown suivis |
| `docs/` | 131 | 46 | 85 | politique `.gitignore` incohérente |
| `.superpowers/` | 75 | 2 | 73 | sorties/caches d'agents |
| `packages/` | 55 | 48 | 7 | README + 27 rapports éditeur historiques |
| `skills/` | 43 | 43 | 0 | workflows locaux |
| `tools/` | 29 | 2 | 27 | dépendances générées |
| racine | 16 | 16 | 0 | 11 documents déplaçables |
| autres zones | 53 | 51 | 2 | projets, exemples et archives secondaires |

Principaux sous-domaines suivis :

| Zone | Fichiers | Taille observée |
|---|---:|---:|
| `reports/narrativeStudio/` | 475 | environ 17,25 Mio |
| `reports/previous/` | 229 | 25 265 310 octets |
| `reports/surface/` | 155 | environ 11,73 Mio |
| `reports/shadows/` | 153 | environ 6,32 Mio |
| `reports/analysis/` | 106 | environ 3,44 Mio |
| `reports/gameplay/` | 100 | environ 3,31 Mio |
| `reports/roadmap/` | 72 | environ 2,49 Mio |
| `reports/pathPattern/` | 58 | environ 3,08 Mio |

### Volume et redondance

- 184 rapports dépassent 100 000 octets et totalisent 46 290 119 octets.
- 14 dépassent 500 000 octets ; 2 dépassent 1 000 000 octets.
- 261 noms contiennent `evidence` et totalisent 14 110 966 octets.
- 14 `created_files_full_content` totalisent 1 455 257 octets ; les 14 sont
  référencés par leurs Evidence Packs associés.
- `reports/previous/` contient 229 fichiers et 25 265 310 octets ; 14 de ces
  chemins sont référencés littéralement depuis 3 autres rapports.
- 7 groupes de contenu SHA-256 identique couvrent 23 fichiers, mais toutes les
  copies impliquent au moins un cache, build ou fichier ignoré. Aucun doublon
  exact entre deux Markdown suivis n'a été prouvé.
- Le scan littéral des rapports trouve 693 fichiers sans référence entrante,
  mais cela ne prouve pas qu'ils sont inutiles pour un lecteur humain.

### Causes structurelles

1. `codex_rule.md` exigeait de recopier le contenu complet de chaque fichier
   créé, ce qui a directement alimenté les Evidence Packs géants.
2. `skills/writing-plans/SKILL.md` imposait
   `docs/superpowers/plans/`, alors que `/docs/*` est ignoré.
3. `.cursor/scope_rules.md` et `.cursor/code_generation_rules.md` imposaient des
   rapports sous `packages/map_editor/reports/`, en contradiction avec
   `reports/<domain>/`.
4. Les règles disaient qu'un « rapport final » était obligatoire sans préciser
   qu'il devait rester dans la réponse de chat par défaut.
5. Aucun contrôle automatisé n'empêchait un agent de créer des dizaines de
   Markdown ou un unique rapport de plusieurs mégaoctets.

### Classification de la racine

Conservés :

- `AGENTS.md` : instructions automatiques du dépôt ;
- `agent_rules.md` : règles historiques encore massivement référencées ;
- `codex_rule.md` : règle canonique imposée pour rapports/audits ;
- `pokemap_roadmap_mecaniques_fangame.md` : emplacement imposé par `AGENTS.md` ;
- `pokemap_authoring_api_mcp_action_catalog.md` : chemin consommé en dur par
  `packages/map_core/lib/src/tooling/repository_authoring_capability_collector.dart`.

Déplacés sans altération de contenu :

- `SKILL.md` vers `skills/karpathy-guidelines/SKILL.md` ;
- `design-qa.md` vers
  `reports/narrativeStudio/ui_convergence/design-qa.md` ;
- les neuf roadmap/plans PMCP vers
  `reports/roadmap/authoring_api_mcp/`.

Neuf comparaisons SHA-256 `HEAD:<ancien chemin>` vers le nouveau chemin sont
identiques. Les plans de phases 2 et 3 diffèrent uniquement par la correction de
leurs commandes `git add`, qui pointent désormais vers leur destination réelle.

## Décisions et garde-fous implémentés

### Règles agents

`AGENTS.md`, `agent_rules.md` et `codex_rule.md` établissent maintenant :

- budget par défaut : zéro nouveau Markdown ;
- rapport final dans le chat, sauf livrable persistant explicitement demandé ;
- un seul document consolidé au lieu d'un fichier par agent/passe/commande ;
- racine limitée aux cinq contrats listés ci-dessus ;
- interdiction de `*_created_files_full_content.md` ;
- destinations canoniques : `reports/<domain>/`,
  `reports/<domain>/plans/`, `reports/roadmap/<domain>/`, `docs/<domain>/` et
  `skills/<skill-name>/` ;
- exécution obligatoire du contrôle d'hygiène avant la clôture.

Les quatre règles `.cursor/` concernées ont été alignées sur
`reports/editor/` uniquement lorsqu'un rapport persistant est demandé.

### Planification agentique

`skills/writing-plans/SKILL.md` ne force plus la création d'un worktree ni d'un
plan sous `docs/superpowers/plans/`. Le plan reste en session par défaut ; Git et
la persistance nécessitent une autorisation explicite.

Le signal RED historique est mesurable : 85 Markdown uniques sont aujourd'hui
ignorés sous `docs/`, dont 59 plans/specs Superpowers et 18 rapports de lots.

### Contrôle local

`scripts/check_markdown_hygiene.sh` contrôle les Markdown ajoutés ou renommés
depuis `HEAD` ou une base de PR :

- `.md`, `.mdx` et `.markdown`, insensibles à la casse ;
- limite locale de zéro nouveau fichier par défaut ;
- dérogation bornée via `POKEMAP_MARKDOWN_MAX_NEW` seulement après demande
  humaine explicite ;
- limite par défaut de 262 144 octets ;
- emplacements canoniques uniquement ;
- rejet des copies `created_files_full_content` ;
- détection des Markdown ignorés hors baseline ;
- reconnaissance SHA-256 des déplacements exacts encore non indexés ;
- validation des destinations de renommage, même sans consommation du budget.

`scripts/markdown_hygiene_ignored_baseline.txt` inventorie exactement les 85
documents `docs/` ignorés existants, sans les supprimer ni les légitimer. Les
arbres régénérables `.dart_tool`, `build`, `node_modules` et `sprites-master`
sont volontairement exclus.

### Contrôle CI

`.github/workflows/markdown_hygiene.yml` lance les 18 scénarios de test et le
checker sur toutes les pull requests, sans filtre d'extension sensible à la
casse. Le seuil CI est 3 nouveaux
Markdown : c'est un filet anti-prolifération plus tolérant que la règle
sémantique locale à zéro. Il ne devient bloquant au merge que si ce check est
rendu obligatoire dans la protection de branche GitHub.

## Fichiers du lot et zones modifiées

### Règles modifiées

- `AGENTS.md` — nouvelle section « Markdown hygiene », destinations et preuve
  attendue ;
- `agent_rules.md` — discipline de dépôt et reporting alignés ;
- `codex_rule.md` — fin de la copie intégrale des sources et rapport de chat par
  défaut ;
- `.cursor/README.md` — source de faits persistants corrigée ;
- `.cursor/project_vision.md` — destination canonique `reports/editor/` ;
- `.cursor/scope_rules.md` — rapport persistant uniquement sur demande ;
- `.cursor/code_generation_rules.md` — même règle pour les refontes ;
- `skills/README.md` — index du skill Karpathy rangé ;
- `skills/writing-plans/SKILL.md` — plan en session par défaut.

### Fichiers créés

- `.github/workflows/markdown_hygiene.yml` — gate CI ciblé ;
- `scripts/check_markdown_hygiene.sh` — contrôle changed-only ;
- `scripts/test_check_markdown_hygiene.sh` — 18 scénarios sur des dépôts Git
  temporaires ;
- `scripts/markdown_hygiene_ignored_baseline.txt` — 85 chemins ignorés audités ;
- ce rapport consolidé.

### Déplacements exacts

- `SKILL.md` → `skills/karpathy-guidelines/SKILL.md` ;
- `design-qa.md` →
  `reports/narrativeStudio/ui_convergence/design-qa.md` ;
- `pokemap_authoring_api_mcp_lot_roadmap.md` →
  `reports/roadmap/authoring_api_mcp/pokemap_authoring_api_mcp_lot_roadmap.md` ;
- `pokemap_authoring_api_mcp_phase_roadmap.md` →
  `reports/roadmap/authoring_api_mcp/pokemap_authoring_api_mcp_phase_roadmap.md` ;
- `pokemap_authoring_api_mcp_phase_1_implementation_plan.md` à
  `pokemap_authoring_api_mcp_phase_7_implementation_plan.md` → mêmes noms sous
  `reports/roadmap/authoring_api_mcp/`.

Le catalogue `pokemap_authoring_api_mcp_action_catalog.md` avait été envisagé
pour déplacement, puis explicitement conservé avant clôture après découverte du
contrat de chemin `map_core`. Son contenu et son emplacement final sont
inchangés.

## Tests et validations

### TDD du checker

RED observés avant implémentation/correction :

- checker absent ;
- Markdown ignoré non détecté ;
- déplacement exact non indexé compté comme nouveau ;
- extension `.markdown` non détectée ;
- build ignoré racine faussement rejeté.

Couverture finale : comportement positif, emplacements négatifs, documents
ignorés, snapshots interdits, limite de masse, limite de taille, renommages,
déplacements exacts, prévention d'une duplication déguisée en déplacement et
non-régression des builds générés.

Commandes finales et résultats :

```text
bash -n scripts/check_markdown_hygiene.sh scripts/test_check_markdown_hygiene.sh
PASS (exit 0, aucune sortie)

bash scripts/test_check_markdown_hygiene.sh
PASS: 18 Markdown hygiene scenarios

POKEMAP_MARKDOWN_MAX_NEW=3 bash scripts/check_markdown_hygiene.sh
Markdown hygiene: 3 new Markdown file(s), all in canonical locations.

ruby -e 'require "yaml"; YAML.load_file(".github/workflows/markdown_hygiene.yml"); puts "PASS: workflow YAML parsed"'
PASS: workflow YAML parsed

comparaison SHA-256 des 11 déplacements
MOVE_SHA_SUMMARY 9/11 exacts ; 2/11 modifiés uniquement pour les chemins git add

comparaison des liens Markdown locaux HEAD/worktree
HEAD: 21 cibles relatives manquantes
WORKTREE: 21 cibles relatives manquantes
introduced_missing=0
resolved_missing=0
```

La dette de 21 liens locaux manquants est préexistante. Un link checker global
strict donnerait un faux échec ; un futur gate doit être baseliné/changed-only.

Analyse Dart/Flutter : non lancée, car aucun fichier Dart/Flutter du lot n'est
modifié. Les nombreux fichiers Smart Tiles présents dans le statut appartiennent
à un chantier préexistant/concurrent.

Build : non applicable. La meilleure alternative est la validation Bash, YAML,
SHA-256 et liens changed-only ci-dessus.

## État Git initial

La commande initiale était :

```text
git status --short --untracked-files=all
```

Elle montrait **55 entrées** : 45 modifications, 2 suppressions et 8 fichiers non
suivis. Cela couvrait les suppressions de `emotions.png` et `emotions2.png`, le
chantier Smart Tiles dans `packages/map_core` et `packages/map_editor`, trois
rapports éditeur modifiés et un cache Python non suivi. Aucun de ces fichiers
n'a été modifié ou nettoyé par ce lot.

Pendant l'audit, le chantier concurrent a encore ajouté des fichiers
`smart_tile_*` et a fait disparaître les deux suppressions d'images du statut.
Cette dérive externe explique que les états initial et final ne puissent pas
être comparés comme un diff exclusivement attribuable à ce lot.

## État Git final

À la clôture, les changements de ce lot apparaissent comme modifications,
suppression des anciens chemins et nouveaux chemins non suivis, car aucune
opération `git add` n'était autorisée. Git pourra les reconnaître comme renames
au staging/commit.

Le statut final complet doit être lu comme deux ensembles :

- total worktree : **94 entrées** (`55 M`, `11 D`, `28 ??`) ;
- ce lot : **36 entrées** (`9 M`, `11 D`, `16 ??`), représentant 9 règles/index
  modifiés, 11 déplacements, 4 fichiers script/config créés et ce rapport ;
- hors lot : **58 entrées** (`46 M`, `12 ??`), couvrant le chantier Smart Tiles,
  les rapports éditeur et le cache Python déjà présents/concurrents.

## Verdict des sub-agents / passes

- **Audit / Architecture — PASS prudent** : volume confirmé ; aucune suppression
  suivie sûre sans migration de références ; racine cible à cinq contrats.
- **Implémentation — PASS** : règles, skill, baseline et checker cohérents ; le
  catalogue MCP a été conservé après détection du contrat applicatif.
- **Tests — PASS** : 18 scénarios ciblés, syntaxe Bash et checker worktree verts.
- **Build / Validation — N/A justifié** : aucun produit modifié ; YAML, SHA et
  liens changed-only remplacent honnêtement un build applicatif.
- **Critique finale — PASS après correction** : la première passe a trouvé trois
  écarts (sous-domaines non obligatoires, anciennes commandes `git add`, chiffres
  incohérents du rapport). Ils ont été corrigés, puis la revue indépendante a
  confirmé les 18 scénarios, les chemins déplacés et les chiffres 21/9+2.

## Lots de nettoyage recommandés, sans exécution automatique

### Priorité 1 — dette locale ignorée

Décider fichier par fichier du sort des 85 documents baselinés sous `docs/` :

- conserver et suivre les références encore actives ;
- déplacer les plans terminés vers une archive unique ;
- supprimer seulement après sauvegarde/migration, car Git ne peut pas les
  restaurer aujourd'hui.

Les 115 Markdown de `node_modules`, `.dart_tool`, `build` et `sprites-master`
sont régénérables. Leur suppression locale est à faible risque, mais elle doit
viser les répertoires générés complets au moment où aucun chantier ne les utilise.

### Priorité 2 — archive suivie

Traiter `reports/previous/` comme un lot séparé : 229 fichiers, 25,3 Mo. Avant
retrait du worktree, migrer les 14 références littérales prouvées depuis 3
rapports, produire un manifeste non Markdown si nécessaire, puis s'appuyer sur
l'historique Git ou une archive de release.

### Priorité 3 — preuves dupliquant les sources

Remplacer les 14 références vers `created_files_full_content` par les commits et
diffs canoniques, puis supprimer ces 14 fichiers (1,46 Mo). Les 23 appendices
Evidence associés (1,03 Mo) demandent la même analyse de référence.

### Priorité 4 — rapports dispersés

Migrer les 27 rapports historiques sous `packages/map_editor/reports/` vers
`reports/editor/`. Un scan littéral a trouvé une référence entrante seulement
pour l'un d'eux, mais l'absence de référence ne prouve pas l'absence d'usage.

## Limites, risques et auto-critique

- Le nombre total de Markdown augmente temporairement de un à cause de cet audit
  explicitement demandé ; la racine, elle, baisse de 16 à 5.
- Le checker ne détecte pas les doublons sémantiques ; seulement les chemins,
  noms, tailles, statuts Git et copies de déplacement exactes.
- La baseline protège les 85 ignorés existants mais peut devenir permanente si
  aucun lot de tri ne la réduit.
- La variable `POKEMAP_MARKDOWN_MAX_NEW` n'authentifie pas techniquement une
  décision humaine ; la règle agentique et la review restent nécessaires.
- Le seuil CI de 3 est un compromis. Il bloque les rafales, pas trois documents
  inutiles bien placés.
- La CI n'empêche un merge que si la protection de branche la rend obligatoire.
- Les références textuelles non cliquables vers les anciens noms de racine dans
  les rapports historiques n'ont pas été réécrites en masse : modifier des
  centaines de preuves historiques aurait créé plus de bruit que de valeur.
- L'audit SHA-256 ne prouve pas la similarité sémantique de deux rapports de
  contenus différents.
- Aucune suppression historique n'a été improvisée ; le principal gain immédiat
  est la racine propre et l'arrêt de la prolifération future.

## Prochaine décision recommandée

Ouvrir un lot séparé et borné sur les **85 fichiers `docs/` ignorés**, car ce
sont les seuls documents potentiellement uniques sans filet Git. Ensuite traiter
`reports/previous/` par archive/migration de références, puis les
`created_files_full_content`.
