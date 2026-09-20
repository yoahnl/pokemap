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
