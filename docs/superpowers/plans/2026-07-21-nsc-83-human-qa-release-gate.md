# NSC-83 — QA humaine, documentation et release gate

Date : 2026-07-21

Branche : `main`

## Contrat du lot

Clore la phase 8 avec un parcours réel des binaires macOS, une matrice de
validation complète, une documentation reproductible et un verdict honnête
sur la gate Narrative Studio v1. Ce lot n'autorise pas à déclarer terminé le
MVP mécanique global `FG-185`.

## Audit initial

- [x] Vérifier que NSC-80, NSC-81 et NSC-82 sont commités et que le dépôt est
  propre au commit `d7d3a2604`.
- [x] Lire la roadmap Narrative Studio, la roadmap mécanique et
  `codex_rule.md`.
- [x] Identifier les parcours desktop, les tests d'accessibilité, les tests de
  panne et la matrice de validation obligatoire.
- [x] Utiliser une copie jetable de `selbrume/` pour toute mutation humaine.

## Parcours humain réel

- [x] Ouvrir le binaire macOS de `map_editor` sur la copie Selbrume.
- [x] Inspecter Overview, Event Builder, un Event sélectionné et Validator.
- [x] Modifier le nom du joueur via Nouveau jeu, sauvegarder, fermer et
  relancer ; vérifier la persistance sur disque.
- [x] Lancer le binaire macOS du runtime host, charger Selbrume, sauvegarder et
  recharger la position `(17,24)` sur `map_bourg_selbrume`.
- [x] Capturer les états avant/après, validation, compactage et runtime.
- [x] Vérifier que le projet canonique source conserve son SHA-256.

## Accessibilité et résilience

- [x] Exécuter clavier, semantics, 200 % de texte, reduced motion, contraste et
  localisation.
- [x] Exécuter les matrices responsive, dont `1280x768` et `800x650`.
- [x] Injecter asset absent, écriture refusée, référence stale et commande
  runtime non supportée.
- [x] Corriger la sérialisation des géométries typées du snapshot Validator.
- [x] Corriger les overflows réels du shell et de Facts/World Rules.
- [x] Rebaser uniquement les goldens correspondant aux changements visuels
  intentionnels, puis les rejouer sans `--update-goldens`.

## Gate technique

- [x] `map_core` : tests et analyze.
- [x] `map_gameplay` : tests et analyze.
- [x] `map_battle` : tests et analyze.
- [x] `map_runtime` : tests et analyze.
- [x] `map_editor` : tests, analyze et build macOS debug.
- [x] `playable_runtime_host` : tests, analyze et build macOS debug.
- [x] Smoke tests Phase A runtime et host.
- [x] `git diff --check`.

## Documentation et verdicts

- [x] Écrire la checklist humaine reproductible.
- [x] Écrire le guide utilisateur Narrative Studio.
- [x] Actualiser la matrice de capacités.
- [x] Produire les passes manuelles nommées Audit/Architecture,
  Implémentation, Tests, Build/Validation et Critique finale.
- [x] Documenter les limites sans transformer la gate narrative en GO global
  du MVP.

## Verdict

`GO — Narrative Studio v1 / Selbrume`, sous réserve des limites explicites du
Evidence Pack. Aucun P0/P1 ni divergence editor/runtime n'est connu sur les
chemins de la matrice promue.
