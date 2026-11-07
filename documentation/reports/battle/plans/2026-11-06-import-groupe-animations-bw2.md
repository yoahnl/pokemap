# Import groupé des animations BW2 dans Avelune Studio — Implementation Plan

> **Exécution :** utiliser `skills/executing-plans/SKILL.md`, en respectant les instructions du dépôt et l'autorisation Git de Yoahn. Les cases sont des étapes à exécuter, pas des résultats déjà obtenus.

**Goal:** permettre à un créateur d'ajouter en une opération les animations BW2 disponibles pour les attaques de son projet, puis livrer une version de Studio utilisable.

**Architecture:** réutiliser le catalogue versionné Avelune, `AveluneMoveRecipeSource`, les contrôles d'intégrité et l'action canonique `pokemon.move_recipe.import`. Un petit orchestrateur partagé traite les attaques une par une et restitue les résultats ; aucune transaction géante, seconde API Pokémon ou modification des règles de combat n'est nécessaire.

**Tech Stack:** Dart/Flutter, `map_authoring`, `map_core`, `map_distribution`, Studio, JSONL/MCP et API Avelune. Les exports restent utilisables hors ligne.

---

## Périmètre et point de départ

- Les trois lots précédents concernaient l'audit HGSS, les corrections de présentation et la publication des recettes. Le présent plan traite leur **import groupé**, puis la livraison de Studio ; ce n'est pas une refonte du combat.
- Le catalogue public `public-2026-11-06-bw2-hgss` a été publié avec 277 recettes et 1 555 liens vers des médias. Il s'agit des recettes disponibles, pas de 277 animations individuellement validées sur appareil.
- Le dépôt PokeMap est sur `main` à `3d96979b74df288536f0742b1a3cb8c9080acc21` au début de ce plan. Le code des nouveaux projets choisit ce catalogue ; une version de Studio contenant ce changement n'a pas été distribuée dans le cadre du lot précédent.
- Une recette réelle de Surf a déjà été importée depuis l'API dans un projet de test puis exportée ; son programme s'est terminé en simulation hors réseau dans les deux orientations. Audio simulé ; fidélité visuelle et appareil non certifiés.
- Studio importe actuellement une recette à la fois. `PokemonMoveRecipeImport` récupère les métadonnées et médias, puis passe par l'action d'authoring existante. Le panneau d'animation se trouve dans le détail d'une seule attaque. Les textes qui affirment que le Player ne sait pas encore utiliser les animations doivent être revus selon les capacités réellement prouvées.
- L'identité locale n'est pas toujours l'identité API. Dans les liaisons actuelles de HGSS, trois exemples vérifiés dérogent au simple remplacement de `_` par `-` : `smoke_screen → smokescreen`, `faint_attack → feint-attack` et `selfdestruct → self-destruct`.
- Charge possède deux recettes publiques : le pilote `gen5-pilot` et le programme source `gen5-bw2`. La sélection groupée ne doit pas prendre la première réponse au hasard.
- Les projets existants peuvent être épinglés à un catalogue plus ancien ; ne pas changer leur version globale silencieusement. Les recettes portent leur propre version de catalogue dans leur liaison ; tester explicitement l'import depuis le catalogue BW2 dans un projet ancien avant de proposer cette possibilité.
- Hors périmètre : nouveaux effets de combat, amélioration de la fidélité de centaines d'attaques, moteur de squelette Pokémon, modification des sauvegardes, correction de Mimique et livraison iPhone. Ces points restent des suites séparées.
- Repères roadmap : FG-052 et FG-053 restent ouverts et ne sont pas clos par ce travail de présentation/import. Ne pas modifier la roadmap sans demande explicite.

## Résultat attendu pour le créateur

Dans **Pokémon → Attaques**, une commande « Importer les animations disponibles » lance une opération explicite pour les attaques présentes dans le projet. Studio indique la progression, permet d'arrêter l'opération et affiche un bilan lisible. Un nouvel essai ne duplique pas le travail déjà effectué.

La commande respecte ces règles :

1. Ne pas modifier les attaques créées par le joueur, ni remplacer une animation déjà liée. Une liaison identique est comptée comme déjà présente ; une liaison différente est signalée comme conservée.
2. Pour une attaque reconnue, privilégier une unique recette `gen5-bw2`. Si plusieurs recettes de ce style sont éligibles, ne pas choisir arbitrairement : signaler l'ambiguïté. Si ce style manque, un éventuel pilote BW unique est identifié séparément comme repli, après vérification de son identité ; sinon signaler l'absence.
3. Résoudre l'identité par correspondances explicites et vérifiables, y compris les trois cas HGSS ci-dessus ; aucune association approximative sur le nom affiché, aucune attaque personnalisée devinée par ressemblance. Une identité incertaine reste à vérifier.
4. À la fin, répartir chaque attaque examinée dans une seule catégorie : ajoutée, déjà présente, conservée car personnalisée ou liée différemment, sans recette, ambiguë/identité incertaine, ou en échec. Si l'opération est arrêtée, afficher aussi le nombre non traité. Les totaux doivent se recouper avec le nombre examiné.
5. Un échec de téléchargement ou de validation ne détruit ni une liaison existante ni les imports déjà terminés. Il est signalé par attaque ; un nouvel essai traite seulement ce qui reste possible. Un problème global durable de connexion arrête proprement la passe au lieu de répéter indéfiniment les mêmes requêtes.
6. Par défaut, utiliser la version de catalogue du projet. Pour un ancien catalogue sans ces recettes, informer clairement le créateur et proposer explicitement le catalogue d'animations BW2 seulement si les tests prouvent que sa provenance peut être enregistrée sans modifier la version générale du projet.

## Lot A — Sélection correcte et sans surprise

**Fichiers à examiner ou modifier :**

- `apps/avelune_studio/lib/features/pokemon/data/pokemon_move_recipe_import.dart` : identité actuelle, liste des recettes et import individuel.
- `apps/avelune_studio/lib/features/pokemon/data/pokemon_moves_projection.dart` et `apps/avelune_studio/lib/features/pokemon/domain/pokemon_workspace_models.dart` : attaques du projet et provenance `project_custom`.
- `packages/map_authoring/lib/src/domains/gameplay/pokemon_external/avelune_move_recipe_source.dart` et `avelune_pokemon_media_source.dart` : accès au catalogue, pagination et vérification des ressources.
- Tests : `apps/avelune_studio/test/pokemon/pokemon_move_recipe_import_test.dart`, `apps/avelune_studio/test/pokemon/pokemon_catalog_release_test.dart` et un test ciblé de sélection groupée sous `packages/map_authoring/test/domains/gameplay/`.

- [ ] Construire l'inventaire à partir des attaques réellement présentes, indépendamment du filtre de recherche affiché dans Studio. Relever séparément celles qui sont personnalisées ou déjà liées, sans lire ni réécrire les autres ressources du projet.
- [ ] Définir une correspondance explicite, partagée par l'import individuel et l'import groupé. Couvrir Charge, Surf, les trois alias HGSS, une identité inconnue et une attaque `project_custom`. Si les métadonnées disponibles ne suffisent pas à établir une correspondance, la classer incertaine ; ne pas inventer une identité.
- [ ] Choisir `gen5-bw2` devant `gen5-pilot` pour Charge ; tester aussi deux candidates `gen5-bw2`, aucun résultat et une réponse de catalogue invalide. Ne pas annoncer une recette comme jouable simplement parce qu'elle a été trouvée.
- [ ] Tester une liaison existante identique, une liaison différente, un ancien catalogue et une version indisponible. Vérifier que le projet existant et son catalogue ne sont pas réécrits lors de la recherche.

**Fin du lot A :** un résultat de sélection déterministe et explicable pour chaque cas, sans aucune écriture au stade de la recherche.

## Lot B — Import par unités sûres et parité d'accès

**Fichiers à examiner ou modifier :**

- `packages/map_authoring/lib/src/domains/gameplay/battle_recipe_import_actions.dart` et `packages/map_authoring/lib/src/workspace/catalog/catalog_battle_recipe_selection.dart` : action existante et lectures limitées à ses dépendances.
- `packages/map_authoring/lib/src/domains/gameplay/pokemon_external/` : petit orchestrateur groupé et politique de sélection partagés, à exporter par le barrel public approprié.
- `packages/map_authoring/lib/src/tooling/jsonl_worker.dart`, `tools/pokemap_mcp/src/tools/mutations.ts` et le catalogue de découverte : exposition du même comportement canonique par JSONL et MCP ; préserver l'action unitaire existante.
- `apps/avelune_studio/lib/features/pokemon/data/pokemon_move_recipe_import.dart` et `local_pokemon_workspace_adapter.dart` : raccord de Studio au coordinateur partagé et au verrou existant.
- Tests : `packages/map_authoring/test/workspace/battle_recipe_import_test.dart`, `tools/pokemap_mcp/test/battle_recipe_import_stdio.test.ts` et un test groupé ciblé pour chaque transport concerné.

- [ ] Exécuter la sélection et la politique de résultat dans `map_authoring`, partagées par Studio et les transports. Exposer une commande groupée découvrable côté JSONL/MCP qui orchestre les mêmes imports unitaires ; ne pas présenter le groupe comme une transaction atomique et ne pas créer un second chemin d'écriture des fichiers. Les transports traitent des sous-listes bornées et renvoient les résultats et le travail restant : pas de job permanent ni d'appel unique supposé pouvoir attendre tout le catalogue.
- [ ] Pour chaque attaque éligible, récupérer les médias avec les limites et empreintes existantes, puis utiliser `pokemon.move_recipe.import` avec sa portée, sa vérification de révision et ses reçus. Une seule attaque est validée à la fois ; les résultats déjà validés restent acquis si la suivante échoue ou si l'utilisateur arrête la passe.
- [ ] Préserver les limites par recette : 1 Mio de JSON, 256 ressources, 8 Mio par image ou son et 64 Mio pour le paquet ; conserver les contrôles de types, dimensions, SHA-256 et provenance. Les erreurs d'intégrité ne doivent pas devenir des succès ou des replis silencieux.
- [ ] Démarrer avec une concurrence réseau de **1** : le serveur public limite lui-même les lectures simultanées. Éviter les recherches doublonnées dans une même opération si cela reste compatible avec la vérification de version et d'empreinte. Mesurer le nombre réel de requêtes et l'impact avant d'envisager davantage de parallélisme.
- [ ] Éviter qu'une importation de 277 attaques relise ou recalcule l'ensemble du projet, des cartes ou de son historique pour chaque attaque. Mesurer les lectures, écritures, décodages et invalidations du premier import et des suivants, avec contenu/historique sans rapport ajoutés. Corriger la frontière propriétaire si le coût dépasse les dépendances réelles ; ne pas contourner l'authoring canonique.
- [ ] Tester : import de plusieurs attaques, relance sans doublon, média corrompu, erreur réseau, interruption pendant le téléchargement et avant l'application, modification concurrente, ressource déjà liée différemment et récupération après interruption. Vérifier les états persistés après réouverture.
- [ ] Prouver le même résultat et les mêmes refus par appel direct, JSONL, Studio et MCP. Reconstruire le serveur MCP, vérifier `pokemap_describe`, puis exécuter une passe groupée sur une fixture limitée. Une simple boucle de persistance JSON ne constitue pas cette preuve.

**Fin du lot B :** plusieurs recettes sont ajoutées sans doublon ni perte ; une interruption laisse un état cohérent et un bilan exact. Aucune promesse que tous les programmes sont visuellement fidèles.

## Lot C — Une commande claire dans Studio

**Fichiers à examiner ou modifier :**

- `apps/avelune_studio/lib/presentation/features/pokemon/pokemon_moves_library.dart` : commande placée au niveau du catalogue, accessible sans sélectionner chaque attaque.
- `apps/avelune_studio/lib/presentation/features/pokemon/pokemon_move_recipe_panel.dart` : préserver le choix individuel et corriger les libellés `gen5-bw2` / Player devenus inexacts.
- `apps/avelune_studio/lib/features/pokemon/application/pokemon_move_recipe_commands.dart`, `pokemon_workspace_controller.dart`, `pokemon_move_recipe_port.dart` et les modèles de résultat : état, progression et annulation.
- Tests : `apps/avelune_studio/test/pokemon/pokemon_move_recipe_panel_test.dart` et un test groupé de contrôleur/écran sous `apps/avelune_studio/test/pokemon/`.

- [ ] Ajouter un bouton au niveau de la bibliothèque et afficher « analyse », puis « X sur Y » pendant l'import. L'action est indisponible si une autre mutation est active ou si des modifications non enregistrées empêchent déjà l'import individuel.
- [ ] Permettre l'arrêt sans promettre d'annuler les attaques déjà enregistrées : terminer ou refuser proprement l'attaque en cours selon son état, puis afficher « import arrêté » et les nombres exacts. Aucun téléchargement ou écriture ne doit continuer après fermeture de la session.
- [ ] Présenter un bilan synthétique avec les noms des attaques non importées et une raison compréhensible ; conserver le détail technique dans les traces, pas dans le parcours normal. Les totaux ne doivent pas prétendre que les animations ont toutes été visionnées.
- [ ] Utiliser les composants et couleurs du design system existant, avec libellés accessibles. Tester les états initial, chargement, succès partiel, erreur, arrêt, relance et affichage compact ; vérifier que le bouton individuel continue de fonctionner.
- [ ] Vérifier le temps jusqu'au premier retour visuel et le coût des écritures unitaires sur un projet représentatif. Les cibles usuelles du dépôt pour un simple changement local sont 100 ms pour le retour et 500 ms pour une persistance durable ; ne pas les revendiquer pour un import réseau groupé sans mesure appropriée.

**Fin du lot C :** un créateur peut lancer, suivre et relancer l'import sans sélectionner chaque attaque ni perdre ses personnalisations.

## Lot D — Chaîne complète, puis livraison de Studio

**Fichiers et outils à utiliser :**

- Tests Studio : `apps/avelune_studio/test/pokemon/pokemon_move_recipe_import_test.dart` et les nouveaux tests groupés.
- Tests authoring : `packages/map_authoring/test/workspace/battle_recipe_import_test.dart` et les nouveaux tests groupés.
- Contrôles MCP : `tools/pokemap_mcp/`, `packages/map_authoring/tool/pmcp085_conformance.dart` et `test/parity/full_authoring_parity_test.dart`.
- Parcours Player : `packages/map_runtime/test/battle_verified_recipe_sound_test.dart`, avec les ressources de la fixture exportée, puis les smoke tests du dépôt si le runtime est touché.
- Livraison : `apps/avelune_studio/pubspec.yaml` et `.github/workflows/pokemap_desktop_release.yml`, seulement après les vérifications ; ne pas ajouter de nouveau job macOS coûteux à la CI.

- [ ] Sur un projet neuf de test sous `/Users/karim/Library/Caches/AveluneQA/`, lancer l'import groupé avec Charge, Surf, Damoclès, un alias, une attaque déjà liée, une attaque personnalisée et une sans recette. Vérifier le bilan, les empreintes et la réouverture ; conserver l'original intact.
- [ ] Effectuer ensuite une passe bornée sur les attaques HGSS disponibles, sur une copie de test minimale. Compter recettes proposées, ajoutées, déjà présentes, protégées, absentes, ambiguës et échecs. Ne pas présumer que chaque projet doit recevoir 277 recettes : seuls les moves éligibles et absents sont candidats.
- [ ] Exporter la copie de test en `.avelunegame`, contrôler les médias et leurs empreintes, couper l'accès réseau et exercer au moins Surf et Charge en portrait et paysage dans un combat simulé. Distinguer chargement, exécution, rendu observé et validation humaine ; un son simulé ne certifie pas son rendu réel.
- [ ] Exécuter les tests ciblés et l'analyse des fichiers modifiés. Exécuter `dart run tool/pmcp085_conformance.dart` et les contrôles MCP nécessaires ; le contrôle global PMCP était incomplet lors du lot précédent, le résultat actuel doit être rapporté sans masquer les écarts. Suivre et nettoyer uniquement les processus et fichiers QA appartenant à cette tâche.
- [ ] Construire une version macOS de Studio, vérifier son identité et son lancement, puis tester visuellement la commande et l'import sur un projet de test. Préparer la distribution par le workflow existant et utiliser un numéro de version cohérent ; ne pas confondre une compilation réussie avec une version effectivement installable ou distribuée.
- [ ] Mettre à jour le ticket Notion existant du domaine **Combat solo** avec preuves, limites et références Git. Commiter et pousser les changements ciblés selon les instructions de Yoahn ; conserver les travaux non liés et indiquer le résultat de la CI.

**Fin du lot D :** une version de Studio contenant la commande est réellement disponible pour l'essai, et un export issu de l'import groupé fonctionne hors ligne sur les exemples retenus. Si signature, distribution ou validation native bloque, signaler précisément l'étape manquante et conserver le lot partiel.

## Critères de fin et suites

- L'utilisateur peut lancer un import groupé depuis Studio et comprendre son résultat, même s'il ne trouve pas toutes les attaques.
- Les liaisons existantes, attaques personnalisées, jeux et sauvegardes ne sont pas écrasés ou migrés implicitement ; un nouvel essai est sans doublon.
- Le même comportement est exposé à l'authoring, à JSONL et à MCP, et les médias importés suivent l'export hors ligne.
- Le bilan donne des nombres propres au projet testé et distingue simulations, observations visuelles et essais sur appareil.
- Les 277 recettes publiées ne sont pas présentées comme 277 animations parfaites ou comme 277 imports nécessaires pour tous les projets.
- Ensuite seulement : vérifier Mimique ; quand Yoahn le souhaite, mettre à disposition un Player compatible et un export HGSS à tester sur iPhone. Les améliorations visuelles et les Pokémon articulés gardent leur suivi propre.

## Relecture du plan avant exécution

- **Architecture :** le chemin unitaire et les limites existent ; le traitement par lot doit les orchestrer sans contourner la persistance ni inventer une transaction globale.
- **Implémentation :** la sélection est partagée, la progression est portée par Studio et chaque attaque conserve sa propre transaction. Les noms de fichiers nouveaux proposés restent à confirmer au moment du changement.
- **Identités :** les trois exceptions HGSS et les deux recettes Charge sont des cas constatés dans les données, pas une garantie que toutes les autres correspondances sont correctes.
- **Tests et build :** les commandes et fixtures indiquées sont des vérifications à effectuer pendant l'exécution ; aucun nouveau test ni build applicatif n'a été exécuté lors de la rédaction de ce plan.
- **Validation de la rédaction :** `git diff --check` est sans erreur. Le contrôle Markdown du dépôt, lancé avec une exception pour ce seul plan, signale deux fichiers ignorés préexistants hors de ce chantier ; ils ont été conservés.
- **Critique finale :** le passage groupé par JSONL/MCP et le choix d'un autre catalogue pour un projet existant restent à prouver, pas à présumer. Le coût répété de lecture du catalogue, la latence réseau, les interruptions et la disponibilité des outils de distribution devront être mesurés avant de déclarer le lot terminé.
