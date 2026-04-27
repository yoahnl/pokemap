# Rapport Lot 15 - Extraction PSDK et matrice de portage moves/effects

## Resume executif

Le Lot 15 est termine. Deux extracteurs Dart purs ont ete ajoutes dans
`packages/map_battle/tool/` pour scanner les scripts Ruby Pokemon SDK:

- `extract_psdk_move_registry.dart` extrait les `Move.register(:method, ClassName)`.
- `extract_psdk_effect_matrix.dart` extrait les classes d'effets Ruby, leurs bases,
  familles, hooks `on_*`, chemins cibles Dart et statuts de portage.

Les matrices generees sont versionnees dans `reports/`:

- `reports/psdk-move-porting-matrix.md`
- `reports/psdk-effect-porting-matrix.md`

Le manifeste Dart interne est genere dans:

- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

## Scope confirme

Ce lot est une cartographie de migration. Il ne porte pas de comportement de combat.
Il ne remplace pas le moteur a lui seul. Il permet de dire clairement quels
`battleEngineMethod` PSDK sont portes, partiels ou manquants.

## Audit initial

Fichiers et contrats concernes:

- `packages/map_battle/pubspec.yaml`: aucune dependance externe ajoutee.
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`: source des
  comportements Dart connus.
- `pokemonsdk-development/scripts/5 Battle/10 Move`: source Ruby des registrations.
- `pokemonsdk-development/scripts/5 Battle/06 Effects`: source Ruby des effects.
- `reports/psdk-battle-engine-migration-worklots.md`: specification du Lot 15.

Risques identifies:

- Une extraction regex ne remplace pas un interpreteur Ruby.
- Des classes Ruby imbriquees peuvent attribuer des hooks au mauvais effet.
- Les conteneurs generiques `Ability`, `Item`, `Status`, `Weather`,
  `FieldTerrain` peuvent creer du bruit s'ils sont imbriques.
- Le manifeste ne doit pas pretendre que les comportements sont portes si le
  moteur ne les execute pas.

## Etat git initial

Le worktree etait deja fortement modifie par les lots precedents:

- nombreuses modifications non liees dans `packages/map_core` et `packages/map_editor`;
- nombreux fichiers non suivis des Lots 1 a 14 sous `packages/map_battle`;
- rapports precedents non suivis sous `reports/`.

Aucun reset, checkout ou nettoyage destructif n'a ete effectue.

## Fichiers crees ou modifies

### `packages/map_battle/tool/extract_psdk_move_registry.dart`

Zones ajoutees:

- parsing d'arguments: `<psdk-5-battle-dir> <output-md> [--manifest <output-dart>]`;
- scan recursif de `10 Move`;
- detection `Move.register(:method, ClassName)`;
- dedupe par `battleEngineMethod`;
- rendu Markdown;
- rendu manifeste Dart;
- table `_knownDartBehaviors`.

Impact:

- produit une matrice moves stable;
- garde `missing` par defaut pour eviter tout faux support.

### `packages/map_battle/tool/extract_psdk_effect_matrix.dart`

Zones ajoutees:

- scan recursif de `06 Effects`;
- parseur simple de blocs Ruby `class/def/end`;
- association des hooks a la classe qui les declare;
- filtrage des conteneurs generiques seulement quand ils sont imbriques;
- colonnes `Effect`, `Ruby base`, `Family`, `Hooks`, `Ruby path`,
  `Dart target`, `Status`, `Notes`.

Impact:

- evite les hooks attribues au fichier entier;
- garde les bases standalone visibles;
- marque seulement `Protect` comme `partial`.

### `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

Fichier genere par l'extracteur moves.

Etat apres Lot 15 seul:

- 316 methods;
- 0 `ported`;
- 3 `partial`;
- 313 `missing`.

Etat apres Lot 16, car le manifeste a ete regenere ensuite:

- 316 methods;
- 6 `ported`;
- 4 `partial`;
- 306 `missing`.

### `packages/map_battle/test/psdk_registry_manifest_test.dart`

Tests ajoutes:

- le manifeste expose les comportements Dart connus honnetement;
- pas de doublon `battleEngineMethod`;
- l'extracteur moves ecrit une matrice triee et un manifeste optionnel;
- l'extracteur effects ecrit hooks/famille/chemin cible;
- l'extracteur effects ignore les conteneurs generiques imbriques;
- il conserve les conteneurs generiques standalone;
- il assigne les hooks a la classe qui les definit.

### `reports/psdk-move-porting-matrix.md`

Artefact genere. Etat actuel apres Lot 16:

- total: 316;
- `ported`: 6;
- `partial`: 4;
- `missing`: 306.

### `reports/psdk-effect-porting-matrix.md`

Artefact genere:

- total: 482;
- `ported`: 0;
- `partial`: 1;
- `missing`: 481.

## Sub-agents et verdicts

- Audit / Architecture: scope confirme, aucun portage comportemental dans Lot 15,
  rester en `dart:io` sans dependance.
- Tests / Build: a detecte le risque d'attribution de hooks au fichier entier.
  Correction appliquee via parseur de blocs Ruby.
- Critique finale: a detecte le risque de filtrer `Status`, `Weather`,
  `FieldTerrain` seulement partiellement. Correction appliquee.
- Critique finale bis: a demande une non-regression inverse pour conserver les
  bases standalone. Test ajoute.

## Tests et resultats

Commandes lancees depuis `packages/map_battle`:

```bash
dart test test/psdk_registry_manifest_test.dart
```

Resultat final observe:

```text
00:01 +9: All tests passed!
```

Validation package complete relancee apres Lot 16:

```bash
dart test
```

Resultat final observe:

```text
00:02 +317: All tests passed!
```

Analyse:

```bash
dart analyze
```

Resultat:

```text
Analyzing map_battle...
No issues found!
```

Build alternatif des outils:

```bash
dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/pokemon_project_extract_psdk_move_registry
dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/pokemon_project_extract_psdk_effect_matrix
```

Resultats:

```text
Generated: /tmp/pokemon_project_extract_psdk_move_registry
Generated: /tmp/pokemon_project_extract_psdk_effect_matrix
```

Hygiene:

```bash
git diff --check
```

Resultat: aucune sortie.

## Limites conservees

- Extraction statique, pas interpretation Ruby.
- Les registrations dynamiques ou multi-lignes non conformes au motif peuvent
  necessiter une passe humaine.
- Les hooks herites ne sont pas expandus sur les classes enfants.
- La matrice est un outil de migration, pas une preuve de parite moteur.

## Auto-critique

Le lot est volontairement utilitaire. Les matrices doivent etre regenerees apres
chaque port de famille de moves/effects. Elles ne doivent jamais etre utilisees
comme unique source de verite comportementale sans tests Dart.

## Prochaines etapes proposees

- Continuer Lot 16 par familles de moves.
- Garder `s_multi_hit` partiel tant que Skill Link et les variantes complexes
  ne sont pas modelees.
- Ne pas demarrer hazards/weather/switch avant d'ajouter le state PSDK associe.
