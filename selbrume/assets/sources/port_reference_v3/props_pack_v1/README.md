# Port des Brisants — pack de props v1

Ce dossier contient uniquement des props autonomes destinés au Port des
Brisants. Le pack ne place rien sur la map et ne porte aucune donnée de
collision.

## Props publiés

| Fichier | Emprise | Origine |
|---|---:|---|
| `barrel_plain.png` | 1 × 2 | tonneau source v2 existant |
| `barrel_pair.png` | 2 × 2 | composition de tonneaux source v2 |
| `cargo_crates_closed.png` | 2 × 2 | caisses portuaires source v2 |
| `rope_coil_plain.png` | 2 × 2 | cordage du tileset portuaire existant |
| `green_netted_barrel.png` | 2 × 2 | création ciblée depuis les références du Port |
| `ground_net_rope_heap.png` | 3 × 2 | création ciblée depuis les références du Port |
| `fishing_gear_bucket.png` | 2 × 2 | création ciblée depuis les références du Port |
| `fish_notice_board.png` | 2 × 2 | création ciblée depuis les références du Port |
| `barrel_planter.png` | 1 × 2 | création ciblée depuis les références du Port |

`port_props_pack_contact_sheet.png` réunit les neuf sprites sur une grille de
prévisualisation.

## Sources

- Référence de map fournie par le propriétaire : `Photo 1.jpg`.
- Famille visuelle existante : `small_harbor_props_alpha.png`.
- Donneurs existants : `13_baril_haut.png`, `03_caisses_port.png` et
  `selbrume_port_props.png`.
- Planche des cinq nouveaux props : `generated_missing_props_chroma.png`,
  générée avec l'outil ImageGen intégré sur fond chroma `#ff00ff`.
- Source détourée : `generated_missing_props_alpha.png`, produite avec le
  helper officiel `remove_chroma_key.py`.

Les sprites finaux sont normalisés sur la grille native de 32 px, ancrés en bas
au centre et redimensionnés en nearest-neighbor par le builder props-only.
