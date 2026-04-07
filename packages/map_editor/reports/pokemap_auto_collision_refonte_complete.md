# PokeMap — refonte du sous-système d’auto-génération des collisions

## Résumé exécutif

L’ancienne logique vivait dans un **fichier monolithique** (`element_collision_profile_generator.dart`, ~400 lignes) mélangeant décodage image, heuristiques par preset, et post-traitements peu documentés. Le comportement était **difficile à prédire** (seuils magiques, bandes « bottom » sans lien clair avec la géométrie du sprite) et **fragile** pour un outil no-code.

La refonte introduit un **pipeline explicite** sous `lib/src/application/collision_generation/` :

1. **Politique par preset** (`CollisionPresetPolicy`) — paramètres nommés et documentés.
2. **Résolution du padding** (`collision_padding_resolver.dart`) — priorité à l’utilisateur, sinon ratios dérivés.
3. **Analyse raster** (`CollisionRasterAnalyzer`) — densité opaque par cellule avec **bande basse du sprite** + **empreinte basse par cellule**.
4. **Raffinement de forme** (`CollisionShapeRefinement`) — seuillage, bande basse grille, centrage, **composante connexe au sol** (pour arbres / décors).

Le point d’entrée runtime reste **`ElementCollisionProfileGenerator`** (façade), qui délègue à **`PlacedElementAutoCollisionGenerator`**. Le modèle persisté **`ElementCollisionProfile`** (cellules + padding) est **inchangé** : l’édition manuelle case par case reste le dernier mot.

---

## Diagnostic de l’ancien système

### Emplacement

- `packages/map_editor/lib/src/application/services/element_collision_profile_generator.dart` (historique)
- Appelé depuis `EditorNotifier.generateElementCollisionProfile` et l’UI `tileset_palette_panel.dart` (« Générer automatiquement la collision »).

### Fonctionnement (avant)

1. Lecture fichier tileset → `ui.Image` → buffer RGBA.
2. Pour chaque cellule de la grille de l’élément : comptage des pixels opaques (seuil alpha fixe 110) dans un rectangle rogné par `WarpTriggerPadding`.
3. Couverture = opaques / pixels échantillonnés ; seuil minimum variable par preset.
4. Post-traitements ad hoc : `_clipBottomBand`, `_clipBottomAndCenter` avec ratios différents par preset.
5. Fallback si aucune cellule : assouplissement du seuil (×0.6).

### Pourquoi c’était « bancal »

| Problème | Effet produit |
|----------|----------------|
| Pas de **zone d’analyse verticale** claire sur le sprite entier | Le haut des bâtiments / feuillage contribuait encore trop à la densité, ou l’inverse selon les assets. |
| Échantillonnage sur **toute la hauteur de chaque cellule** | Sprites hauts dans une case généraient des collisions « pleine hauteur » peu Pokémon-like. |
| Responsabilités fusionnées | Impossible de tester l’algo sans I/O fichier ; difficile d’ajuster un seul maillon. |
| Heuristiques implicites | Ratios (`bottomRatio`, `maxWidthRatio`) non reliés à des concepts produit nommés. |

### Ce qui a été conservé

- **Sortie** : `ElementCollisionProfile` avec `cells`, `padding`, `source: generated`.
- **Contrat UI** : mêmes paramètres (`presetKind`, `padding` utilisateur optionnel).
- **Édition manuelle** inchangée côté données.

### Ce qui a été remplacé

- L’implémentation interne du générateur (logique déplacée dans `collision_generation/`).

---

## Design du nouveau système

### Séparation des préoccupations (produit / roadmap)

| Notion | Statut dans cette refonte |
|--------|---------------------------|
| **A. Collision de déplacement** | **Implémentée** : liste de `GridPos` dans `ElementCollisionProfile`, consommée par `map_gameplay` (`_buildCollisionCache`). |
| **B. Recouvrement visuel (profondeur)** | **Hors périmètre** : le tri / calques runtime restent dans le moteur de rendu ; ce document évite de mélanger les concepts. |
| **C. Interaction / proximité PNJ** | **Hors périmètre** : porté par entités et règles gameplay, pas par la grille de collision décor. |

Le pipeline d’auto-génération ne fait **que** proposer une approximation de **A**, sans écrire de données pour B ou C.

### Structures principales

- **`CollisionPresetPolicy`**  
  Champs explicites : `alphaThreshold`, `minimumCoverage`, `focusBottomFraction`, `cellFootprintFraction`, ratios de padding horizontal, `bottomBandRowRatio`, `maxCenterWidthRatio`, `forceSingleColumnWhenNarrow`, `applyConnectivityToBottomRow`.

- **`CollisionRasterAnalyzer.computeCoverage`**  
  Retourne une liste `coverage[y * w + x]` ∈ [0,1].

- **`CollisionShapeRefinement.buildCells`**  
  Produit la liste finale de `GridPos`.

- **`PlacedElementAutoCollisionGenerator.generate`**  
  Orchestre I/O + appels ci-dessus.

### Algorithme (détail)

1. **Décodage** de l’image source (inchangé techniquement).
2. **Padding** : si l’utilisateur a défini un côté > 0, on garde sa valeur ; sinon on applique les ratios de la politique (équivalent à l’ancien comportement « auto »).
3. **Bande « gameplay » verticale** : on ne compte les pixels opaques que pour `y >= srcTop + ceil((1 - focusBottomFraction) * srcHeight)` — concentre l’analyse sur le **bas du sprite** (socle / tronc).
4. **Empreinte par cellule** : dans chaque cellule, on ignore le haut de la case sur une fraction `cellFootprintFraction` (bas de case = « pieds »).
5. **Densité** : pour chaque cellule, `densité = pixels_opaques / pixels_échantillonnés` (pas de règle « un pixel = collision »).
6. **Seuillage** avec `minimumCoverage` ; relâchement unique si vide (comme avant, borne [0.05, 0.22]).
7. **Raffinement** :
   - si `maxCenterWidthRatio >= 0.999` : uniquement bande basse de **lignes de grille** ;
   - sinon : bande basse + limitation du nombre de colonnes centrées (arbres, rochers).
8. **Composante au sol** (si `applyConnectivityToBottomRow`) : on ne garde que les cellules reliées en 4-voisinage à au moins une cellule sur la **dernière ligne** du masque — réduit les artefacts « feuillage » déconnecté du sol dans le graphe des cellules sélectionnées.
9. **Tri / déduplication** des cellules.

### Compromis assumés

- Les valeurs numériques sont **calibrées** pour un style Pokémon-like ; des assets très exotiques peuvent nécessiter une retouche manuelle (objectif produit : assistance, pas perfection aveugle).
- La profondeur visuelle **n’est pas** inférée ici (évite de sur-promettre sur un seul canal « collision »).

---

## Fichiers ajoutés ou modifiés

### Nouveaux

| Fichier | Rôle |
|---------|------|
| `lib/src/application/collision_generation/collision_preset_policy.dart` | Politiques par `ElementPresetKind`. |
| `lib/src/application/collision_generation/collision_padding_resolver.dart` | Fusion padding utilisateur / défaut. |
| `lib/src/application/collision_generation/collision_raster_analyzer.dart` | Densité par cellule. |
| `lib/src/application/collision_generation/collision_shape_refinement.dart` | Seuillage + forme + connectivité. |
| `lib/src/application/collision_generation/placed_element_auto_collision_generator.dart` | Orchestration + I/O. |
| `test/collision_generation/*.dart` | Tests unitaires. |
| `reports/pokemap_auto_collision_refonte_complete.md` | Ce rapport. |

### Modifiés

| Fichier | Changement |
|---------|------------|
| `lib/src/application/services/element_collision_profile_generator.dart` | Façade mince vers `PlacedElementAutoCollisionGenerator`. |

### Non modifiés (volontairement)

- UI `tileset_palette_panel.dart` — même API.
- `EditorNotifier` — même appel.
- `ElementCollisionProfile` / persistance JSON — inchangés.

---

## Tests ajoutés

Exécution : `flutter test test/collision_generation/` depuis `packages/map_editor`.

- **Raster** : transparence totale ; moitié opaque ; exclusion du haut du sprite (preset arbre).
- **Forme** : grille 3×2 pleine + arbre (bande basse + largeur) ; grille 2×2 + arbre (uniquement ligne basse).
- **Padding** : respect du padding utilisateur ; dérivation si vide.

---

## Limites restantes / prochaines étapes possibles

1. **Calibrage par projet** : exposer dans l’UI des curseurs liés aux champs de `CollisionPresetPolicy` (sans exposer le code).
2. **Assets multi-fenêtres / animations** : la génération utilise la frame décodée du fichier ; pas d’analyse frame-par-frame.
3. **Profondeur / occlusion** : si besoin produit, ajouter un second masque ou des métadonnées dédiées (ne pas surcharger `ElementCollisionProfile`).
4. **Tests visuels golden** : images PNG de référence dans le repo pour régression fine.

---

## Vérification manuelle recommandée

1. Ouvrir un élément décor (arbre, bâtiment) dans la palette tileset.
2. Cliquer « Générer automatiquement la collision » avec différents presets.
3. Vérifier la preview des cellules puis **peindre / effacer** manuellement quelques cases.
4. Jouer en runtime : le joueur ne doit plus se comporter de façon absurde sur les bords testés.

---

*Document généré pour la refonte auto-collision PokeMap — pas de commit Git associé à ce fichier dans le cadre de la tâche.*
