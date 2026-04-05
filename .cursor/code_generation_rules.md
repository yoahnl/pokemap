# Génération de code — attentes pour ce dépôt

## Qualité

- Code **modulaire**, **lisible**, aligné sur le style du package touché.
- **Commentaires utiles** en tête de fichier et aux frontières non triviales : responsabilité, source de vérité, legacy, placeholder, contrat runtime.

## Ce qu’il faut toujours dire franchement

- **Placeholder** / **stub** / **MVP partiel** / **legacy** / **bridge** vers le runtime : le nommer dans le code et, si visible utilisateur, dans l’UI ou les advisories.
- **Compromis** : une phrase dans le rapport ou le commentaire du module.

## Rapports

- Passes structurantes ou refontes : **rapport markdown détaillé** dans `packages/map_editor/reports/` (nom explicite, date ou version dans le titre si utile).

## Interdits

- **Opérations Git d’écriture** (commit, push, rebase, etc.) sauf demande explicite du mainteneur.
- Fichiers **parasites** (`.vscode/` ajouté pour l’IA, tmp, dumps).
- Docs **creuses** : préférer peu de fichiers **denses** dans `.cursor/` et `reports/`.

## Tests

- Après refactor domaine : au minimum `flutter test` / `dart test` **ciblés** sur le package modifié.
- Ne pas exploser le scope test sans raison.

## Imports

- Préférer le **barrel** public (`cutscene_studio_authoring.dart`) pour l’UI et les tests **grand public** du module.
- Imports directs des sous-fichiers réservés aux **internes** du même dossier (`cutscene_studio/*.dart` entre eux).

## PokeMap / no-code

- Vocabulaire UI : voir `ui_ux_rules.md` et `project_vision.md`.
- Architecture : voir `clean_architecture_rules.md`.

## Si un fichier redevient trop gros

- **Découper** avant d’empiler des centaines de lignes supplémentaires ; mettre à jour `.cursor/clean_architecture_rules.md` ou le rapport si la structure change.
