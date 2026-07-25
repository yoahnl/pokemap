# PokeMap Hub Phase 2 — Saves et lifecycle multijeux

**Date :** 2026-07-25

**Lots :** `HUB-020`, `HUB-021`, `HUB-022`, `HUB-023`, `HUB-024`

**Source de vérité :** contrats Phase 0 et audit produit du 2026-07-24

## Découpage architectural

- `map_core` possède `GameIdentity`, `SaveEnvelope`, leur codec, le checksum,
  l’évaluation de compatibilité et les contrats de migration. Il reste pur Dart
  et ne connaît aucun chemin.
- `apps/pokemap_hub` possède les chemins, profils/slots, locks, écritures
  atomiques, backups, récupération, snapshots de migration et orchestration du
  lifecycle.
- `map_runtime` continue de produire/consommer l’état métier. Son repository
  historique reste disponible au host développeur et n’est pas promu comme
  stockage officiel du Hub.

## HUB-020 — Identité et enveloppe

**Objectif :** fournir des contrats versionnés qui lient sans ambiguïté une
sauvegarde à un jeu, un profil et un slot.

**Périmètre :**

- identité stable du jeu et adresse game/profile/slot ;
- enveloppe v1, origin, statut active/completed et checksum SHA-256 sur JSON
  canonique sans `checksum` ;
- validation stricte des IDs, versions, timestamps UTC, bornes et invariants ;
- diagnostic de compatibilité : accept, migration requise ou rejet.

**Fichiers :** nouveaux contrats sous `packages/map_core/lib/src/save/`, export
dans `map_core.dart`, tests sous `packages/map_core/test/save/`.

**Tests :** fixture Phase 0, round-trip, checksum, champ inconnu, IDs dangereux,
ordre temporel, completedAt, mauvais jeu/compatibilityId, format futur et
migration disponible/absente.

**DONE :** la fixture canonique Phase 0 est acceptée et toute enveloppe exposée
est validée contre l’identité attendue et son checksum.

**Risques :** divergence entre schéma JSON et code ; mutation indirecte de
`state` ; confusion entre version d’enveloppe et format métier.

**Dépendances :** contrats Phase 0 `HUB-003`, aucune dépendance Flutter.

## HUB-021 — Repository scoppé

**Objectif :** empêcher toute lecture ou écriture interjeu.

**Périmètre :**

- racine `PokeMap/saves/<gameId>/<profileId>/<slotId>/` ;
- validation avant composition et confinement des chemins ;
- profils à ID stable et nom d’affichage séparé ;
- inspection/listing des slots, Continuer par date et suppression explicite
  d’un slot.

**Fichiers :** infrastructure privée sous
`apps/pokemap_hub/lib/src/saves/`, tests sous `apps/pokemap_hub/test/saves/`.

**Tests :** deux jeux avec mêmes profile/slot, traversal, symlink, sélection du
slot compatible le plus récent et conservation hors scope.

**DONE :** deux jeux ne peuvent ni se lire ni s’écraser et aucun chemin résolu
ne sort de la racine saves.

**Risques :** différences de casse/filesystem et liens créés hors processus.

**Dépendances :** `HUB-020`.

## HUB-022 — Atomicité, backup et récupération

**Objectif :** ne jamais perdre la dernière save valide.

**Périmètre :**

- verrou exclusif par slot ;
- temporaire même répertoire, flush, relecture/validation, rotation du backup,
  promotion atomique et confirmation ;
- lecture primary puis backup, quarantaine récupérable des corruptions ;
- récupération des artefacts laissés par une interruption.

**Tests :** corruption primary + backup valide, écritures concurrentes,
injection d’échec et arrêt de processus aux étapes sensibles.

**DONE :** après chaque interruption simulée ou réelle, une lecture retrouve
l’ancienne ou la nouvelle enveloppe complète ; aucune temporaire invalide n’est
promue.

**Risques :** sémantique de rename/fsync par OS ; advisory locks.

**Dépendances :** `HUB-020`, `HUB-021`.

## HUB-023 — Migrations et rollback

**Objectif :** migrer sur une copie et préserver un retour à la version
précédente.

**Périmètre :**

- chaîne explicite N→N+1 sans script package ;
- nouveau `saveId`, conservation de `createdAt`, progression de `updatedAt` ;
- snapshot pré-migration lié à la version source ;
- promotion seulement après validation de la cible ;
- restauration explicite du snapshot lors d’un rollback.
- import de la save globale historique après preview, confirmation et sélection
  explicite game/profile/slot, sans modifier le fichier source.

**Tests :** chaîne réussie, étape manquante, exception de migration, état source
non muté, checksum cible, restauration du snapshot et import legacy par copie.

**DONE :** un échec laisse le courant et son backup inchangés ; un succès garde
un snapshot valide de la version précédente.

**Risques :** migrations non déterministes et compatibilité déclarée à tort.

**Dépendances :** `HUB-020..022`.

## HUB-024 — Lifecycle et checkpoint

**Objectif :** suspendre/reprendre/quitter sans rendre la dernière save invalide.

**Périmètre :**

- suspension input/horloges avant capture ;
- checkpoint borné et persistance si valide ;
- reprise après revalidation de session/version ;
- sortie au titre/Hub après commit ou abandon explicite ;
- sérialisation/coalescence des transitions concurrentes.

**Tests :** succès, timeout capture/persistance, erreur, double background,
foreground incompatible et sortie avec/sans abandon.

**DONE :** toutes les branches accusent réception avec un résultat typé et un
timeout conserve une save antérieure valide.

**Risques :** délai OS réellement disponible et opérations non annulables.

**Dépendances :** `HUB-022`; le branchement à `AppLifecycleState` viendra avec
le shell applicatif sans modifier ce contrat.

## Vérification et commit

```bash
cd packages/map_core && dart format --output=none --set-exit-if-changed lib test
cd packages/map_core && dart test test/save
cd packages/map_core && dart analyze
cd apps/pokemap_hub && dart format --output=none --set-exit-if-changed lib test
cd apps/pokemap_hub && dart test
cd apps/pokemap_hub && dart analyze
git diff --check
git status --short --untracked-files=all
```

Le commit final ne doit contenir que les fichiers Phase 2. Aucun fichier non
suivi préexistant n’est ajouté.
