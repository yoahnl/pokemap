# Risques de performance et mesures à préparer

**Aucune mesure de latence, de débit ou de mémoire processus n’a été réalisée. Aucun benchmark ni instrumentation permanente ajouté.** Ce document prépare AS-PERF-001 ; il ne l’exécute pas. Les constats portent sur le code au SHA du README. La longueur d’un fichier n’est jamais utilisée comme preuve de lenteur.

## Points d’observation

| Déclencheur | Chemin et travail observés | Portée | Preuve disponible / qualification | Mesure à prévoir |
|---|---|---|---|---|
| Ouvrir un projet | `ProjectOpenService.openProject`, `packages/map_authoring/lib/src/workspace/project_open_service.dart:61-127` : autorisation, lecture/inspection manifeste ; isolate au-delà de 1 MiB | Ouverture projet | Code lu ; coût non mesuré | Temps jusqu’à première carte éditable, bytes lus, inspection UI/isolate ; séparer tâches secondaires. |
| Query authoring | `AuthoringReadApi.queryProject`, `src/api/authoring_read_api.dart:123-131` : charge un snapshot, puis projection | Potentiellement projet, pas uniquement carte affichée | Code lu ; politique/cache présents | Nombre de lectures et ressources inspectées pour query chaude/froide ; coût sérialisation projection. |
| Planning puis apply | `LocalMapAuthoringMutationApi`, `src/api/local_map_authoring_mutation_api.dart:572-591,622-682` : cache session au plan, validation canonique à l’apply | Snapshot et ressources de la transaction | Observation ; contrôle nécessaire, risque si appelé par point de pinceau | Coût séparé plan/apply, nombre de probes/hashes, file de commits et latence confirmation. |
| Sauvegarder une petite modification | `SemanticMapActionContext.draft`, `src/domains/maps/semantic_map_action_support.dart:103-151` : validation projection et sérialisation carte entière ; transaction stage/flush/promotion | Carte entière en bytes même si delta métier petit | Code lu ; risque d’allocations/I/O sur grande carte, non mesuré | Bytes temporaires et écrits, temps JSON/validation/flush, taille du journal et fréquence des commits. |
| Activer une autre carte | `EditorNotifier.activateMap`, `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:3092-3296` : garde dirty, chargement document, adoption et reset d’état | Carte/session active | Code lu ; aucune garantie générale d’activation chaude sans reload démontrée | Alternance A→B→A : lectures, notifications, décodages, frames vides, préservation des documents sales. |
| Peindre | `editor_notifier.dart:8655-8742` : buffer transitoire, commit et résolution dérivée à fin de stroke ; Smart Tiles async à `8831-8860,9180-9210` | Cellules et couches touchées, puis éventuelle carte sérialisée | Séparation geste/commit observée ; batch tests lus | Durée par event/frame et fin de geste ; allocations/copies, taille delta, rejouements et longueur de file. |
| Sélectionner un objet en scène dense | `map_canvas_object_hit_test.dart:119-202`, sous `features/editor/application/` : index de définitions construit et candidats parcourus | Définitions et objets des passes examinées | Observation ; risque de travail répété, pas ralentissement prouvé | Temps hit-test versus candidats totaux/visibles ; répétition de l’index et résultat au clic cyclique. |
| Mettre à jour le document ou naviguer | `MapCanvas` selectors `ui/canvas/map_canvas.dart:815-817`; `MapGridPainter.shouldRepaint`, `ui/canvas/map_canvas/map_grid_painter.dart:3441-3531` : compare de nombreux inputs | Widget et painter ; culling/pictures limitent déjà certains travaux | Code lu ; reconstruction globale systématique non démontrée | Nombre de rebuilds/repaints, champs ayant déclenché, chunks/pictures invalidés ; selection-only doit rester sans dirty. |
| Tester égalité/changement d’état | État `features/editor/state/editor_state.dart:65-151`, `shouldRepaint` ci-dessus ; modèles générés à caractériser séparément | Collections et propriétés possiblement larges | **Hypothèse à tracer** : coût de comparaisons profondes non établi par cet audit | Compter appels/tailles et allocations ; vérifier identity/revision avant de proposer une substitution. |
| Charger une image / changer de ressource | `ui/assets/editor_image_cache.dart:120,336-415,570-703` : budget, empreinte taille/mtime, leases, éviction et retirement après frame | Cache images et consommateurs vivants | Code lu ; décodage répété systématique non prouvé | Hit/miss et déduplication concurrente par projet/révision/variante ; bytes décodés résidents + encore référencés. |
| Recevoir un résultat tardif | `editor_notifier.dart:2094,3243-3249,3731` et `map_canvas.dart:568,760,962` : identité/lease et génération de requête | Session documentaire ou image demandée | Garde-fous observés ; couverture de tous les chemins non certifiée | Changement A→B pendant lecture/décodage/commit ; vérifier non-adoption, annulation, libération et absence de modification perdue. |
| Valider explicitement le projet | `AuthoringReadApi.validateProject`, `src/api/authoring_read_api.dart:145-177` : snapshot, index de références, cohérence catalogues et boucle des cartes | Projet | Travail global explicite observé | Temps par catégorie, ressources réutilisables par révision ; prouver absence de cet appel dans les gestes courants. |
| Accumuler undo/redo | `application/services/map_history_coordinator.dart:7-9,313-355` : 100 entrées, 16 MiB estimés, checkpoint/25 ; journal authoring distinct | Histoire locale et persistante | Paramètres de code, pas mesure mémoire | Bytes réels des snapshots/deltas, partage structurel, eviction, pause au checkpoint et restauration. |
| Pression sur cache snapshot | `packages/map_authoring/lib/src/workspace/project_snapshot_cache.dart:16-44,113-149,226-269` : cache session sans inspection ; canonique revalide ; adoption compare base/bytes | 2 projets, 64 MiB authoring + 256 MiB blobs par défaut | Code lu ; plafonds internes seulement | RSS/Dart/native séparés, coût probes canonical, références retenues hors cache ; aucune éviction de document dirty. |

Dans les lignes `src/...` d’authoring, le préfixe est `packages/map_authoring/lib/`. Dans les chemins editor abrégés, le préfixe est `packages/map_editor/lib/src/`. Les bornes/chiffres ci-dessus sont ceux des paramètres observés, pas des garanties de performance.

## Propriétaires et invalidation à définir

| État / ressource | Autorité attendue dans Studio | Invalidation / risque |
|---|---|---|
| Document auteur sale | Session de travail | Jamais évincé comme un cache. Sauvegarde/récupération/abandon explicite avant libération. |
| Révision disque et snapshot propre | Adaptateur I/O + cache snapshot | Contrôle canonique à la publication ; le snapshot de preview peut devenir obsolète. |
| Buffer de geste | Outil actif associé à session/carte | Annuler lors changement de cible ; commit unique, ne pas rejouer sur autre carte. |
| Sélection / inspection / caméra | Présentation | Conserver le contexte de retour ; ne pas déclencher sauvegarde ni rechargement global. |
| Images / miniatures / pictures | Gestionnaire graphique avec références explicites | Clé projet/session/ressource/révision/variante ; libération sûre après dernier consommateur ; budget en octets. |
| Index de recherche / spatial | Projection dérivée versionnée | Mettre à jour les entrées touchées ; ne pas devenir source métier indépendante. |
| Tâche de fond | File bornée de session | Priorité interaction/visible/sauvegarde avant préchargement ; abandon des résultats obsolètes ; `async` seul ne garantit pas du parallélisme CPU. |

`NarrativeDocumentSession<T>` (`packages/map_editor/lib/src/application/services/narrative_document_session.dart:243`) possède également son cycle d’édition/sauvegarde et expose `ChangeNotifier`. Ce n’est pas un contrat de domaine pur réutilisable tel quel. L’inventaire est important pour éviter une nouvelle copie concurrente du document lorsqu’un outil narratif s’ouvre depuis la carte.

Aucune purge globale de tous les caches à chaque navigation n’a été démontrée. Ne pas transformer la règle produit « ne pas purger » en diagnostic inventé sur l’existant. Rechercher et tracer les invalidations de la tranche effectivement reprise avant de proposer une optimisation.

## Protocole à préparer pour AS-PERF-001

Les fixtures S/M/L et objectifs p95/p99 de la page Notion Fluidité sont **des propositions à qualifier**. Fixer versions SDK/OS, CPU/GPU/RAM, résolution, Hz, mode d’alimentation, taille/octets des atlas, couverture visible, animations et nombre d’objets. Séparer cache froid, cache chaud et document modifié. Aucun chiffre de délai n’est validé ici.

Mesures prioritaires :

1. Entrée utilisateur → première image correcte : sélection, devant/derrière, inspection. Ne pas mesurer seulement la méthode Dart.
2. A→B→A et retour d’un panneau contextuel : compteurs de lectures/décodages, requêtes et invalidations ; interface correcte à chaque frame.
3. Traits courts/longs et drag de gros décor : UI/raster séparés, nombre de cellules réellement visitées, buffer et sérialisation au commit.
4. Sauvegarde d’une modification minimale sur cartes de plusieurs tailles ; conflits et échecs disque conservant le travail.
5. Changement de projet pendant lecture/image/commit ; résultat tardif rejeté et ressources libérées.
6. Plateau mémoire après échauffement, pression et longue alternance : documents sales, cache propre, historique, Dart/native/GPU distincts.

Prévoir des assertions déterministes de non-rechargement et de ciblage en plus des traces profile. Les journeys longues restent locales et opt-in ; aucune nouvelle dépendance CI coûteuse n’est proposée. Les seules exécutions de cet audit sont listées dans le README, sans benchmark.
