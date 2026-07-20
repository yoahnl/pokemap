# Selbrume stone-chain V1 — sources

Ce dossier contient les 16 pierres individuelles du kit
`ts_selbrume_cliff_stone_chain_v1`. Le résolveur Border Studio les assemble
sur les arêtes de la grille ; aucune source n'est un segment de falaise déjà
monté.

## Inventaire et ordre de l'atlas

L'ordre est row-major dans une grille 4×4 de cellules 32×32 :

1. `primary_01.png` à `primary_05.png` : pierres principales ;
2. `secondary_01.png` à `secondary_04.png` : pierres de seconde strate ;
3. `filler_01.png` à `filler_03.png` : petits cailloux facultatifs ;
4. `corner_01.png` et `corner_02.png` : pierres d'angle ;
5. `cap_01.png` et `cap_02.png` : terminaisons.

Chaque source est un PNG RGBA 32×32 à alpha binaire, avec une ancre
bottom-center `(16,29)`. La collision est intentionnellement
`visual_only_no_collision`. Le blueprint Selbrume publié conserve les fillers
dans le kit récupérable mais leur donne un poids nul : les tests sur Bourg de
Selbrume ont montré que cette troisième famille minuscule brouillait la face
rocheuse au lieu de la renforcer.

## Création et transformations finales

- Génération finale : un appel built-in `imagegen` le 2026-07-17, sous forme
  d'une planche originale 4×4 sur chroma `#FF00FF`.
- Références visuelles seulement : `assets/tilesets/cliff.png` et
  `assets/tilesets/objectif.png`. Elles n'ont été ni découpées, ni copiées, ni
  intégrées comme underlay.
- SHA-256 de la sortie imagegen brute finale :
  `a2da7f3b3ace55006033102d8f9cbf82d7b015a31381fbc82100512a4461c528`.
- Détourage : seuil RGB déterministe du chroma, puis alpha binaire.
- Normalisation : découpe row-major, réduction nearest-neighbour vers les
  footprints par catégorie, ancrage bottom-center et quantification vers huit
  couleurs pierre.
- SHA-256 de l'atlas final :
  `357d8a242d688102a0d1cc6f8d1aa54cc5e76f15a21b60cf3692003a21169119`.

La planche initiale 4×4 et la correction coins/caps 2×2 restent consignées
dans le manifeste comme provenance historique, mais elles sont entièrement
supplantées par la génération finale ci-dessus. Les 16 hashes source et les
footprints finaux se trouvent dans
`assets/provenance/selbrume_stone_chain_v1.json`.

La palette opaque autorisée est : `#302d28`, `#3e3a33`, `#4d483e`, `#5b5548`,
`#6c6554`, `#7e7660`, `#91886d`, `#a69c7b`. Elle exclut volontairement herbe,
mousse, sable, eau et écume.

## Reproduction

Depuis `packages/map_editor` :

```bash
flutter test test/selbrume_stone_chain_pack_builder_test.dart
dart run tool/build_selbrume_stone_chain_pack.dart \
  --project-root ../../selbrume \
  --refresh-project-metrics
```

La planche brute finale peut être réappliquée explicitement avec :

```bash
dart run tool/build_selbrume_stone_chain_pack.dart \
  --project-root ../../selbrume \
  --replacement-sheet <planche-brute-4x4.png> \
  --refresh-project-metrics
```

Sans `--replacement-sheet`, le builder ne modifie aucune source et reconstruit
seulement l'atlas et son manifeste. La QA couvre publication, déterminisme,
lignes horizontale et verticale, deux L, deux S, boucle fermée, inversion de
côté et rotation automatique. L'acceptation artistique de la carte reste un
gate humain distinct des tests et des hashes ; aucun aperçu de QA n'est
persisté dans `map_bourg_selbrume.json` avant ce gate.

## Licence

`license status: unverified`. La licence des références et la permission de
redistribution publique ne sont pas documentées ; ce statut ne constitue pas
une autorisation de publication.
