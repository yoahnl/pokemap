# Design QA — Inspecteur compact des calques World Map
Date : 2026-08-02
Résultat final : `passed`
## Périmètre
Référence fournie :
- `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/TemporaryItems/NSIRD_screencaptureui_VoyssL/Screenshot 2026-08-02 at 14.28.38.png`
- dimensions : 573 × 941 px
- état : thème sombre, inspecteur `Calques`, premier calque de tuiles actif, opacité à 100 %
Implémentation vérifiée :
- application Flutter macOS en mode debug, viewport 1920 × 1080 px
- capture complète : `/tmp/pokemap-layer-qa-implementation-full.png`
- recadrage de l'inspecteur : `/tmp/pokemap-layer-qa-implementation-panel.png`, 540 × 920 px
- projet de test jetable dérivé de `le_train_de_17h42`
## Audit initial
La référence affichait des cartes d'environ 165 px de haut, sans type de calque explicite et sans repère chromatique continu. L'opacité, la visibilité, l'édition, la suppression et le réordonnancement étaient disponibles, mais la densité obligeait à faire défiler fréquemment et les calques se distinguaient surtout par leur nom et leur icône.
Objectifs retenus :
- conserver toutes les actions existantes et le réglage d'opacité ;
- afficher le type en clair, sans dépendre uniquement de la couleur ;
- ajouter un liseré fin issu des tons sémantiques du design system ;
- ramener la hauteur nominale d'une carte sous 120 px ;
- préserver un rendu utilisable lorsque l'inspecteur devient étroit.
## Fichiers concernés par ce lot
- `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_guided_slider.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_guided_slider_test.dart`
- `design-qa.md`
## Zones modifiées
- `PokeMapPanel` : nouveau liseré directionnel optionnel, piloté par `PokeMapTone`, largeur par défaut de 3 px.
- `PokeMapGuidedSlider` : nouveau mode `inline` réutilisant les mêmes comportements de focus, clavier et transaction.
- `WorldMapLayersInspector` : nom, type, actions, opacité et réordonnancement recomposés en deux lignes ; variante adaptative en trois lignes sous 300 px de largeur utile.
- Typologie visuelle : tuiles, collision, terrain, chemin, forêt, objets, environnement, bordures et surfaces utilisent chacun un libellé explicite et un ton sémantique.
## Comparaison visuelle
### Typographie et copie
- Les styles du design system sont conservés.
- Le type est maintenant écrit dans chaque carte (`Tuiles`, `Terrain`, `Chemin`, `Forêt`, `Collision`, etc.).
- Le libellé accessible inclut également `Type …`, de sorte que la couleur n'est jamais l'unique information.
### Espacement et densité
- Hauteur observée d'une carte standard : 102 px, contre environ 165 px dans la référence.
- Sept calques sont visibles dans le viewport de validation sans perte des commandes essentielles.
- La hiérarchie reste : identité et actions, puis opacité et ordre.
### Couleurs
- Liseré bleu pour les tuiles, vert pour les terrains, jaune pour les chemins, rouge pour les collisions, avec les autres types mappés sur les tons sémantiques existants.
- Aucune couleur produit brute n'a été ajoutée ; les valeurs proviennent des tokens du design system.
### Images et assets
- Sans objet : ce composant ne contient pas d'image de référence ni d'asset décoratif.
## Interactions vérifiées
- ouverture de `Chambre de la pension d'Hanazuki` ;
- ouverture de l'inspecteur `Calques` ;
- sélection d'un calque ;
- glissement réel de l'opacité de 100 % à 66 % ;
- présence et accessibilité des actions de visibilité, édition, suppression et réordonnancement ;
- projet source vérifié avant et après : empreinte inchangée `618a90e826b1abbbe20c61bbdb8ba89f2e97f2da`.
## Historique des passes
1. **Audit** — la carte a été identifiée comme trop haute et insuffisamment explicite ; verdict : changement nécessaire.
2. **Implémentation** — composition compacte, liseré sémantique et type textuel ajoutés ; verdict : conforme au design system.
3. **Tests** — un test de shell a révélé un dépassement horizontal de 31 px dans une largeur réduite ; verdict : correctif requis.
4. **Correctif responsive** — passage automatique à trois lignes sous 300 px ; test isolé et suite ciblée verts ; verdict : résolu.
5. **Build et validation réelle** — build macOS réussi, interactions réelles et capture post-correctif vérifiées ; aucun `RenderFlex` ni exception observé dans le terminal Flutter ; verdict : validé.
6. **Auto-critique** — le gain de densité est net sans masquer les actions. Le risque restant est uniquement une traduction future des noms de types si le produit abandonne les libellés français actuels ; aucune dette fonctionnelle bloquante identifiée.
## Preuves automatisées
- `flutter test test/ui/design_system/pokemap_card_panel_test.dart test/ui/design_system/pokemap_guided_slider_test.dart test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart test/ui/shell/pokemap_inspector_shell_migration_test.dart` — 41 tests réussis.
- `flutter test test/ui/shell/pokemap_inspector_shell_migration_test.dart --plain-name 'adaptive layers inspector renders localized rows and actions'` — 1 test réussi après le correctif responsive.
- `flutter analyze` — aucune anomalie (`No issues found!`, 6,9 s) après le correctif responsive.
- `npm test` dans `tools/pokemap_mcp` — build TypeScript réussi et 25/25 tests MCP réussis.
- `pokemap_describe` sur le serveur actif — `ok: true`; catalogue présent avec commandes, ressources, requêtes, actions, validation et manifeste de parité.
- Une seconde suite complète a été lancée avec `--concurrency=24`. Elle a atteint 2 891 réussites et 5 tests ignorés, mais n'est pas verte : 49 échecs étaient présents avant interruption, principalement des délais de 30 s sous forte concurrence et des tests hors périmètre liés aux autres modifications déjà présentes dans le worktree (par exemple la palette Terrain et l'Event Builder). Les erreurs de fermeture provoquées ensuite par `Ctrl-C` sont exclues de ce bilan. La suite ciblée du lot a été rejouée après cette interruption et reste verte à 41/41.
## Parité PokeMap MCP
Sans objet sur le plan sémantique pour ce lot : la modification est strictement présentationnelle. Elle ne change ni les données projet, ni les commandes d'authoring, ni la sérialisation, ni le rendu de carte, ni le playtest. Les contrats `map_authoring` restent donc inchangés. Le serveur MCP a néanmoins été reconstruit et testé à 25/25, puis son catalogue actif a été relu avec succès.
