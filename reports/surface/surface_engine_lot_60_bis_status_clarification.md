# Lot 60-bis — Evidence / Git Status Clarification Only

## Résumé exécutif

L’incohérence documentaire du Lot 60 tient au fait qu’un fichier non suivi, `?? packages/project_overview_pokemon_project.txt`, figurait au statut initial décrit par le Lot 60, qu’il n’apparaissait plus au statut final décrit, alors que le texte disait qu’il était resté « initial uniquement, non modifié par le Lot 60 ». L’audit actuel montre : le chemin `packages/project_overview_pokemon_project.txt` n’existe plus sur le disque dans le dépôt, n’est suivi par aucun index Git, n’apparaît dans aucun `find` par nom, et n’apparaît pas au `git status` actuel. Aucune preuve n’est disponible ici sur l’auteur, la date ou l’opération (suppression, déplacement hors dépôt, etc.) qui a fait disparaître un fichier jamais versionné. L’explication prudente : soit le fichier a été supprimé (ou retiré du répertoire) entre deux relevés de statut, soit le relevé de statut initial du Lot 60 ne reflétait plus l’arbre de travail au moment du final. Le code et les tests du Lot 60 ne sont pas remis en cause. Le Lot 60 peut être considéré comme fermable sur le plan documentaire dès lors que l’on accepte que la trace « ?? overview » n’est reproductible qu’au moment du premier snapshot, et qu’actuellement le fichier n’existe plus.

## Question à clarifier

Pourquoi `packages/project_overview_pokemon_project.txt` était présent dans le `git status` initial du Lot 60, mais absent du `git status` final du Lot 60 ?

## 1. Incohérence documentaire à clarifier (extrait issu des constats Lot 60)

- Le rapport du Lot 60 mentionnait au départ : `?? packages/project_overview_pokemon_project.txt`
- Un relevé de statut final du Lot 60 ne listait plus ce fichier
- Le même rapport disait par ailleurs que ce fichier restait en « initial uniquement », « non modifié par le Lot 60 »

En l’absence d’objet de ce nom dans l’arbre aujourd’hui, l’enchaînement « listé en untracked puis disparaît du `status` sans être devenu suivi ou ignoré de façon démontrable » appelle l’explication prudente ci-dessous.

## Périmètre

- Création de ce seul livrable : `reports/surface/surface_engine_lot_60_bis_status_clarification.md`
- Aucun fichier de code modifié, aucun test lancé, aucune commande Git d’écriture, aucun `build_runner`, rapport Lot 60 inchangé
- Vérification par commandes d’audit en lecture seule

## Commandes exécutées

Sorties exactes (répertoire de travail : racine du dépôt) :

```text
$ pwd
/Users/karim/Project/pokemonProject
```

```text
$ git branch --show-current
codex/psdk-fight-next-move-wave
```

```text
$ git log --oneline -n 5
19ef4032 feat(map_editor): Surface Studio sélection locale (Lot 58) et inspecteur (Lot 59)
68e0e552 feat(map_editor): Lot 57 — Surface Studio animation/preset detail views (read-only)
0dc3faff feat(map_editor): Lot 56 — Surface Studio atlas detail view (read-only)
de40ae6b move previous reports to the folder previous
439b5706 feat(map_editor): Lot 55 — Surface Studio diagnostics view (read-only)
```

Puis les commandes d’état (voir sections Git status et Audit).

## Git status initial frais

Commande exécutée : `git status --short --untracked-files=all`

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md
```

```text
$ git diff --stat
 .../surface_studio/surface_studio_panel.dart       |  7 ++
 .../surface_studio/surface_studio_panel_test.dart  | 76 ++++++++++++++++++----
 .../surface_studio_workspace_entry_test.dart       | 29 +++++++--
 3 files changed, 94 insertions(+), 18 deletions(-)
```

## Audit du fichier packages/project_overview_pokemon_project.txt

### test -e

Commande : `test -e packages/project_overview_pokemon_project.txt; echo "exists=?"`  
(Implémentation utilisée : `(test -e packages/project_overview_pokemon_project.txt && echo "existe" || echo "absent")`.)

```text
absent
```

Interprétation : le test `test -e` a échoué, donc le chemin n’existe pas sur le disque à cet emplacement.

### ls -la

Commande : `ls -la packages/project_overview_pokemon_project.txt 2>/dev/null || true`

Sortie : <vide>  
Commande attendue comme potentiellement non zéro, utilisée pour diagnostic (fichier absent, rien n’est imprimé sur stdout).

### stat

Commande : `stat packages/project_overview_pokemon_project.txt 2>/dev/null || true`

Sortie : <vide>  
Même remarque : diagnostic absence de fichier.

### git ls-files

Commande : `git ls-files -- packages/project_overview_pokemon_project.txt`

Sortie : <vide>  
Le fichier n’est pas suivi par l’index pour ce chemin.

### git check-ignore

Commande : `git check-ignore -v packages/project_overview_pokemon_project.txt 2>&1; echo "exit_check_ignore=?"`  
Sortie observée (premier essai) : stdout <vide>, code de sortie 1.

Nouveau passage pour documentation :

```text
$ git check-ignore -v packages/project_overview_pokemon_project.txt 2>&1; echo "exit_check_ignore=$?"

```

Sortie (stdout) : <vide>  
`exit_check_ignore=1`  
En l’absence de fichier et d’appariement d’une règle d’ignore affichable par Git, rien n’est listé. On ne conclut pas que le chemin serait « ignoré » au sens d’une règle active sur un fichier présent : le chemin cible n’existe pas.

### find chemin exact

Commande : `find . -path './packages/project_overview_pokemon_project.txt' -print`

Sortie : <vide>  
Aucun fichier à ce chemin exact sous la racine du dépôt.

### find par nom

Commande : `find . -name 'project_overview_pokemon_project.txt' -print`

Sortie : <vide>  
Aucune occurrence de ce nom de fichier ailleurs dans l’arbre (sous le dépôt) au moment de l’audit.

## État actuel réel (réponses directes)

- `packages/project_overview_pokemon_project.txt` **existe** : non (test d’existence : absent).
- **n’existe pas** (à ce chemin) : oui, correspond à la constatation du point précédent.
- **est suivi** : non (`git ls-files` vide).
- **est non suivi** : non, au sens où le chemin n’existe pas, donc Git ne l’indexe ni comme suivi ni comme non suivi au sens d’entrée de statut.
- **est ignoré** : le résultat de `check-ignore` ne montre pas de règle d’exclusion appliquée sur ce chemin ; en l’absence de fichier, la situation « ignoré sur disque » n’est pas établie.
- **est introuvable** : oui, au chemin et au nom attendus, à l’instant de l’audit.
- **existe ailleurs dans le dépôt** : non (`find` par nom sans résultat).
- **Rapport Lot 60 cohérent avec l’état actuel** : le seul conflit signalé (overview listé en initial puis disparaît du `status` final tout en étant qualifié de « non modifié par le Lot 60 ») reste un problème de **lecture** des preuves, pas de la dette de code. Le texte d’alors pouvait nommer l’overview comme bruit de fond sans que ce fichier n’existe aujourd’hui.

## Vérification des fichiers Lot 60

```text
$ test -e packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart; echo "atlas_prep_source_exists=$?"
atlas_prep_source_exists=0
```

```text
$ test -e packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart; echo "atlas_prep_test_exists=$?"
atlas_prep_test_exists=0
```

```text
$ test -e reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md; echo "lot60_report_exists=$?"
lot60_report_exists=0
```

## Vérification fichiers temporaires

Commande : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print`

Sortie : <vide>  
Aucun fichier de ce type trouvé (aucun laissé par le Lot 60-bis, aucun listé ici).

## Git status final

Commande : `git status --short --untracked-files=all` (relevé de fin d’audit, avant l’enregistrement de ce rapport sur le disque)

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md
```

```text
$ git diff --stat
 .../surface_studio/surface_studio_panel.dart       |  7 ++
 .../surface_studio/surface_studio_panel_test.dart  | 76 ++++++++++++++++++----
 .../surface_studio_workspace_entry_test.dart       | 29 +++++++--
 3 files changed, 94 insertions(+), 18 deletions(-)
```

Note pour le relevé de statut : un second `git status` exécuté **après** l’enregistrement de ce rapport sur le disque doit comporter en plus `?? reports/surface/surface_engine_lot_60_bis_status_clarification.md` (voir section « Git status après enregistrement du Lot 60-bis »).

## Analyse des hypothèses

| Hypothèse | Classement |
| --- | --- |
| Le fichier a été supprimé entre le statut initial et le statut final du Lot 60 | **Possible** (cohérent avec l’absence actuelle) ; **non prouvé** (pas d’horodatage, pas d’auteur) |
| Le fichier a été déplacé ailleurs dans le dépôt | **Exclu** (au moment de l’audit, `find . -name 'project_overview_pokemon_project.txt'` est vide) |
| Le fichier a été ajouté à `.gitignore` | **Non prouvé** ; pour un chemin qui n’existe plus, l’exclusion par ignore ne s’était pas montrée par `check-ignore` de façon utile ici. Aucun diff sur `.gitignore` n’a été requis par ce lot (lecture seule sur statut) |
| Artefact d’environnement injecté puis retiré | **Non prouvé** (aucune trace dans les commandes Git d’où le fichier serait venu) |
| Le rapport Lot 60 a recopié un statut initial obsolète | **Possible** (les deux relevés ne sont pas ici reproductibles dans un même enchaînement temporel) |
| Le statut final du Lot 60 était incomplet | **Non prouvé** (il peut avoir été juste ; la liste actuelle n’inclut simplement plus l’overview) |
| Le fichier existe encore mais est ignoré | **Exclu** pour l’emplacement `packages/...` : le fichier n’existe pas sur le disque (résultat du test d’existence : absent) |
| Le fichier existe ailleurs dans le dépôt | **Exclu** (find par nom : aucun résultat) |

## Impact sur le Lot 60

- **Code** : non remis en cause. Aucun livrable Lot 60 ne devait toucher un fichier d’aperçu de projet en `packages/`.
- **Tests** : non remis en cause. Le périmètre lot était `map_editor` et rapports, pas ce texte.
- **Périmètre fonctionnel** : le brouillon atlas, le panneau, les tests associés et la contrainte « pas de mutation manifeste » restent valides tels que décrits.
- **Correction de code** : **non** requise pour cette incohérence.
- **Correction documentaire** : **oui** pour la cohérence des preuves de statut ; c’est l’objet du présent Lot 60-bis. Le rapport historique `surface_engine_lot_60_*.md` n’est pas modifié par ce lot (interdit) ; le présent texte sert d’addendum explicatif.

## Recommandation

- **Fermer le Lot 60** : oui, du point de vue technique et de périmètre, dès que l’on accepte qu’un fichier jamais versionné, absent aujourd’hui, n’a pas d’implication sur le code livré.
- **Autre correctif** : inutile côté code. Optionnel côté process : lors des prochains lots, noter l’heure ou le hachage du `git status` si le contrat exige des preuves reproductibles.
- **Fichier `packages/project_overview_pokemon_project.txt`** : aujourd’hui absent du disque à ce chemin ; ce lot ne recommande ni suppression, ni recréation, ni déplacement (hors scope).
- **Passer au Lot 61** : possible une fois l’addendum 60-bis intégré à la clôture documentaire, sans conflit avec les livrables Lot 60.

## Fichiers créés

- `reports/surface/surface_engine_lot_60_bis_status_clarification.md`

## Fichiers modifiés

- Aucun

## Fichiers supprimés

- Aucun

## Périmètre explicitement non touché

- `packages/map_editor/**` (hors constat d’existence de chemins) : contenu de code **non** modifié
- `packages/map_core/**`, `packages/map_runtime/**`, `packages/map_gameplay/**`, `packages/map_battle/**` : **non** modifiés
- `reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md` : **non** modifié
- Aucun provider, repository, use case, build_runner, test automatisé lancé pour ce lot
- Aucune commande Git d’écriture

## Auto-review

- Est-ce que du code a été modifié ? **Non.** Aucun fichier de code `*.dart` ni autre ressource applicative n’a été édité.
- Est-ce que le Lot 60 a été modifié ? **Non.** Cible technique du Lot 60 (code + tests) inchangée.
- Est-ce que le rapport Lot 60 a été modifié ? **Non.** Fichier `surface_engine_lot_60_surface_studio_atlas_authoring_prep.md` intact.
- Est-ce qu’une commande Git d’écriture a été utilisée ? **Non.**
- Est-ce que `packages/project_overview_pokemon_project.txt` existe actuellement ? **Non** (résultat d’audit : sortie `absent` pour le test d’existence du chemin).
- Est-ce que son absence actuelle est expliquée par des preuves ? **Partiellement** : prouvé qu’il n’existe plus à ce chemin et n’apparaît nulle part sous ce nom ; **non prouvé** le geste (qui/quand) qui l’a retiré.
- Est-ce que l’incohérence du Lot 60 est résolue ? **Partiellement** : l’incohérence (initial vs final) se ramène à un fichier non suivi disparu de l’arbre, ce qui est compatible avec toute explication sans conserver de trace Git.
- Est-ce que le Lot 60 peut être fermé après ce 60-bis ? **Oui**, sous réserve de valider côté humain que l’addendum 60-bis satisfait l’exigence de clôture documentaire.

## Critique du prompt

- Il est **impossible de prouver avec certitude** pourquoi un fichier **jamais versionné** a cessé d’apparaître sur le disque si aucun journal d’audit shell ou historique de session n’est fourni. Ce lot fournit le meilleur diagnostic factuel : absence actuelle, absence de piste d’autre emplacement, statut des fichiers Lot 60 inchangé par la question. Exiger le diff *du fichier final* dans le fichier final sans récursion impose de documenter soit une **pré-version** du texte, soit le diff d’un fichier binaire de même contenu hors arbre, soit d’accepter une légère différence de hachage entre le diff affiché et le fichier intégral après assemblage.

## Distinction changements préexistants (Lot 60) et changement Lot 60-bis

- **Préexistant (hors 60-bis)** : trafic de travail issu du Lot 60 décrit ailleurs : fichiers `map_editor` modifiés, fichiers Surface Studio en `??`, rapport `surface_engine_lot_60_surface_studio_atlas_authoring_prep.md` en `??`. Aucun de ces éléments n’est modifié par le Lot 60-bis.
- **Changement Lot 60-bis** : seule **création** de `reports/surface/surface_engine_lot_60_bis_status_clarification.md` (ce document) ; aucun autre chemin du dépôt n’est modifié.

## Contenu intégral (Evidence Pack)

Le corps principal du livrable correspond au texte reproduit dans la sortie `git diff` ci-dessous (pré-version : jusqu’à la dernière ligne de la section « Critique du prompt » incluse, numéro de ligne indiqué pour la dernière régénération). Les sections `Distinction`, `Contenu intégral` et `Evidence Pack — Diff unifié` qui suivent dans le fichier final s’ajoutent après ce corps et ne font pas partie de ce diff.

## Evidence Pack — Diff unifié (git diff --no-index /dev/null, pré-version sans les sections postérieures à Critique)

Commande (pré-version : mêmes contenus que le présent fichier jusqu’à la fin de la dernière ligne de la section « Critique du prompt » incluse, 254 premières lignes au moment de la dernière régénération du diff) :

`head -n 254 reports/surface/surface_engine_lot_60_bis_status_clarification.md | git diff --no-index /dev/null -`

Sortie **exacte** (code de sortie 1, attendu quand le diff n’est pas vide) :

```diff
diff --git a/- b/-
new file mode 100644
--- /dev/null
+++ b/-
@@ -0,0 +1,254 @@
+# Lot 60-bis — Evidence / Git Status Clarification Only
+
+## Résumé exécutif
+
+L’incohérence documentaire du Lot 60 tient au fait qu’un fichier non suivi, `?? packages/project_overview_pokemon_project.txt`, figurait au statut initial décrit par le Lot 60, qu’il n’apparaissait plus au statut final décrit, alors que le texte disait qu’il était resté « initial uniquement, non modifié par le Lot 60 ». L’audit actuel montre : le chemin `packages/project_overview_pokemon_project.txt` n’existe plus sur le disque dans le dépôt, n’est suivi par aucun index Git, n’apparaît dans aucun `find` par nom, et n’apparaît pas au `git status` actuel. Aucune preuve n’est disponible ici sur l’auteur, la date ou l’opération (suppression, déplacement hors dépôt, etc.) qui a fait disparaître un fichier jamais versionné. L’explication prudente : soit le fichier a été supprimé (ou retiré du répertoire) entre deux relevés de statut, soit le relevé de statut initial du Lot 60 ne reflétait plus l’arbre de travail au moment du final. Le code et les tests du Lot 60 ne sont pas remis en cause. Le Lot 60 peut être considéré comme fermable sur le plan documentaire dès lors que l’on accepte que la trace « ?? overview » n’est reproductible qu’au moment du premier snapshot, et qu’actuellement le fichier n’existe plus.
+
+## Question à clarifier
+
+Pourquoi `packages/project_overview_pokemon_project.txt` était présent dans le `git status` initial du Lot 60, mais absent du `git status` final du Lot 60 ?
+
+## 1. Incohérence documentaire à clarifier (extrait issu des constats Lot 60)
+
+- Le rapport du Lot 60 mentionnait au départ : `?? packages/project_overview_pokemon_project.txt`
+- Un relevé de statut final du Lot 60 ne listait plus ce fichier
+- Le même rapport disait par ailleurs que ce fichier restait en « initial uniquement », « non modifié par le Lot 60 »
+
+En l’absence d’objet de ce nom dans l’arbre aujourd’hui, l’enchaînement « listé en untracked puis disparaît du `status` sans être devenu suivi ou ignoré de façon démontrable » appelle l’explication prudente ci-dessous.
+
+## Périmètre
+
+- Création de ce seul livrable : `reports/surface/surface_engine_lot_60_bis_status_clarification.md`
+- Aucun fichier de code modifié, aucun test lancé, aucune commande Git d’écriture, aucun `build_runner`, rapport Lot 60 inchangé
+- Vérification par commandes d’audit en lecture seule
+
+## Commandes exécutées
+
+Sorties exactes (répertoire de travail : racine du dépôt) :
+
+```text
+$ pwd
+/Users/karim/Project/pokemonProject
+```
+
+```text
+$ git branch --show-current
+codex/psdk-fight-next-move-wave
+```
+
+```text
+$ git log --oneline -n 5
+19ef4032 feat(map_editor): Surface Studio sélection locale (Lot 58) et inspecteur (Lot 59)
+68e0e552 feat(map_editor): Lot 57 — Surface Studio animation/preset detail views (read-only)
+0dc3faff feat(map_editor): Lot 56 — Surface Studio atlas detail view (read-only)
+de40ae6b move previous reports to the folder previous
+439b5706 feat(map_editor): Lot 55 — Surface Studio diagnostics view (read-only)
+```
+
+Puis les commandes d’état (voir sections Git status et Audit).
+
+## Git status initial frais
+
+Commande exécutée : `git status --short --untracked-files=all`
+
+```text
+ M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+ M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+ M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
+?? packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
+?? reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md
+```
+
+```text
+$ git diff --stat
+ .../surface_studio/surface_studio_panel.dart       |  7 ++
+ .../surface_studio/surface_studio_panel_test.dart  | 76 ++++++++++++++++++----
+ .../surface_studio_workspace_entry_test.dart       | 29 +++++++--
+ 3 files changed, 94 insertions(+), 18 deletions(-)
+```
+
+## Audit du fichier packages/project_overview_pokemon_project.txt
+
+### test -e
+
+Commande : `test -e packages/project_overview_pokemon_project.txt; echo "exists=?"`  
+(Implémentation utilisée : `(test -e packages/project_overview_pokemon_project.txt && echo "existe" || echo "absent")`.)
+
+```text
+absent
+```
+
+Interprétation : le test `test -e` a échoué, donc le chemin n’existe pas sur le disque à cet emplacement.
+
+### ls -la
+
+Commande : `ls -la packages/project_overview_pokemon_project.txt 2>/dev/null || true`
+
+Sortie : <vide>  
+Commande attendue comme potentiellement non zéro, utilisée pour diagnostic (fichier absent, rien n’est imprimé sur stdout).
+
+### stat
+
+Commande : `stat packages/project_overview_pokemon_project.txt 2>/dev/null || true`
+
+Sortie : <vide>  
+Même remarque : diagnostic absence de fichier.
+
+### git ls-files
+
+Commande : `git ls-files -- packages/project_overview_pokemon_project.txt`
+
+Sortie : <vide>  
+Le fichier n’est pas suivi par l’index pour ce chemin.
+
+### git check-ignore
+
+Commande : `git check-ignore -v packages/project_overview_pokemon_project.txt 2>&1; echo "exit_check_ignore=?"`  
+Sortie observée (premier essai) : stdout <vide>, code de sortie 1.
+
+Nouveau passage pour documentation :
+
+```text
+$ git check-ignore -v packages/project_overview_pokemon_project.txt 2>&1; echo "exit_check_ignore=$?"
+
+```
+
+Sortie (stdout) : <vide>  
+`exit_check_ignore=1`  
+En l’absence de fichier et d’appariement d’une règle d’ignore affichable par Git, rien n’est listé. On ne conclut pas que le chemin serait « ignoré » au sens d’une règle active sur un fichier présent : le chemin cible n’existe pas.
+
+### find chemin exact
+
+Commande : `find . -path './packages/project_overview_pokemon_project.txt' -print`
+
+Sortie : <vide>  
+Aucun fichier à ce chemin exact sous la racine du dépôt.
+
+### find par nom
+
+Commande : `find . -name 'project_overview_pokemon_project.txt' -print`
+
+Sortie : <vide>  
+Aucune occurrence de ce nom de fichier ailleurs dans l’arbre (sous le dépôt) au moment de l’audit.
+
+## État actuel réel (réponses directes)
+
+- `packages/project_overview_pokemon_project.txt` **existe** : non (test d’existence : absent).
+- **n’existe pas** (à ce chemin) : oui, correspond à la constatation du point précédent.
+- **est suivi** : non (`git ls-files` vide).
+- **est non suivi** : non, au sens où le chemin n’existe pas, donc Git ne l’indexe ni comme suivi ni comme non suivi au sens d’entrée de statut.
+- **est ignoré** : le résultat de `check-ignore` ne montre pas de règle d’exclusion appliquée sur ce chemin ; en l’absence de fichier, la situation « ignoré sur disque » n’est pas établie.
+- **est introuvable** : oui, au chemin et au nom attendus, à l’instant de l’audit.
+- **existe ailleurs dans le dépôt** : non (`find` par nom sans résultat).
+- **Rapport Lot 60 cohérent avec l’état actuel** : le seul conflit signalé (overview listé en initial puis disparaît du `status` final tout en étant qualifié de « non modifié par le Lot 60 ») reste un problème de **lecture** des preuves, pas de la dette de code. Le texte d’alors pouvait nommer l’overview comme bruit de fond sans que ce fichier n’existe aujourd’hui.
+
+## Vérification des fichiers Lot 60
+
+```text
+$ test -e packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart; echo "atlas_prep_source_exists=$?"
+atlas_prep_source_exists=0
+```
+
+```text
+$ test -e packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart; echo "atlas_prep_test_exists=$?"
+atlas_prep_test_exists=0
+```
+
+```text
+$ test -e reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md; echo "lot60_report_exists=$?"
+lot60_report_exists=0
+```
+
+## Vérification fichiers temporaires
+
+Commande : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print`
+
+Sortie : <vide>  
+Aucun fichier de ce type trouvé (aucun laissé par le Lot 60-bis, aucun listé ici).
+
+## Git status final
+
+Commande : `git status --short --untracked-files=all` (relevé de fin d’audit, avant l’enregistrement de ce rapport sur le disque)
+
+```text
+ M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+ M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+ M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
+?? packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
+?? reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md
+```
+
+```text
+$ git diff --stat
+ .../surface_studio/surface_studio_panel.dart       |  7 ++
+ .../surface_studio/surface_studio_panel_test.dart  | 76 ++++++++++++++++++----
+ .../surface_studio_workspace_entry_test.dart       | 29 +++++++--
+ 3 files changed, 94 insertions(+), 18 deletions(-)
+```
+
+Note pour le relevé de statut : un second `git status` exécuté **après** l’enregistrement de ce rapport sur le disque doit comporter en plus `?? reports/surface/surface_engine_lot_60_bis_status_clarification.md` (voir section « Git status après enregistrement du Lot 60-bis »).
+
+## Analyse des hypothèses
+
+| Hypothèse | Classement |
+| --- | --- |
+| Le fichier a été supprimé entre le statut initial et le statut final du Lot 60 | **Possible** (cohérent avec l’absence actuelle) ; **non prouvé** (pas d’horodatage, pas d’auteur) |
+| Le fichier a été déplacé ailleurs dans le dépôt | **Exclu** (au moment de l’audit, `find . -name 'project_overview_pokemon_project.txt'` est vide) |
+| Le fichier a été ajouté à `.gitignore` | **Non prouvé** ; pour un chemin qui n’existe plus, l’exclusion par ignore ne s’était pas montrée par `check-ignore` de façon utile ici. Aucun diff sur `.gitignore` n’a été requis par ce lot (lecture seule sur statut) |
+| Artefact d’environnement injecté puis retiré | **Non prouvé** (aucune trace dans les commandes Git d’où le fichier serait venu) |
+| Le rapport Lot 60 a recopié un statut initial obsolète | **Possible** (les deux relevés ne sont pas ici reproductibles dans un même enchaînement temporel) |
+| Le statut final du Lot 60 était incomplet | **Non prouvé** (il peut avoir été juste ; la liste actuelle n’inclut simplement plus l’overview) |
+| Le fichier existe encore mais est ignoré | **Exclu** pour l’emplacement `packages/...` : le fichier n’existe pas sur le disque (résultat du test d’existence : absent) |
+| Le fichier existe ailleurs dans le dépôt | **Exclu** (find par nom : aucun résultat) |
+
+## Impact sur le Lot 60
+
+- **Code** : non remis en cause. Aucun livrable Lot 60 ne devait toucher un fichier d’aperçu de projet en `packages/`.
+- **Tests** : non remis en cause. Le périmètre lot était `map_editor` et rapports, pas ce texte.
+- **Périmètre fonctionnel** : le brouillon atlas, le panneau, les tests associés et la contrainte « pas de mutation manifeste » restent valides tels que décrits.
+- **Correction de code** : **non** requise pour cette incohérence.
+- **Correction documentaire** : **oui** pour la cohérence des preuves de statut ; c’est l’objet du présent Lot 60-bis. Le rapport historique `surface_engine_lot_60_*.md` n’est pas modifié par ce lot (interdit) ; le présent texte sert d’addendum explicatif.
+
+## Recommandation
+
+- **Fermer le Lot 60** : oui, du point de vue technique et de périmètre, dès que l’on accepte qu’un fichier jamais versionné, absent aujourd’hui, n’a pas d’implication sur le code livré.
+- **Autre correctif** : inutile côté code. Optionnel côté process : lors des prochains lots, noter l’heure ou le hachage du `git status` si le contrat exige des preuves reproductibles.
+- **Fichier `packages/project_overview_pokemon_project.txt`** : aujourd’hui absent du disque à ce chemin ; ce lot ne recommande ni suppression, ni recréation, ni déplacement (hors scope).
+- **Passer au Lot 61** : possible une fois l’addendum 60-bis intégré à la clôture documentaire, sans conflit avec les livrables Lot 60.
+
+## Fichiers créés
+
+- `reports/surface/surface_engine_lot_60_bis_status_clarification.md`
+
+## Fichiers modifiés
+
+- Aucun
+
+## Fichiers supprimés
+
+- Aucun
+
+## Périmètre explicitement non touché
+
+- `packages/map_editor/**` (hors constat d’existence de chemins) : contenu de code **non** modifié
+- `packages/map_core/**`, `packages/map_runtime/**`, `packages/map_gameplay/**`, `packages/map_battle/**` : **non** modifiés
+- `reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md` : **non** modifié
+- Aucun provider, repository, use case, build_runner, test automatisé lancé pour ce lot
+- Aucune commande Git d’écriture
+
+## Auto-review
+
+- Est-ce que du code a été modifié ? **Non.** Aucun fichier de code `*.dart` ni autre ressource applicative n’a été édité.
+- Est-ce que le Lot 60 a été modifié ? **Non.** Cible technique du Lot 60 (code + tests) inchangée.
+- Est-ce que le rapport Lot 60 a été modifié ? **Non.** Fichier `surface_engine_lot_60_surface_studio_atlas_authoring_prep.md` intact.
+- Est-ce qu’une commande Git d’écriture a été utilisée ? **Non.**
+- Est-ce que `packages/project_overview_pokemon_project.txt` existe actuellement ? **Non** (résultat d’audit : sortie `absent` pour le test d’existence du chemin).
+- Est-ce que son absence actuelle est expliquée par des preuves ? **Partiellement** : prouvé qu’il n’existe plus à ce chemin et n’apparaît nulle part sous ce nom ; **non prouvé** le geste (qui/quand) qui l’a retiré.
+- Est-ce que l’incohérence du Lot 60 est résolue ? **Partiellement** : l’incohérence (initial vs final) se ramène à un fichier non suivi disparu de l’arbre, ce qui est compatible avec toute explication sans conserver de trace Git.
+- Est-ce que le Lot 60 peut être fermé après ce 60-bis ? **Oui**, sous réserve de valider côté humain que l’addendum 60-bis satisfait l’exigence de clôture documentaire.
+
+## Critique du prompt
+
+- Il est **impossible de prouver avec certitude** pourquoi un fichier **jamais versionné** a cessé d’apparaître sur le disque si aucun journal d’audit shell ou historique de session n’est fourni. Ce lot fournit le meilleur diagnostic factuel : absence actuelle, absence de piste d’autre emplacement, statut des fichiers Lot 60 inchangé par la question. Exiger le diff *du fichier final* dans le fichier final sans récursion impose de documenter soit une **pré-version** du texte, soit le diff d’un fichier binaire de même contenu hors arbre, soit d’accepter une légère différence de hachage entre le diff affiché et le fichier intégral après assemblage.
```

## Git status après enregistrement du rapport 60-bis (fichier `surface_engine_lot_60_bis_status_clarification.md` présent sur disque)

Commande : `git status --short --untracked-files=all`

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? reports/surface/surface_engine_lot_60_bis_status_clarification.md
?? reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md
```

Commande : `git diff --stat`

```text
 .../surface_studio/surface_studio_panel.dart       |  7 ++
 .../surface_studio/surface_studio_panel_test.dart  | 76 ++++++++++++++++++----
 .../surface_studio_workspace_entry_test.dart       | 29 +++++++--
 3 files changed, 94 insertions(+), 18 deletions(-)
```

## Confirmations (Evidence Pack, suite)

- Aucun fichier de code du dépôt n’a été modifié pour le Lot 60-bis. Seul le présent Markdown a été ajouté (création).
- Aucune commande Git d’écriture n’a été exécutée (aucun `add`, `commit`, `reset`, `checkout`, etc.).
- Aucun fichier temporaire `_gen_*.py`, `build_*.py` ou `*.tmp` n’a été laissé dans le dépôt par le Lot 60-bis. La vérification `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print` a donné une sortie vide.
- Vérification mojibake (ainsi qu’on peut la faire à vue sur le texte rédigé) : pas de `RÃ`, `Ã©`, `â€`, `Â` dans le corps de ce document.
- Le rapport `reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md` n’a pas été modifié. Il apparaît en `??` comme travail en cours (Lot 60), distinct du `??` pour le présent fichier 60-bis.
