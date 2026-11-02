# Référentiel Pokémon autonome — plan de réalisation

> Pour les agents : appliquer le workflow `skills/executing-plans/SKILL.md` par lots, avec les deux conversations déjà en cours. Avant d’écrire dans un fichier partagé, vérifier son propriétaire et coordonner les commits.

**Objectif :** disposer d’un catalogue Pokémon et objets autonome, hébergé chez Yoahn, puis prouver que Studio et un jeu exporté utilisent effectivement ses données, sons et animations.

**Architecture :** l’API NestJS et PostgreSQL publient des versions immuables ; les médias sont stockés sur le volume local du serveur. L’import Avelune récupère les ressources depuis une version précise, puis les embarque dans le projet et l’export ; Player ne dépend pas du réseau pour jouer.

**Technologies :** TypeScript/NestJS, PostgreSQL, Dokploy/TrueNAS, Dart/Flutter/Flame ; AnimaEngine C et les sources BW2 indiquées par Yoahn pour le pilote de sprites par pièces.

**Cadre du POC :** à la demande de Yoahn, les questions de licences et de diffusion sur les stores seront traitées lors de la préparation d’une éventuelle publication ; elles ne bloquent pas l’exploration technique ni l’intégration du prototype. Les 74 modèles explicitement réservés au brouillon restent privés.

---

## Début : état vérifié le 2 novembre 2026

| Élément | État établi | Limite |
|---|---|---|
| API | `https://pokemon-api.yoahn.me`, conteneurs API et PostgreSQL en bonne santé ; API `72f6d9e` | La sécurité globale et la couverture ne sont pas certifiées. |
| Version publique | `public-2026-11` publiée comme **partielle** : 1 025 Pokémon, 2 223 objets et 937 attaques | Une version publiée est figée ; les compléments demanderont une nouvelle version. |
| Sources BW2 | 649 fiches de ressources de combat Pokémon et 559 scripts d’attaques disponibles | Les 649 fiches couvrent les formes par défaut uniquement. Une seule fiche `move-animation` est présente ; ni cette fiche ni les scripts ne prouvent que l’animation est jouable. |
| Sons et images | 605 nouveaux sons importés en plus du pilote Lance-Flammes ; 2 687 portraits disponibles dans la version de novembre | Associations son/attaque déduites des noms ; synchronisation et couverture réelles à prouver. |
| Ressources manquantes | L’audit relève 135 257 références sans correspondance locale sur 196 244 examinées | Ce sont des occurrences, pas 135 257 fichiers distincts ; plusieurs exemples existent à la source, dont HGSS. |
| Privé | 74 modèles 3D spéciaux restent dans le brouillon ; aucun de leurs fichiers n’est référencé par la nouvelle publication | Leur publication n’a pas été autorisée. Les autres médias restent soumis aux décisions déjà prises par Yoahn. |
| Stockage et sauvegarde | Volume de 20 Gio, environ 17 Gio libres au dernier contrôle ; sauvegarde post-publication `scheduled-20261101T203927Z` vérifiée au niveau de l’archive | Cette sauvegarde précise n’a pas été restaurée ; une sauvegarde précédente a été restaurée et testée isolément. L’état du pool de disques durs reste hors de cette preuve. |
| Avelune | Défaut de catalogue `public-2026-11` commité dans `53d7f7b64` ; transport Studio testé en direct sur Bulbizarre, Ponchiot et un portrait Pikachu | Une version de Studio incluant ce commit doit encore être livrée ; l’import complet de ressources et le jeu réel ne sont pas prouvés. |
| Animations | Le pilote de particules groupées et ses replis ont des tests ; AnimaEngine compose un aperçu de Ponchiot | Ni le raccordement réel de l’attaque au Player ni un lecteur articulé fidèle et intégré ne sont terminés. |

## Organisation et ordre

- **Tom / référentiel :** inventaire, API, import des données et médias, administration, sécurité, sauvegardes et publication.
- **Conversation attaques :** moteur d’effets et de caméra BW2, son, intégration Player et validation d’un combat réel.
- **Conversation sprites :** lecteur par pièces, comparaisons à la référence et raccordement Player quand la fidélité le permet.
- Les lots 1 et 2 peuvent avancer pendant les lots 3 et 4. Le lot 5 dépend de ressources et de capacités prouvées ; les contrôles du lot 6 commencent dès maintenant et sont rejoués au lot 7.
- Chaque lot finit par un résultat vérifiable, un point de reprise, la mise à jour du ticket Notion existant et, conformément à l’autorisation de Yoahn, un commit ciblé si du code a changé. Une conversation sans tâche utile attend ; elle ne fabrique pas de travail.

## Les huit lots

### 0 — Figer le périmètre et mesurer ce qui existe

**Responsable :** Tom, avec les deux conversations. **État :** commencé.

- [ ] Épingler les révisions des sources effectivement utilisées et produire, pour chaque famille, le nombre d’entrées attendues, disponibles, absentes à la source, importées et vérifiées. Distinguer les références répétées des fichiers uniques.
- [ ] Mesurer la taille des ressources réellement présentes avant import massif ; identifier les formats et les 17 Gio disponibles sur le volume. Ne pas modifier le réseau de Mochi ni intervenir sur ses disques défectueux comme raccourci.
- [ ] Conserver les contrats et données existants ; enregistrer les manques et les causes plutôt que présenter une copie partielle comme complète.

**Fini quand :** un inventaire reproductible donne les dénominateurs par source et par famille, et permet d’ordonner les imports sans hypothèse de taille.

### 1 — Compléter les données du catalogue

**Responsable :** Tom. **Dépendance :** lot 0.

- [ ] Compléter Pokémon, formes, capacités, types, évolutions, objets et attaques à partir des sources épinglées ; conserver identifiants, relations et variantes, sans écraser les modifications d’administration.
- [ ] Importer les noms et descriptions d’attaques disponibles dans chaque langue et chaque version pertinente. Si une description doit être inventée, conserver son origine IA et l’étoile demandée par Yoahn ; ne jamais la faire passer pour une règle de combat vérifiée.
- [ ] Lier les données d’objets, images et effets au registre réellement implémenté par Avelune ; distinguer un effet documenté d’un effet effectivement exécutable.
- [ ] Tester imports reprenables, cohérence des relations, édition privée et lecture d’une version publiée.

**Fini quand :** chaque entrée attendue par les inventaires épinglés est traitée, les absences de source sont identifiées et les données demandées sont interrogeables avec leur provenance.

### 2 — Compléter les médias et leur disponibilité

**Responsable :** Tom. **Dépendance :** lot 0 ; peut avancer avec le lot 1.

- [ ] Importer par lots vérifiés et reprenables : sprites GBA, GIF de combat Noir et Blanc face/dos et variantes, sprites overworld pour les Pokémon suiveurs, icônes de menus, cris, sons généraux, images d’objets et modèles 3D disponibles.
- [ ] Pour le suivi 2D, enregistrer directions, grille, animations et ancrage lorsqu’ils sont connus. Pour les modèles 3D, conserver maillage, textures, squelette et animations disponibles ; distinguer un sprite 2D dressé dans une scène 3D d’un véritable modèle 3D.
- [ ] Si une forme alternative n’a pas son propre sprite, utiliser celui de la forme de base ; ne pas bloquer le POC pour compléter ces variantes.
- [ ] Prioriser les ressources nécessaires au pilote HGSS et à Noir et Blanc ; poursuivre ensuite les autres références réellement présentes dans les sources. Les fichiers WebP existent à la source mais le schéma média courant accepte PNG/GIF : choisir et tester une prise en charge qui conserve transparence et animation lorsque nécessaire.
- [ ] Pour chaque média, conserver source, révision, empreinte, variante et statut de disponibilité ; vérifier les octets stockés et les liens locaux. Ne pas inventer une ressource officielle absente et ne pas exposer les 74 modèles réservés au privé.
- [ ] Si la taille dépasse l’espace vérifié, présenter un besoin chiffré et une solution de stockage concrète avant de changer l’infrastructure.

**Fini quand :** les ressources prioritaires sont importées et servies, les absences sont connues et les formes alternatives sans sprite dédié utilisent le repli prévu.

### 3 — Jouer les attaques BW2

**Responsable :** conversation attaques. **Dépendance :** API et contrats médias des lots 1 et 2.

- [ ] Finir le pilote Lance-Flammes : composant SPL réel, ancrage aux combattants, son joué une fois, caméra, libération des ressources et repli sûr avant ou après audio.
- [ ] Importer la recette et les médias qu’elle déclare depuis l’API — neuf dans la fixture actuelle —, vérifier leurs empreintes, exporter puis jouer hors réseau ; comparer visuel, orientation, rythme et son au jeu de référence. Les tests à audio simulé ne suffisent pas.
- [ ] Généraliser le lecteur à partir des comportements réellement rencontrés, puis importer les ressources et dépendances des 559 scripts BW2 ; distinguer absent à la source, disponible mais non importé, comportement non pris en charge et attaque effectivement jouable. Un MP3 associé par son nom ne prouve ni les événements SEQ ni leur synchronisation.
- [ ] Tester interruption, absence de média, budget mémoire et anciennes recettes sans répéter dégâts ou son.

**Fini quand :** un combat Player réel est validé de bout en bout et que les attaques BW2 du périmètre source sont jouables ou qu’une absence effective de source est identifiée, sans repli silencieusement présenté comme l’animation BW2.

### 4 — Lire les sprites BW2 par pièces

**Responsable :** conversation sprites. **Dépendance :** disponibilité et vérification des sources nécessaires à son périmètre, déjà présentes pour les 649 formes par défaut ; coordination avec le lot 3 pour les ancrages. La fin de tout le lot 2 n’est pas un préalable.

- [ ] Résoudre les écarts du pilote Ponchiot à partir d’hypothèses mesurables ; exploiter les sources techniques indiquées et comparer le résultat à la référence melonDS.
- [x] Comparer pour Ponchiot les atlas PNG et palettes PAL de l’API avec les données NCGR/NCLR de la ROM de Yoahn : face et dos, normal et chromatique. Les indices et les dix banques d’animation/coordonnées concordent ; les palettes possèdent les mêmes valeurs 5 bits. Après harmonisation de la conversion 5→8 bits, les quatre comparaisons d’images ne présentent plus de différence de pixel.
- [ ] Fixer la convention de conversion des palettes et vérifier son effet sur les cinq poses de référence avant de la raccorder au Player ; l’égalité des données ne prouve ni la fidélité de l’animation ni sa cadence.
- [ ] Vérifier face et dos, palette, pièces, animations et placement sur plusieurs Pokémon et formes représentatifs, à échelle comparable à la référence ; ne pas assimiler un aperçu ou un test unitaire à une preuve Player. Déterminer le rythme et le cadrage sans utiliser la référence comme oracle pendant l’exécution.
- [ ] Compiler et embarquer le C/FFI sur les plateformes Player visées, puis raccorder le lecteur aux ressources prises en charge ; annuler les chargements périmés et libérer les ressources. Si la source ou le moteur est indisponible, vérifier le repli GIF → image statique → silhouette. Des données corrompues doivent produire un diagnostic clair et préserver les originaux.
- [ ] Exercer et inventorier automatiquement les 649 formes par défaut et leurs modes pris en charge ; préciser les cas non pris en charge et leur repli. Ne pas annoncer les autres formes ou différences de sexe comme couvertes sans leurs données.

**Fini quand :** Ponchiot face/dos normal/chromatique et au moins une autre espèce sont comparés sur un cycle complet, à échelle et placement fixes, puis vus dans un vrai combat Player : corps entier, appui stable, pas de coupure ni de saut visible, rythme cohérent. Les écarts restants sont montrés à Yoahn plutôt que masqués derrière un seuil inventé. Les sources utilisées, le repli et la couverture sont vérifiés. Les générations 6 à 9 en moteur par pièces restent hors de ce lot.

### 5 — Raccorder Studio, Player et HGSS

**Responsable :** Tom avec les deux conversations. **Dépendances :** lots 1 à 4 pour les capacités utilisées.

- [ ] Faire importer les données et médias avec le vrai transport API, puis par les parcours canoniques de Studio, API d’authoring, JSONL et MCP ; vérifier la présence des actions dans le catalogue MCP vivant et que les nouveaux projets sélectionnent les ressources sans configuration manuelle.
- [ ] Dans le projet HGSS, importer au moins un Pokémon de face et de dos en style BW, son cri, ses icônes et son overworld, puis une attaque pilote ; vérifier aussi une espèce ou forme avec repli.
- [ ] Installer le jeu exporté, couper le réseau et jouer : combat, affichage, son, suivi et chargement. Vérifier au moins un export protégé de Studio 0.3.31+331 et un plus récent, avec des sauvegardes représentatives, via installation, chargement et Continuer. Les originaux restent récupérables en cas d’échec ; nommer les plateformes et parcours 2D/spatial réellement testés.
- [ ] Vérifier les nouveaux formats 3D au niveau catalogue et prévisualisation ; les jeux 3D complets ne sont pas à fabriquer dans ce lot.

**Fini quand :** le vrai parcours Studio → projet → export → Player fonctionne hors réseau sur HGSS et préserve les projets et sauvegardes protégés ; les captures et observations identifient les médias et versions utilisés.

### 6 — Sécuriser et rendre le serveur exploitable

**Responsable :** Tom. **Dépendances :** commence dès le lot 0, clôture après les changements des lots 1 à 5.

- [ ] Vérifier l’authentification, les autorisations, CSRF, limites d’upload, validation des médias, journaux d’audit et accès public/privé ; corriger les défauts constatés sans promettre un risque zéro.
- [ ] Confirmer la surveillance, la capacité, la stratégie de sauvegardes automatiques et leur conservation ; restaurer une copie récente complète, démarrer l’API restaurée et vérifier données et médias. Documenter séparément la procédure de retour arrière en production.
- [ ] Rendre le dépôt API reproductible sur un dépôt distant adapté et un déploiement Dokploy traçable ; ne jamais y inclure secrets, sauvegardes ni médias privés. Le dépôt API est actuellement local, sans distant Git configuré.
- [ ] Simuler une indisponibilité de stockage et un échec de sauvegarde sur un environnement isolé ; vérifier l’erreur et la préservation des données. Garder les secrets hors des sorties et dépôts.
- [ ] Tester l’administration sur mobile, mode clair/sombre et connexion ; vérifier que seule la lecture prévue est publique.

**Fini quand :** les scénarios de sécurité et restauration sont exécutés avec preuves, les défauts critiques identifiés sont corrigés et les risques résiduels sont documentés.

### 7 — Version finale et décision de fin

**Responsable :** Tom, avec validation des deux conversations et de Yoahn. **Dépendances :** lots 0 à 6.

- [ ] Construire une nouvelle version figée à partir du catalogue vérifié, exclure les contenus explicitement privés et contrôler les références et empreintes avant publication.
- [ ] Vérifier l’URL publique, les accès non autorisés, les exemples Pokémon/objets/attaques/médias et le parcours HGSS hors réseau ; sauvegarder après publication et vérifier la restauration selon le lot 6.
- [ ] Livrer la documentation d’utilisation de l’API et de l’administration, les versions, couvertures, limites réelles, commandes d’exploitation et éléments de provenance ; mettre à jour le ticket Notion et committer les changements ciblés.
- [ ] Présenter les preuves à Yoahn pour sa revue : un test unitaire, un catalogue rempli ou une image d’aperçu ne remplacent pas un jeu réellement utilisable.

**Serveur terminé :** les lots 0, 1, 2, 6 et la partie serveur du lot 7 sont démontrés, avec un inventaire complet des données disponibles et des absences ; l’API est exploitable et restaurable.

**Programme entier terminé :** le serveur est terminé, les lots 3, 4 et 5 sont prouvés dans le Player et HGSS, la partie finale du lot 7 est revue, et aucune exigence demandée ne reste simplement supposée. Une publication partielle ou un seul pilote vert ne ferme pas le programme.

## Fichiers et vérifications de départ

- API : `/Users/karim/Project/avelune-pokemon-api/src/imports/`, `src/media/`, `src/catalog/`, `src/auth/`, `admin/` et `tools/backup_to_mac.py`. Contrôles ciblés : `node --import tsx --test test/catalog/partial-publication.test.ts test/catalog/fork-release.test.ts test/auth/fork-release-http.test.ts`, puis `npm run typecheck` et `npm run build` depuis le dépôt API.
- Sources et import Avelune : `packages/map_authoring/lib/src/domains/gameplay/pokemon_external/`, `apps/avelune_studio/lib/features/pokemon/data/pokemon_external_import.dart` et les tests `packages/map_authoring/test/domains/gameplay/avelune_*_source_test.dart`.
- Player : `packages/map_runtime/lib/src/presentation/flame/`, les tests de recettes, sprites et audio sous `packages/map_runtime/test/`, ainsi que `tools/gen5_battle_sprite/PROVENANCE.txt` et `ANIMAENGINE-LICENSE.txt`.
- Parité : conserver l’action `pokemon.gen5_battle_source.import`, contrôler l’API directe, JSONL, Studio et MCP pour les comportements modifiés et signaler toute preuve manquante. Le bilan PMCP-085 existant n’est pas entièrement certifié et la suite MCP globale a été interrompue après plusieurs échecs de tests de bordures ; ne pas la déclarer verte.
- Contrats gameplay à préserver : FG-021, FG-030, FG-044, FG-046, FG-047 et FG-060. Les lots de cette feuille ne changent pas leur statut sans preuve dédiée.
- Hors périmètre de ce plan : refonte de l’interface de combat, combats triples et fabrication de jeux 3D complets. Ces sujets restent possibles après le référentiel et les intégrations demandées.
