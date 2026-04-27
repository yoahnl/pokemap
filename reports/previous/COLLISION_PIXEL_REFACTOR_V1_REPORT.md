# Rapport — refonte collision pixel-level (addendum V1)

Document honnête sur l’état de la refonte **après** la série d’implémentations décrite dans la conversation (verrous : APIs explicites grille vs pixel, pas de moteur sur `cells`, déplacement joueur en pixels, ordre map_core → editor → gameplay → runtime).

---

## 1. État initial (constat)

- Les APIs `isBlocked` / `movementBlockReasonAt` mélangeaient sémantiques (grille, eau, décor) sans distinction explicite dans le nom.
- Le fichier `packages/map_core/lib/src/collision/pixel_rect.dart` était **référencé** par `map_core.dart` et par `player_collision_conventions_v1.dart` mais **absent du disque** : la compilation échouait jusqu’à sa création.
- `GameplayWorldState.withEntityPosition` / `withNpcMapPresencePredicate` mettaient à jour `blockingEntityByPos` mais **pas** `_pixelCollisionCache`, alors que `isCellCenterBlockedLegacyForGridIndexedSystems` ne lisait que le bitmap pixel : les déplacements PNJ / présence **ne reflétaient pas** la collision après déplacement.
- Les tests utilisaient encore `cells`-only sur les profils d’éléments : le moteur actif **ignore** `cells` pour le bitmap (conformément au verrou) → collisions « disparues » tant que les fixtures n’avaient pas de `pixelMask`.
- Les tests qui faisaient `copyWith(pos: …)` sans resynchroniser `playerPositionPx` **cassaient** l’invariant déplacement pixel (comportement incohérent avec `MoveIntent`).

---

## 2. Décisions d’architecture (figées dans le code)

| Sujet | Décision |
|--------|----------|
| Vérité collision statique | Bitmap monde `_pixelCollisionCache` (union tuiles collision carte + masques `pixelMask` des éléments + empreintes entités bloquantes en tuiles pleines). **Pas** de lecture de `cells` dans ce pipeline. |
| Joueur | `playerPositionPx` (coin haut-gauche sprite) + hitbox 12×8 via `PlayerCollisionConventionsV1` ; résolution `PixelMovementResolverV1.resolveSeparateAxis`. |
| Grille legacy | `isCellCenterBlockedLegacyForGridIndexedSystems` : échantillon au **centre** de la case sur le bitmap (pour LoS, pathfinding grossier, etc.). |
| Eau / surf + essai « grille » | `movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial` (nom explicite : pieds **cellule** + mode). |
| Manifeste projet | Champ interne `_projectManifest` pour **reconstruire** `_pixelCollisionCache` quand les entités bloquantes changent. |

---

## 3. Conventions produit (rappel)

- `playerPositionPx` : coin haut-gauche du sprite monde.
- Hitbox : 12×8 px, centrée horizontalement, bas du rectangle = bas du sprite.
- Projection pieds → grille : centre du bord inférieur de la hitbox, puis `floor(x / tileWidth)`, etc. (**uniquement** warps / triggers / interactions).

---

## 4. Fichiers créés

| Fichier | Rôle |
|---------|------|
| `packages/map_core/lib/src/collision/pixel_rect.dart` | `PixelPosition`, `PixelRect`, `PixelPoint`, getter `bottomCenterPx` (ancre pieds documentée). |
| `reports/COLLISION_PIXEL_REFACTOR_V1_REPORT.md` | Ce rapport. |

---

## 5. Fichiers modifiés (principaux)

- `packages/map_gameplay/lib/src/gameplay_world_state.dart` : `_projectManifest`, rebuild du cache pixel dans `withNpcMapPresencePredicate` et `withEntityPosition`, suppression import inutilisé, suppression classe interne morte `_PixelRect`.
- `packages/map_gameplay/lib/src/gameplay_step.dart` : warp / comportements sur la position joueur **après** mouvement (coordonnées cohérentes).
- `packages/map_gameplay/lib/src/los_detection.dart` : `isCellCenterBlockedLegacyForGridIndexedSystems` au lieu de l’ancienne API.
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` : remplacement des anciens appels par `movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial` / logique équivalente pour chemins, warps, connections, PNJ.
- `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart` : même API grille/eau explicite.
- Nombreux tests `packages/map_gameplay/test/*.dart` et `packages/map_runtime/test/*.dart` : noms d’API + **fixtures avec `pixelMask`** là où le gameplay le requiert + `GameplayPlayerState.fromGridSpawn` pour les états intermédiaires volontaires.

*(Les fichiers map_core / map_editor antérieurs à ce fil — conventions, validateurs, éditeur — restent tels que décrits dans le résumé de conversation ; non redétaillés ici pour éviter doublon.)*

---

## 6. Fichiers supprimés

- Aucune suppression dans **cette** passe de travail (des suppressions éditeur peuvent exister dans l’historique global du projet).

---

## 7. Legacy retiré ou gelé

- **Retiré du moteur actif** : toute collision placée fondée sur `cells` **sans** `pixelMask` (les éléments concernés ne génèrent plus de solides dans le bitmap).
- **JSON / migration** : `cells` peut subsister pour outillage ou migration ; le validateur strict map_core peut exiger `pixelMask` si `cells` non vide (politique déjà en place côté modèle).
- **API** : `isBlocked` / `movementBlockReasonAt` ne sont plus les noms publics pour ce périmètre (remplacés par les noms ci-dessus).

---

## 8. Risques

- **Assets sans `pixelMask`** : collision gameplay **absente** pour ces éléments jusqu’à migration explicite (rupture voulue, pas de fallback silencieux sur `cells`).
- **`_projectManifest == null`** : rebuild du cache après déplacement d’entité **ne** peut pas réencoder les masques d’éléments (même limite qu’à la construction initiale sans manifeste).
- **Cohérence état joueur** : tout `copyWith` sur `pos` sans recalcul de `playerPositionPx` **casse** le modèle ; les tests doivent utiliser `fromGridSpawn` ou une API dédiée.
- **« Pixel-perfect »** : le moteur est **pixel-based** pour le joueur (séparation d’axes, bitmap), mais ce n’est **pas** une garantie physique complète (pas de glissement diagonal avancé, pas de correction continue hors de ce résolveur). Ne pas vendre « tout est pixel-perfect » au sens rendu/physique AAA.

---

## 9. Limites restantes

- Pathfinding / PNJ : beaucoup de chemins utilisent encore des **cellules** et `movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial` (grille + eau), pas une résolution sweep complète du joueur — cohérent avec « systèmes encore en grille ».
- Entités bloquantes : empreinte **pleine tuile** par case du footprint (approximation documentée dans le builder du cache).

---

## 10. Stratégie de migration

1. Pour chaque élément avec `cells` : générer / coller un `pixelMask` (outil éditeur ou script) ; laisser `cells` vide ou réservé au debug.
2. Revalider les cartes avec validation stricte map_core.
3. Vérifier en jeu : warps/triggers sur la projection pieds, pas sur le seul coin sprite.

---

## 11. Tests exécutés et résultats

| Commande | Résultat |
|----------|----------|
| `dart test` dans `packages/map_gameplay` | **86 tests passés** |
| `flutter test` dans `packages/map_runtime` | **succès** (sortie agrégée ; pas d’échec signalé) |

`dart analyze` : avertissements préexistants dans map_core (annotations JsonSerializable, etc.) ; map_gameplay après correctif : plus d’import inutilisé sur `gameplay_world_state.dart`.

---

## 12. Checklist QA manuelle (suggestions)

- [ ] Déplacement cardinal : le joueur s’arrête contre les bords de masque (pas « téléportation » case par case).
- [ ] Warp / trigger : déclenchés selon la **cellule des pieds** après déplacement.
- [ ] Eau : surf / blocage alignés sur les caches eau + bitmap.
- [ ] PNJ qui se déplace : la zone bloquante suit la nouvelle position (présence + `withEntityPosition`).
- [ ] Carte avec éléments **sans** masque : constater absence de blocage **ou** rejet en validation selon pipeline (comportement attendu post-rupture).

---

## 13. Review bundle (fichiers à relire en priorité)

1. `packages/map_core/lib/src/collision/pixel_rect.dart`
2. `packages/map_core/lib/src/collision/player_collision_conventions_v1.dart`
3. `packages/map_gameplay/lib/src/gameplay_world_state.dart` (builder bitmap, rebuilds)
4. `packages/map_gameplay/lib/src/gameplay_step.dart`
5. `packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart`
6. `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` (sections warps / connections / pathfinding)
7. `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart`

---

*Aucune opération Git effectuée dans le cadre de cette tâche (conforme à la contrainte utilisateur).*
