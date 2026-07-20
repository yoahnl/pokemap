# Falaises Selbrume à deux étages — sources V2

Ce dossier contient les 24 pierres individuelles 32×32 utilisées par
`ts_selbrume_cliff_two_tier_v2`. Elles sont des sources éditables et non des
blocs de falaise déjà assemblés.

## Organisation

- `top_<n|e|s|w>_<01|02|03>.png` : lèvre supérieure, courte et plutôt claire ;
- `face_<n|e|s|w>_<01|02|03>.png` : face verticale, longue et plutôt sombre ;
- chaque PNG contient exactement un composant opaque 4-connexe ;
- alpha binaire, palette fermée de huit couleurs et canevas 32×32 ;
- les orientations sont dessinées pour le monde et ne sont pas des rotations
  automatiques d'une unique pierre.

L'atlas runtime correspondant est
`assets/tilesets/falaises_selbrume_deux_etages_v2.png`. L'ordre est documenté
dans `assets/ATLAS_LAYOUTS.json`; les anchors, bounds, hashes et ratios de tons
sont consignés dans
`assets/provenance/selbrume_two_tier_cliff_v2.json`.

## Reproduction

La planche ImageGen V4 retenue et les itérations rejetées sont conservées dans
le paquet QA du Bureau. Depuis `packages/map_editor` :

```bash
dart run tool/build_selbrume_two_tier_cliff_pack.dart \
  --sheet <raw-two-tier-sheet-v4.png> \
  --project-root ../../selbrume \
  --output-atlas assets/tilesets/falaises_selbrume_deux_etages_v2.png \
  --provenance assets/provenance/selbrume_two_tier_cliff_v2.json \
  --chroma '#FF00FF' \
  --chroma-tolerance 48
```

Le builder segmente 24 composants, quantifie la palette, normalise la balance
de tons propre à chaque étage, applique les bounds et anchors cardinaux puis
reconstruit l'atlas de manière déterministe. Il échoue avant toute écriture si
la planche est ambiguë, coupée ou contient un fragment détaché.
Quand les snapshots de publication existent déjà, le builder reconnaît
uniquement les copies `borders/snapshots/<sha256>/frame_0000.png` dont les
octets correspondent à l'une des 24 sources et régénère leur provenance
dérivée approuvée. Un rebuild conserve donc ces 24 entrées sans modifier les
octets des snapshots.

Ces sprites sont purement visuels : `visual_only_no_collision`.
