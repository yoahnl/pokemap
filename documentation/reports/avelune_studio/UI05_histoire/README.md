# AS-UI-005 — Histoire, vue d’ensemble

Page Histoire livrée pour revue visuelle. Aucun autre écran n’a été refondu. Les éditeurs détaillés, opérations de publication, moteurs, dépendances, configuration native et logos existants sont conservés. Aucune écriture Git ou Notion ; les seuls projets manipulés sont des fixtures temporaires.

## Audit initial et décisions

État initial propre, HEAD `8ee866c8e603bf673e3f9ab2097a06da66c08483`. Le pack UI05 et ses trois images ont été lus/ouverts avant le code. L’ancienne page aplatissait les histoires, ouvrait l’éditeur au clic et proposait toutes les interactions lorsqu’une étape n’avait aucun lien.

La consultation utilise une projection indexée en mémoire, distincte des opérations. Elle fusionne les sessions locales avec les enregistrements canoniques par identifiant, utilise les noms des documents déjà ouverts et ne charge aucun dialogue ou carte supplémentaire. Les chapitres/étapes suivent leur ordre canonique ; les égalités conservent l’ordre source. Aucune progression jouée ni classification principale n’est inventée.

Les liens étape/scène couvrent les deux directions canoniques. Une référence manquante est distincte d’un format avancé ; les formats avancés restent consultables sans conversion. Un brouillon éditable reste reprenable même s’il présente une référence à réparer. Les noms des sources non chargées portent une indication explicite.

Sélectionner consulte ; les boutons ouvrent l’éditeur ou localisent une source réelle. Les retours conservent recherche, sélection, chapitres, défilement, documents modifiés et historique. Les ouvertures concurrentes sont gardées par requête et projet. Les sources sans coordonnées produisent un diagnostic local, sans marqueur inventé. L’enregistrement annonce son périmètre réel : narration et cartes ouvertes modifiées.

## Comparaison visuelle

Première capture complète produite avant la passe de finition ; comparée à la cible basse résolution et au cadre actuel. La cible guide la hiérarchie, sans reproduire son illustration ni ses statistiques fictives.

- Navigation locale : 210 px, histoires sélectionnables et trois vues locales.
- Centre : espace majoritaire, chapitres repliables, étapes et liens explicites.
- Détail : 320 px, contexte de source, Quand / Si / Alors et actions distinctes.
- Corrections après la première capture : ordre canonique des chapitres/étapes, diagnostic des liens indirects, en-tête réduit en détail compact pour rendre de la place au contenu.
- À 1024 × 640 et 150 %, le détail utilise l’espace central avec retour à la liste et défilement. L’en-tête utilise un menu d’actions dans les fenêtres basses, également testé avec Échap. Le débordement trouvé au retour à la liste avec les polices de test a été corrigé. Pas de réduction forcée de la police.

Captures sans retouche des **vrais widgets Flutter hors écran**, à densité 1, sur `Ui05NarrativeFixture` publiée par les adaptateurs réels. Elles ne constituent pas un essai natif interactif :

| Capture | État vérifié |
| --- | --- |
| [01-histoire-structuree.png](01-histoire-structuree.png) | Deux histoires, chapitres et étapes, 1536 × 1024 |
| [02-interactions-homonymes.png](02-interactions-homonymes.png) | Trois homonymes distingués par carte et source |
| [03-brouillon-local.png](03-brouillon-local.png) | Brouillon local repris sans publication implicite |
| [04-compact-150.png](04-compact-150.png) | Véritable format avancé, 1024 × 640, texte à 150 % |
| [05-retour-carte-source.png](05-retour-carte-source.png) | Chef de gare sélectionné sur sa carte modifiée, outil Sélection |

Les comparaisons ont porté sur la vue complète puis sur navigation locale, contenu central et détail : hiérarchie, largeur utile, lisibilité des sources et emplacement des actions. L’acceptation visuelle finale appartient à Yoahn.

## Fichiers et zones

Chemins ci-dessous relatifs à `apps/avelune_studio/`. « Ajout » désigne un fichier nouveau ; les autres sont modifiés. Le diff Git et les sources restent la preuve technique, sans copie intégrale dans ce rapport.

| Fichier | Zone / raison |
| --- | --- |
| lib/features/map_workspace/application/map_workspace_controller.dart | `activate`, garde d’une requête périmée, état de fermeture |
| lib/features/narrative/application/narrative_workspace_controller.dart | délégation d’ouverture, publication conservée, refus d’étapes toutes blanches |
| lib/features/narrative/application/narrative_interaction_opener.dart | Ajout : ouvertures/reprises/localisation, garde de génération et projet |
| lib/features/narrative/application/narrative_source_location.dart | Ajout : coordonnées canoniques NPC/zone |
| lib/features/narrative/application/narrative_overview.dart | Ajout : modèle de consultation, disponibilité d’édition |
| lib/features/narrative/application/narrative_overview_cache.dart | Ajout : cache par identités pertinentes, sans I/O |
| lib/features/narrative/application/narrative_overview_context.dart | Ajout : index des noms et liens scène/étape dans les deux sens |
| lib/features/narrative/application/narrative_overview_projection.dart | Ajout : fusion persisté/local, compatibilité, résumés et diagnostics |
| lib/features/narrative/application/narrative_overview_references.dart | Ajout : références typées et textes des conditions/actions |
| lib/presentation/features/narrative/narrative_story_pane.dart | nouvelle composition adaptative et navigation explicite |
| lib/presentation/features/narrative/narrative_overview_content.dart | Ajout : listes paresseuses, recherche, filtre carte et états |
| lib/presentation/features/narrative/narrative_overview_detail.dart | Ajout : détail contextuel, liens et actions |
| lib/presentation/features/narrative/narrative_overview_header.dart | Ajout : création existante, enregistrement au périmètre honnête |
| lib/presentation/features/narrative/narrative_overview_navigation.dart | Ajout : navigation locale et histoires |
| lib/presentation/features/narrative/narrative_overview_view_state.dart | Ajout : conservation de l’état de consultation et du cache |
| lib/presentation/features/narrative/narrative_story_chapters.dart | Ajout : chapitres/étapes ordonnés, repli et sélection |
| lib/presentation/features/narrative/narrative_interaction_pane.dart | seul libellé de retour paramétrable, pas de refonte |
| lib/presentation/features/map_workspace/workspace_story_binding.dart | Ajout : origine du retour, ouverture, localisation et création contextualisée |
| lib/presentation/features/map_workspace/workspace_secondary_content.dart | callbacks et état Histoire raccordés |
| lib/presentation/features/map_workspace/map_workspace_screen.dart | état Histoire, annulation des ouvertures, garde des raccourcis |
| lib/presentation/features/map_workspace/workspace_home_binding.dart | fonctions narratives déplacées vers leur raccord dédié |
| lib/presentation/features/map_workspace/map_workspace_view_state.dart | sélection de zone, centrage volontaire à zoom conservé |
| lib/presentation/features/map_workspace/map_workspace_canvas.dart | réutilisation du centrage et de l’overlay de zone |
| test/narrative_overview_test.dart | Ajout : 1 000 interactions, cache, fusion, noms en mémoire et liens |
| test/narrative_overview_links_test.dart | Ajout : deux directions de lien scène/étape, absence et déduplication |
| test/narrative_overview_availability_test.dart | Ajout : structure absente distincte du format avancé |
| test/narrative/narrative_navigation_ui05_test.dart | Ajout : courses A/B, fermeture/projet, reprise, localisation et création vide |
| test/narrative/narrative_source_location_ui05_test.dart | Ajout : sources sans coordonnées, drafts NPC/zone, centrage et zoom |
| test/narrative/narrative_story_navigation_test.dart | sélection seule, action explicite, 1 000 étapes et 1 000 interactions montées paresseusement |
| test/presentation/ui05_story_journey_test.dart | Ajout : parcours réel, homonymes, filtre, brouillon, retour Carte, clavier et tailles |
| test/presentation/ui05_story_creation_test.dart | Ajout : annulations, création, publication réelle, réouverture et carte sale |
| test/support/ui05_narrative_fixture.dart | Ajout : fixture temporaire canonique, compteurs et empreintes des fichiers |
| test/presentation/m3_authoring_journey_test.dart | deux libellés actualisés, garanties du parcours conservées |

Ce dossier ajoute uniquement cette note, `verification.txt` et les cinq PNG ci-dessus.

## Vérifications

Résultats finaux : **29 tests ciblés réussis ; suite Studio 319 réussis et 2 ignorés ; analyse sans problème ; build macOS debug réussi ; 4 tests API/JSONL et 82 tests MCP packagé réussis**. Les deux tests ignorés nécessitent une copie externe Train via `AVELUNE_PROJECT_COPY` ; ils n’ont pas été présentés comme exécutés.

Les commandes et sorties finales sont regroupées dans [verification.txt](verification.txt). Les tests ciblés vérifient notamment :

- zéro lecture de dialogue, zéro publication et fichiers inchangés pendant la consultation ;
- homonymes ouverts par identité, bonne carte/source, brouillon et carte sale conservés ;
- annulation sans effet, création puis sauvegarde/réouverture via les adaptateurs réels ;
- index de 1 000 interactions sans I/O, construction de moins de 30 lignes visibles, accès à la dernière entrée et recherche ;
- formats avancés réels protégés, références absentes explicites, courses de navigation ;
- 1536, 1440, 1280 et 1024 × 640 à 150 %, saisie clavier sans commandes Carte cachées.

Les premières passes ont corrigé l’ancienne attente « sélectionner ouvre », une fixture vide rejetée par le compilateur de dialogues, un test qui tentait de cliquer une liste déjà remplacée par le détail compact, et des fixtures dites avancées qui étaient en réalité incomplètes. Le parcours fait aussi défiler le détail avant son action, car les polices de test sans capture prennent davantage de place. Les doubles ont été rendus fidèles ; aucune validation canonique n’a été retirée.

Les processus des tests Flutter sont suivis par PID et descendants ; seuls les descendants appartenant à l’exécution peuvent être récoltés. Aucun arrêt global.

## Parité, revue et limites

Pas de nouveau contrat auteur ni d’opération moteur : les publications canoniques existantes sont réutilisées. Les contrôles API/JSONL et MCP packagé sont distincts de l’UI. Le `pokemap_describe` connecté a échoué avec `worker.exited`, code 78 : **parité connectée non certifiée**, sans élargissement du périmètre. La certification globale PMCP-085 n’a pas été relancée pour cette projection locale ; les publications narratives et les transports packagés ont été rejoués.

Verdicts des passes déléguées : projection — liens indirects et disponibilité corrigés, pas d’autre blocage identifié ; navigation — requêtes périmées et sources de brouillons protégées ; critique/tests — localisation `draftOrNull.source` corrigée, volume et filtre réellement exercés. La passe principale a comparé les captures et réduit l’en-tête compact.

Auto-critique : les textes complets des dialogues et les sources de cartes non chargées ne sont volontairement pas analysés ; les graphes avancés ne sont pas transformés en récits simplifiés. Les liens indiquent des références, pas une preuve d’atteignabilité ou de progression. La recherche reste limitée au périmètre affiché. La validation interactive native et l’acceptation visuelle restent ouvertes.

État final : 11 fichiers suivis modifiés, 22 nouveaux fichiers Dart et 7 fichiers de preuve non suivis ; aucun fichier indexé ni commit. Aucun package partagé, dépendance, projet original ou configuration native modifié. Attendre la validation visuelle avant toute autre page.

Lancement depuis `apps/avelune_studio` : `flutter run -d macos`.

## Complément AS-UI-005 — vue d’ensemble du Narrative Studio (23 septembre 2026)

Ce complément décrit l’intervention actuelle ; les résultats et le HEAD de la section précédente sont historiques. La rubrique Histoire ouvre désormais une vue d’ensemble illustrée, distincte de l’accueil général. La vue détaillée UI05 reste accessible par « Voir tous les documents ». Aucun écran voisin, moteur narratif, package partagé ou projet utilisateur n’a été modifié.

### Audit, décisions et passes

État initial : arbre propre sur `main`, HEAD `08f9d75e891e42b953e3d676fc3d2b199e9699b7`. Le mandat nommait deux fichiers absents du kit ; Yoahn a explicitement retenu `ecrans/01_vue_ensemble_narrative/FICHE.md` et sa `MAQUETTE.png`. La maquette a été ouverte à taille originale. L’écran existant était une consultation structurée en trois colonnes, sans bandeau illustré ni reprise synthétique. Les propriétaires des histoires, scènes, dialogues et événements, la projection narrative et les routes Carte/Vérification étaient déjà présents : le risque principal était une navigation qui perdrait la sélection ou prendrait un document enregistré pour un brouillon.

Passes séparées, sans sub-agent : **Audit/architecture** — conserver la projection et ses frontières ; **Implémentation** — ajouter seulement la composition et ses raccords ; **Tests** — vérifier identités, brouillons, absence d’écriture et anciens parcours ; **Build/validation** — analyse, architecture, build et suite Studio ; **Critique finale** — aucun pourcentage, date de modification ou état « terminé » inventé. Les chapitres servent seulement à contextualiser les étapes ; la progression de l’auteur ne devient pas une progression du joueur. L’illustration d’ambiance est commune aux cartes d’histoires car `StorylineAsset` ne porte pas de miniature dédiée.

### Parcours et comparaison

La page regroupe bandeau et quatre accès rapides, cartes des histoires réelles, quatre premières étapes dans l’ordre canonique, cartes du projet, reprise des sessions ouvertes ou sales, comptes issus des catalogues et accès à la vérification existante. La recherche rejoint l’identité exacte de l’histoire, de l’étape, de la scène, du dialogue, de l’événement, de l’interaction ou de la carte. L’ouverture d’une histoire mène à son graphe ; une étape sélectionne son nœud ; une scène et ses brouillons reviennent à leur propriétaire. La simple consultation ne publie rien.

La capture initiale montrait encore la vue en trois colonnes. Après comparaison avec la référence 1584 × 993, les actions ont été replacées dans le bandeau ; la galerie et les étapes remontent dans le premier écran. À 1440, les quatre accès tiennent sur une ligne ; à 1280 ils passent sur deux lignes. À 1024 × 640 avec texte à 150 %, le bandeau grandit, la page défile et aucun texte ne déborde. Les données de la fixture ne reproduisent pas les contenus inventés de la maquette.

Captures des **vrais widgets Flutter hors écran**, sans retouche, depuis une fixture temporaire publiée par les adaptateurs locaux ; aucune manipulation native n’est prétendue :

| Fichier | État |
| --- | --- |
| [06-vue-ensemble-narrative.png](06-vue-ensemble-narrative.png) | 1536 × 1024, vue complète |
| [07-vue-ensemble-1280.png](07-vue-ensemble-1280.png) | 1280 × 800, accès sur deux rangées |
| [08-vue-ensemble-1440.png](08-vue-ensemble-1440.png) | 1440 × 900, quatre accès dans le bandeau |
| [09-vue-ensemble-compact-150.png](09-vue-ensemble-compact-150.png) | 1024 × 640, texte à 150 % |
| [10-reprise-scene-brouillon.png](10-reprise-scene-brouillon.png) | Retour depuis le Scene Builder avec session modifiée |

### Fichiers et zones de diff

Préfixe de tous les chemins de code : `apps/avelune_studio/`. Les fichiers `lib/` sont le code de la page et de ses routes ; `test/` contient les parcours et leurs fixtures. Le diff Git donne les lignes exactes.

| Fichier | Zone et effet |
| --- | --- |
| `lib/presentation/features/narrative/narrative_overview_landing.dart` | Ajout : composition, bandeau et accès rapides adaptatifs |
| `lib/presentation/features/narrative/narrative_overview_landing_content.dart` | Ajout : histoires, étapes ordonnées et cartes liées |
| `lib/presentation/features/narrative/narrative_overview_landing_side.dart` | Ajout : sessions reprises, comptes réels, accès à la vérification |
| `lib/presentation/features/narrative/narrative_overview_landing_search.dart` | Ajout : recherche par identités et composants de ligne |
| `lib/presentation/features/narrative/narrative_story_pane_overview.dart` | Ajout : raccords des documents et propriétaires depuis UI05 |
| `lib/presentation/features/narrative/narrative_story_pane.dart` | Vue d’ensemble par défaut, détail préservé et retour explicite |
| `lib/presentation/features/narrative/narrative_overview_view_state.dart` | État de navigation de la vue d’ensemble |
| `lib/presentation/shared/widgets/buttons/studio_action_card.dart` | Ajout : action compacte aux tokens Avelune |
| `lib/presentation/shared/widgets/inputs/studio_resource_card.dart` | Variante d’aperçu plein cadre pour les histoires |
| `lib/presentation/features/map_workspace/workspace_progression_binding.dart` | Ouverture de l’histoire et du nœud d’étape exacts |
| `lib/presentation/features/map_workspace/workspace_story_binding.dart` | Ouverture gardée d’une carte du projet depuis UI05 |
| `lib/presentation/features/map_workspace/workspace_dialogue_binding.dart` | Ouverture du dialogue dans son propriétaire |
| `lib/presentation/features/map_workspace/workspace_event_binding.dart` | Filtre de source et ouverture de l’événement exact |
| `lib/presentation/features/map_workspace/workspace_screen_body.dart` | Passage des quatre nouvelles destinations |
| `lib/presentation/features/map_workspace/workspace_secondary_content.dart` | Passage des propriétaires et retours à UI05 |
| `test/presentation/ui05_narrative_overview_landing_test.dart` | Ajout : création, histoire/étape exactes, carte, tailles et absence de publication |
| `test/presentation/ui05_narrative_overview_links_test.dart` | Ajout : brouillon de scène, dialogue et événement exacts, retours |
| `test/support/ui05_narrative_fixture.dart` | Propriétaires locaux réels pour le parcours de la page |
| `test/support/ui05_narrative_port.dart` | Ajout : port de fixture extrait pour respecter la limite de 300 lignes |
| `test/narrative/narrative_story_navigation_test.dart` | Entre directement dans le détail qu’il caractérise |
| `test/presentation/ui05_story_creation_test.dart` | Accède au détail avant son ancien parcours de création |
| `test/presentation/ui05_story_journey_test.dart` | Accède au détail et rend le défilement de l’action fiable |
| `test/presentation/m3_authoring_journey_test.dart` | Accède au détail avant le parcours M3 |
| `test/presentation/ui06_scene_navigation_test.dart` | Ouvre le détail avant l’onglet Interactions |
| `test/support/ui10_workspace_harness.dart` | Préserve l’accès Cinématique par le détail |
| `test/support/ui12_close_harness.dart` | Préserve l’accès États et règles par le détail |
| `test/support/ui13_host_harness.dart` | Utilise le vrai bouton de vérification de la nouvelle page |
| `test/support/map_host_fixture.dart` | Route générique vers États et règles via le détail |
| `test/ui12_world_navigation_test.dart` | Vérifie le retour Histoire après la nouvelle entrée |

Les cinq PNG ci-dessus et cette section sont les seules preuves ajoutées au rapport existant. Aucun commentaire n’a été ajouté au code manuel, conformément au mandat de Yoahn.

### Vérifications finales et critique

Depuis `apps/avelune_studio`, sur les sources et tests finaux :

| Commande | Résultat exact |
| --- | --- |
| `flutter test test/presentation/ui05_narrative_overview_landing_test.dart test/presentation/ui05_narrative_overview_links_test.dart --reporter expanded --no-pub --concurrency=2` | 4 tests réussis, exit 0 ; captures ci-dessus |
| `flutter test test/ui12_world_close_test.dart test/ui12_world_global_close_test.dart test/ui12_world_navigation_test.dart test/map_workspace/keyboard_delete_host_test.dart test/presentation/ui06_scene_navigation_test.dart --reporter expanded --no-pub --concurrency=2` | 14 tests réussis, exit 0 |
| `flutter test test/presentation/desktop_workspace_layout_test.dart --reporter expanded --no-pub` | 1 test de stress réussi isolément, exit 0 |
| `flutter test test/architecture/architecture_boundaries_test.dart --reporter expanded --no-pub` | 7 tests réussis, exit 0 |
| `flutter analyze --no-pub` | `No issues found!`, exit 0 |
| `flutter build macos --debug --no-pub` | `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app`, exit 0 |
| `flutter test --no-pub --concurrency=2 --reporter compact` | `08:03 +895 ~2: 2 skipped tests. All other tests passed!`, exit 0 |

Depuis la racine : `bash tools/scripts/check_markdown_hygiene.sh` → `Markdown hygiene: no new Markdown files.`, exit 0 ; `git diff --check` → aucune sortie, exit 0. Les deux tests ignorés sont ceux de la suite Studio qui demandent une copie externe ; ils ne sont pas comptés comme exécutés. Le journal textuel est ajouté à [verification.txt](verification.txt).

Les passes intermédiaires de la suite ont d’abord révélé dix tests utilisant encore l’ancien accès direct depuis Histoire et un test de stress dépassant son attente d’E/S de 20 secondes. Les parcours historiques ont été réorientés via « Voir tous les documents », sans supprimer leurs assertions métier ; les 14 cas concernés passent, puis la suite finale passe. Une deuxième passe a relevé un test neuf cliquant « Créer » avant la reconstruction de la boîte de dialogue ; le test vérifie désormais l’activation réelle puis attend le rendu, et passe en suite finale. Le succès isolé du stress n’a pas été substitué au résultat en suite : ce dernier est aussi réussi dans l’exécution finale.

Verdicts des passes : **Audit/architecture** — frontières conservées, pas de nouveau contrat moteur ; **Implémentation** — page et destinations réelles livrées ; **Tests** — identités, annulation, brouillons, retour et absence d’écriture prouvés ; **Build/validation** — analyse, build et suite finale réussis ; **Critique finale** — pas de sortie de périmètre dans les fichiers de code, mais les images d’histoires restent une illustration Avelune commune faute de miniature dans le modèle. Aucun nouvel acte auteur sémantique n’est exposé : parité MCP non applicable à cette composition de présentation, et aucun transport MCP n’est revendiqué comme testé dans cette intervention.

Limites : pas de manipulation native interactive, pas de pourcentage d’écriture ni de statut de progression du joueur inféré, pas d’illustration propre à chaque histoire. La validation visuelle finale revient à Yoahn. Aucun autre écran n’est commencé. État Git final : modifications UI05 et tests/raccords décrits ci-dessus, cette note, `verification.txt` et cinq captures non indexées ; aucun commit, push ou changement Notion. Lancement : `cd apps/avelune_studio && flutter run -d macos`.

## Complément — illustrations propres au Train de 17h42

L’illustration Avelune commune était encore utilisée dans le bandeau et chaque carte d’histoire. Audit du projet ouvert : `Le train de 17h42` possède 188 scènes et 41 dialogues, mais aucune `StorylineAsset`. La demande d’images personnalisées ne justifie donc pas de créer artificiellement des chapitres ni de modifier le récit. L’état Git initial de cette passe était `main` à `d15171687bdcba63ee928f09c3fcf8ec8574d9c0`, avec les modifications UI05 décrites ci-dessus déjà présentes et non indexées.

Studio lit désormais `assets/studio/narrative/hero.png`, `stories/<id>.png` et `scenes/<id>.png` dans le projet ouvert, via le lecteur de fichiers borné au projet. Une image absente ou invalide utilise le repli visuel ; un changement de projet ne conserve pas son image précédente pendant le chargement. Quand aucune histoire structurée n’existe, les trois premières scènes réelles occupent les grandes cartes du centre ; les quatre premières restent accessibles dans la reprise latérale. Le clic conserve l’identité de la scène et rejoint son éditeur existant. Il s’agit d’illustrations de Studio, sans changement du moteur ni des données de jeu.

Cinq PNG originaux ont été générés et placés dans le projet externe `/Users/karim/Desktop/pokeMap Project/le_train_de_17h42/assets/studio/narrative/`. Une copie identique, vérifiée octet par octet, est suivie dans ce rapport sous `artwork_train/` afin que le push contienne aussi le travail graphique : `hero.png`, puis `scenes/campaign-opening.png`, `campaign-shizune.png`, `campaign-photo-home.png` et `campaign-box-home.png`. Pour réinstaller ce pack dans une autre copie du Train, recopier le contenu de `artwork_train/` vers `assets/studio/narrative/` de cette copie. Le visuel Shizune a été régénéré après confrontation au personnage canonique, scientifique et soigneuse. Le `project.json` original n’a pas été écrit : SHA-256 initial et final `bd808b9bf2971f1352878295a86b15a6e9c5c7a539568c641070125ec73fa6a3`.

Zones nouvelles ou modifiées de cette passe, sous `apps/avelune_studio/` : `lib/features/narrative/domain/narrative_port.dart` définit le port de lecture décorative ; `lib/features/narrative/data/local_narrative_adapter.dart` valide l’identifiant et lit les PNG dans le projet ; `lib/presentation/features/narrative/narrative_artwork_image.dart` charge avec repli et protège le changement de projet ; `lib/presentation/features/narrative/narrative_overview_landing.dart`, `_content.dart`, `_side.dart` et `_search.dart` placent la bannière, les cartes et les miniatures ; `lib/presentation/features/narrative/narrative_story_pane.dart` et `_overview.dart` raccordent le port ; `lib/presentation/shared/widgets/buttons/studio_action_card.dart` accepte une miniature. `test/support/ui05_narrative_fixture.dart`, `_port.dart`, `test/narrative/narrative_artwork_adapter_test.dart` et `test/presentation/ui05_narrative_artwork_test.dart` couvrent la lecture, les replis, le projet actif, les cartes de scènes et leur destination. Le diff Git et ces sources donnent les lignes précises.

Passes séparées : **Audit/architecture** — images de présentation sans nouveau champ métier ; **Implémentation** — cinq images et lecture bornée au projet ; **Tests** — lecture réelle, absence, identifiant invalide, changement de projet et ouverture de scène ; **Build/validation** — analyse, architecture et build réussis ; **Critique** — aucun contenu narratif inventé, seulement quatre scènes illustrées, et pas de validation native interactive. La parité MCP ne change pas : aucune commande auteur ni modèle canonique n’a été ajouté. La manipulation native n’a pas été réalisée, faute d’entrée de test Marionette dans cette application.

Vérifications de cette passe : `flutter analyze lib test/presentation/ui05_narrative_artwork_test.dart test/narrative/narrative_artwork_adapter_test.dart` → `No issues found!` ; groupe UI05 et architecture → **27 tests réussis**, exit 0 ; `flutter build macos --debug --no-pub` → `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app`, exit 0 ; lecture directe des cinq PNG par `LocalNarrativeAdapter` depuis le vrai projet → cinq réponses non nulles ; `dart format --output=none --set-exit-if-changed` → 0 fichier changé ; `git diff --check` → exit 0. Les originaux du Train restent externes à Git ; leurs copies dans `artwork_train/` sont le matériel versionné. Aucun commentaire de code, aucune écriture Notion.

Avant le commit, sur la même source finale : `flutter analyze --no-pub` → `No issues found! (ran in 6.6s)`, exit 0 ; `flutter test --no-pub --concurrency=2 --reporter=compact` → `08:12 +899 ~2: 2 skipped tests. All other tests passed!`, exit 0. Les deux tests ignorés requièrent la copie externe explicitement prévue ; aucune réussite n’est revendiquée pour eux. Les journaux sont ajoutés à `verification.txt`.

## Finition des cinq raccordements UI05 — 23 septembre 2026

État initial de cette intervention : `main` à `2c9d162ae`, arbre propre. Le mandat joint a été lu comme spécification, avec sa maquette 01 ouverte puis comparée aux vrais widgets. Audit initial ciblé : le retour Carte conservait l’outil armé ; la bibliothèque conservait un détail masqué par les filtres ; deux actions du bandeau ouvraient une bibliothèque au lieu de créer ; le panneau de vérification était fixe ; la galerie et les résultats construisaient toutes les lignes. Les deux premiers défauts ont été reproduits par tests avant correction. Aucune modification des projets originaux, de Carte hors son raccourci UI05, des moteurs ou de Notion.

La navigation de consultation vers Carte sélectionne désormais l’outil, désarme le déplacement en attente et invalide les gestes uniquement après activation courante et réussie. La bibliothèque utilise les mêmes prédicats pour afficher les résultats et réconcilier sa sélection : une cible masquée laisse un détail neutre, une cible visible reste sélectionnée, les sessions et brouillons demeurent intacts. L’étape est qualifiée par son histoire dans le détail, les cartes et la recherche. Les quatre actions du bandeau mènent à la création d’histoire, de scène, d’événement et à UI13 ; scène et événement passent par leurs propriétaires et restent des brouillons jusqu’à l’enregistrement explicite. Le résumé UI13 lit le contrôleur existant, avec état sans rapport, contrôle en cours ou échoué, fraîcheur, compteurs, périmètre, quatre dimensions et limites/exclusions. La galerie borne ses aperçus à six histoires, annonce le reste et la recherche monte seulement les lignes visibles ; sa position survit au retour d’un éditeur.

Zones du diff, sous `apps/avelune_studio/` : `lib/presentation/features/map_workspace/workspace_story_binding.dart` contient le seul désarmement Carte ; `workspace_screen_body.dart` et `workspace_secondary_content.dart` transmettent le propriétaire UI13. `lib/presentation/features/narrative/narrative_story_pane.dart`, `narrative_story_pane_creation.dart` et `narrative_story_pane_overview.dart` raccordent les créations et le rapport. `narrative_overview_view_state.dart`, `narrative_overview_content.dart` et `narrative_overview_detail.dart` réconcilient les filtres et le détail. `narrative_overview_landing.dart`, `narrative_overview_landing_content.dart`, `narrative_overview_landing_search.dart` et `narrative_overview_landing_side.dart` portent les quatre accès, la galerie bornée, la recherche paresseuse et le résumé UI13. `test/presentation/ui05_narrative_overview_landing_test.dart`, `ui05_narrative_overview_collection_test.dart`, `ui05_narrative_overview_navigation_test.dart`, `ui05_verification_summary_test.dart` et `ui05_narrative_artwork_test.dart`, avec `test/support/ui05_narrative_fixture.dart` et `ui05_narrative_port.dart`, couvrent les parcours dans le véritable workspace, la relecture indépendante, les 1 000 résultats, les lectures de médias et les quatre tailles. Les découpages de source et de test respectent la limite de 300 lignes de l’architecture.

Les tests existants `test/dialogues_ui09_navigation_test.dart`, `test/presentation/ui06_scene_navigation_test.dart`, `test/support/map_host_fixture.dart`, `test/support/ui07_journey_driver.dart` et `test/support/ui08_journey_driver.dart` passent désormais par l’accès secondaire « Voir tous les documents » avant leurs éditeurs. Leurs assertions métier restent inchangées. Le test de création UI05 ouvre explicitement une ancienne scène et un ancien événement avant d’annuler puis de confirmer chaque nouvelle création.

Captures des widgets Flutter réels, sur fixture temporaire recevant des **copies** des illustrations du Train suivies dans ce rapport : [1536 × 1024](captures/ui05-finition-1536.png), [1440 × 900](captures/ui05-finition-1440.png), [1280 × 800](captures/ui05-finition-1280.png), [1024 × 640 à 150 %](captures/ui05-finition-1024-150.png). La composition garde le bandeau, la galerie et la colonne de reprise de la maquette ; les documents, quantités et états affichés viennent de la fixture. À 1024, la page devient déroulante sans débordement. Ces captures ne valent pas essai natif interactif ni acceptation visuelle par l’utilisateur.

Passes locales : **audit** des cinq causes et des propriétaires existants ; **tests rouges** pour l’outil resté armé, le détail masqué et la galerie non bornée ; **implémentation** restreinte à UI05 et son raccourci Carte ; **relecture critique** ayant ajouté la clé d’étape qualifiée et la conservation du défilement ; **validation** par formatage, analyse, architecture, tests ciblés, suite complète et build consignés dans `verification.txt`. Aucun sous-agent n’a été sollicité. La parité MCP reste non applicable à ces routes de présentation : aucun acte auteur canonique ou format n’a changé. Les limites conservées sont l’absence de manipulation native et l’impossibilité de déduire la progression d’un joueur depuis les modèles d’auteur.

Sur les sources finales, `dart format` a contrôlé 25 fichiers sans changement ; `flutter analyze --no-pub` a répondu `No issues found!` ; le groupe architecture, UI05 et routes voisines a réussi 38 tests, la création renforcée 3 cas et la fixture visuelle finale avec architecture 9 tests. La suite complète `flutter test --no-pub --concurrency=2 test` a terminé à `09:30 +905 ~2: All tests passed!`, exit 0. `flutter build macos --debug --no-pub` a construit `Avelune Studio.app`, exit 0. Le contrôle Markdown et `git diff --check` ont réussi. Des passes intermédiaires ont relevé dix échecs de routes historiques et de stress, puis une fixture à 302 lignes ; les routes ont été adaptées, la fixture réduite à 300 lignes et le stress a réussi dans la suite finale. Son échec isolé de 20 secondes reste consigné dans le journal, sans test désactivé ni attendu assoupli.

État Git final : les fichiers UI05, ses tests, ce rapport et quatre captures restent non indexés et non committés. Pendant l’intervention, HEAD a avancé indépendamment de `2c9d162ae` à `eb65bd79a` par des commits iOS externes à cette mission ; des modifications Swift et ressources sous `apps/Avelune iOS/` sont également apparues dans l’arbre de travail. Elles ont été laissées intactes et ne font pas partie de cette livraison. Les quatre captures sont des widgets Flutter exécutés avec des copies temporaires des images du Train et le port UI13 réel de la fixture, pas des captures d’une manipulation native. Le test du vrai workspace prouve l’accès UI13 actif, le rapport et sa péremption. La validation visuelle définitive appartient toujours à l’utilisateur.

## Composition desktop stable — intervention Export depuis Accueil

Le cadre commun et la vue d’ensemble Histoire ont été adaptés à une hauteur desktop contrainte. À largeur ordinaire, le bandeau et la recherche restent en place tandis que les collections centrales et la colonne de reprise défilent chacune dans leur zone. À petite taille ou avec texte agrandi, la page autorise un défilement local complet pour conserver les actions accessibles. Ce changement se limite à `narrative_overview_landing.dart` et à sa nouvelle partie `narrative_overview_landing_desktop.dart` ; les propriétaires, recherches paresseuses, créations directes, données et illustrations du Train restent ceux de UI05. Les tests et captures des quatre tailles sont actualisés avec les sources finales de l’intervention Export, sans entrée Export dans la barre latérale : les 2 tests de navigation UI05 passent et leur journal figure dans le rapport AS-EXP-001.
