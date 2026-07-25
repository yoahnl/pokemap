# PokeMap Hub Phase 3 — Installer et bibliothèque

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Installer, maintenir et recenser plusieurs jeux `.pokemapgame` sans
qu’un échec, une annulation ou un crash ne détruise la version active ni les
sauvegardes.

**Architecture:** `apps/pokemap_hub` reste la racine de composition et possède
les chemins, le registre, les journaux de transaction et l’orchestration.
`map_distribution` fournit l’inspection hostile, les manifests, les receipts et
la politique de release. Les validations smoke et migrations de saves passent
par des ports injectés afin de préserver le sens des dépendances de Phase 0.

**Tech Stack:** Dart, `dart:io`, `map_distribution`, `map_core`, `archive`,
`crypto`, `path`, `package:test`.

---

## Inventaire des fichiers

- `apps/pokemap_hub/lib/src/library/game_library.dart` : snapshots publics du
  registre et des versions installées.
- `apps/pokemap_hub/lib/src/library/game_library_codec.dart` : codec JSON strict
  et canonique.
- `apps/pokemap_hub/lib/src/library/game_library_store.dart` : persistance
  atomique, backup et reconstruction contrôlée.
- `apps/pokemap_hub/lib/src/install/game_installation_diagnostic.dart` :
  diagnostics sûrs, progression et annulation.
- `apps/pokemap_hub/lib/src/install/game_installation_ports.dart` : espace
  disque, smoke runtime et préparation/restauration de saves.
- `apps/pokemap_hub/lib/src/install/file_package_source.dart` : snapshot
  random-access borné d’un fichier sélectionné.
- `apps/pokemap_hub/lib/src/install/installed_game_verifier.dart` : vérification
  manifest/receipt/inventaire d’une version immuable.
- `apps/pokemap_hub/lib/src/install/game_package_installer.dart` : fresh install,
  update, staging, extraction, promotion et recovery.
- `apps/pokemap_hub/lib/src/install/game_maintenance_service.dart` : rollback,
  repair et uninstall conservant les saves.
- `apps/pokemap_hub/test/library/` et `test/install/` : preuves des lots
  `HUB-030…034`, dont subprocess kill-tests.

## HUB-030 — Registre `GameLibrary`

**Objectif :** lister les jeux et toutes leurs versions installées à partir
d’un registre validé, récupérable et indépendant des titres.

**Périmètre :**

- schéma versionné `library.json`, révision monotone, `gameId` stable ;
- version courante identifiée par version + tree hash ;
- métadonnées joueur issues du manifest courant ;
- liste immuable des versions/receipts et état de santé ;
- écriture `tmp → flush → backup → rename → relecture` ;
- reconstruction depuis versions et receipts après corruption.

**Tests :**

- round-trip canonique et rejet des champs inconnus/doublons ;
- deux jeux au même titre mais IDs distincts ;
- corruption du courant avec backup valide ;
- reconstruction sans inventer de version non couverte par un receipt.

**DONE :** une lecture expose uniquement des entrées cohérentes avec des
receipts et une corruption du cache `library.json` ne supprime aucune version.

## HUB-031 — Installer staging/promotion atomique

**Objectif :** installer une archive inspectée dans une version immuable sans
modifier la version active avant tous les gates.

**Périmètre :**

- première inspection read-only puis snapshot local rehashé pour fermer le
  TOCTOU ;
- espace requis `max(512 MiB, archiveBytes * 5 / 2)` ;
- staging imprévisible sur le même volume ;
- extraction STORE-only par chunks avec confinement et annulation ;
- relecture taille/hash de chaque fichier, validation projet Phase 1 et smoke
  injecté ;
- receipt canonique, promotion de version, `current.json`, puis library ;
- journal persistant et recovery idempotent.

**Tests :**

- fresh install, package incompatible, espace insuffisant et release conflict ;
- annulation mi-extraction sans version visible ;
- échec smoke laissant le courant intact ;
- kill avant promotion et après déplacement de version avant `current.json`.

**DONE :** après toute frontière injectée, recovery retrouve soit l’ancienne
version courante, soit la nouvelle version complète couverte par son receipt.

## HUB-032 — Update côte à côte et rollback

**Objectif :** activer une version supérieure seulement après préparation des
saves et permettre un retour explicite vers un receipt antérieur.

**Périmètre :**

- politique `GamePackageReleasePolicy` pour update/rollback ;
- ancienne version conservée ;
- port de préparation/migration des saves avant activation ;
- rollback exigeant confirmation et snapshot save compatible ;
- journalisation du pointeur courant et reconstruction library.

**Tests :**

- update supérieure activée côte à côte ;
- version égale/tree différent rejetée ;
- migration save en échec laissant ancienne version courante ;
- rollback refusé sans confirmation/snapshot puis accepté avec restauration.

**DONE :** `current.json` ne pointe jamais une update non validée et rollback
restaure version + snapshots via le port avant de publier l’état final.

## HUB-033 — Repair et uninstall

**Objectif :** détecter/réparer une version altérée et désinstaller sans toucher
aux sauvegardes par défaut.

**Périmètre :**

- verifier installé : manifest canonique, receipt, fichiers exacts, tailles,
  hashes et tree hash ;
- repair uniquement depuis un package de même identité/version/tree ;
- remplacement journalisé avec ancienne copie récupérable ;
- uninstall transactionnel d’une version ou d’un jeu ;
- fallback courant explicite si plusieurs versions ;
- aucune suppression sous `saves/<gameId>`.

**Tests :**

- altération détectée puis réparée ;
- mauvaise source de repair refusée ;
- uninstall courant avec fallback et uninstall total ;
- mêmes saves octet-pour-octet avant/après.

**DONE :** repair rend la version saine contre son receipt et uninstall ne
mutile ni autre jeu ni saves.

## HUB-034 — Progression, annulation, stockage et diagnostics

**Objectif :** rendre chaque opération longue observable, bornée et
diagnostiquable sans exposer de donnée sensible.

**Périmètre :**

- étapes typées inspection, espace, staging, extraction, validation, smoke,
  promotion, library et recovery ;
- compteurs fichiers/octets monotones ;
- annulation autorisée avant promotion, refusée après frontière critique ;
- verrou de mutation interprocess ;
- codes diagnostics stables et contexte limité à gameId/version/stage ;
- nettoyage/recovery des transactions abandonnées.

**Tests :**

- séquence et monotonie de progression ;
- double mutation sérialisée/refusée ;
- diagnostic sans chemin source ni contenu secret ;
- recovery idempotent.

**DONE :** aucune opération longue n’est opaque et toute erreur retourne une
étape, un code stable, une possibilité de retry/repair et un état courant
préservé.

## Vérification finale

```bash
cd apps/pokemap_hub
dart format --output=none --set-exit-if-changed lib test
dart test
dart analyze

cd packages/map_distribution
dart test
dart analyze

git diff --check
git status --short --untracked-files=all
```

Le commit final ne contient que les fichiers de Phase 3. Les 73 fichiers non
suivis préexistants restent hors index. Aucun push n’est autorisé par cette
mission.
