# M3 — Des personnages à une première histoire jouable

Livraison M3 implémentée et vérifiée : personnages, dialogue à choix, conditions, séquences, histoire, publication et progression dans le vrai runtime. Suite Studio : 229 tests réussis, 2 optionnels ignorés ; analyse, format et build macOS réussis. Validation native interactive non acquise, explicitée ci-dessous. Aucun lot suivant engagé.

## Mandat, audit initial et décisions

Le lot prolonge M1/M2 dans `apps/avelune_studio` : personnage sur la carte, interaction structurée, conditions, scène simple, progression Storyline, publication et vrai playtest. Aucun calque manuel, moteur narratif parallèle, import de sprite complet, combat, inventaire, cloud ou 3D ajouté.

L’[état initial](evidence/initial-state.txt) atteste `/Users/karim/Project/pokemonProject`, branche `main`, HEAD `2abaea0a71033fc6f9d62bf5f8dc01775cb4fbb6`, index et arbre de travail propres. Aucun checkout n’a été effectué. Le fichier de mission a été lu ; l’archive contenant `PROMPT_CODEX.md`, `REFERENCES_VISUELLES.md` et les images n’a pas été trouvée dans les emplacements inspectés. Leur lecture/extraction ne sont donc pas revendiquées. L’implémentation poursuit le mandat écrit et le thème existant ; conformité aux maquettes non certifiée.

L’audit a localisé les documents et historiques M1, la file de mutations et les contrôles de révision M2, les opérations d’entités de `map_core`, le catalogue Character Studio, le compilateur Yarn, les contrats Scene/Event/Storyline et `PlayableMapGame`. Les tests M1/M2 et les tests de dialogue/dispatch/runtime existants servent de non-régression. Les risques principaux étaient la perte de rétention du pinceau, une publication à partir d’une carte disque périmée, les commandes injectées par du texte, les références cassées après undo et le double déclenchement narratif.

L’utilisateur a ensuite confirmé « c’est ça le fichier de prompt » : le Markdown joint constitue donc le brief effectif. Aucun pack d’images n’a été inventé ou attendu comme préalable bloquant.

Décisions issues de cet audit :

- Une seule transition effective de pinceau, avec rétention conservée pendant la main, utilise le cache M2 existant.
- `narrative.publish_document` publie la carte capturée en mémoire et ses dépendances dans une transaction canonique récupérable. La garde du port ressources M2 reste intacte. Il ne s’agit pas d’une visibilité simultanée garantie entre plusieurs fichiers.
- Le dialogue visuel produit du Yarn compilé par le moteur existant. Les littéraux échappés préservent accents, guillemets, retours à la ligne et marqueurs ; la directive de locuteur exploite les métadonnées runtime existantes. Une source ou des métadonnées hors sous-ensemble restent en lecture seule.
- L’option native `activeInLegacyMode` appartient au record concerné. Le mode global du projet est préservé, ainsi que les sources historiques non concernées ; la même source ne déclenche pas les deux systèmes.
- Les scènes utilisent les conséquences natives, et des actions Cinematic natives pour orientation/attente. Les étapes d’histoire restent des Storylines ; leur exécution modifie l’état de jeu isolé, pas leur statut éditorial.
- Les consignes directes du mandat et d’`AGENTS.md` interdisent les nouveaux commentaires : elles prévalent ici sur la demande inverse de `codex_rule.md`. Aucun commentaire/DartDoc/TODO ajouté pour ce lot.

## Zones modifiées et inventaire

L’[inventaire final des sources](evidence/source-inventory.json) liste chaque fichier modifié/créé, ses déclarations principales et les en-têtes de hunks des fichiers suivis. Sources et `git diff` restent les preuves canoniques, sans copie intégrale de code dans le rapport. Les artefacts de preuve sont inventoriés par l’état Git final.

| Zones du dépôt | Modification et effet attendu |
| --- | --- |
| Studio `app/di`, `studio_bootstrap`, `studio_workspace_host` | Injection du port narratif dans la session ; mêmes documents et services entre carte, ressources et histoire. |
| `features/characters/application/character_editing_commands.dart` | Placement, déplacement, duplication et propriétés par opérations natives ; préservation des données avancées et refus de suppression d’une source référencée. |
| `features/narrative/domain`, `dialogue_draft_codec`, `dialogue_editing_controller`, `interaction_edit_session` | Brouillons structurés, projection Yarn, historique, lecture seule sûre ; choix et effets associés modifiés dans une même entrée d’historique. |
| `narrative_interaction`, `narrative_sequence_projection`, `narrative_interaction_reader`, `narrative_editing` | Projection et relecture du sous-ensemble Scene/Event/Cinematic/Storyline, sans nouveau moteur. |
| `narrative_workspace_controller`, `data/local_narrative_adapter` | Capture cohérente, file partagée, révisions de sources indépendantes de l’historique, conflits conservant les brouillons, vérification du reçu et reprise. |
| `map_workspace/application/editable_map_document`, `map_workspace_controller` | Validation avant déplacement des piles undo/redo ; impossibilité d’annuler un PNJ/une zone encore référencé par l’histoire publiée. |
| `presentation/features/characters`, `presentation/features/narrative`, `studio_draft_field` | Palette/inspecteur et formulaires orientés tâches ; répliques, destinations, conditions, séquences et histoire. Listes paresseuses, navigation depuis les étapes et variantes prioritaires. |
| `presentation/features/map_workspace`, `resources/resource_brush_selection` | Gestes PNJ/zone, distinction des sélections, navigation, commandes, état de vue, panneau compact et transition de pinceau. |
| `platform/rendering/studio_*`, `map_runtime` authoring renderer | Prévisualisations des vrais sprites, ressources demandées et notifications ciblées ; pas de simulation complète dans l’éditeur. |
| `platform/playtest/studio_playtest_view`, `studio_playtest_session` | Vrai jeu, nouvelle partie/reprise explicites, dépôt de sauvegarde en mémoire isolée et retour dans le même éditeur. |
| `map_authoring` façade narrative, `NarrativeDocumentActions`, dispatcher, parity | Publication sémantique discoverable via API/JSONL/MCP ; validation, compilation et journal existants. |
| `map_core` Yarn/runtime dialogue et modèles/opérations d’autorité narrative | Littéraux/locuteur sûrs ; opt-in par source historique conservé lors des opérations natives. |
| `map_runtime` snapshot narratif, interactions et `PlayableMapGame` | Consommation réelle de l’autorité ciblée et politique de répétition ; protection du fallback historique. |
| Tests Studio, `map_core`, `map_authoring`, MCP ; `tool/create_example_project.dart` | Régressions, fixtures autonomes, parcours exécutés et import de personnages d’exemple sans toucher aux originaux. |

## Preuves exécutées

Chaque lien de résultat a un fichier `.json` voisin contenant l’argv exact, le répertoire de travail, les heures, le code de sortie et les processus possédés. Les comptes ci-dessous se recouvrent : ne pas les additionner pour annoncer un total unique.

| Commande / périmètre | Résultat frais et preuve |
| --- | --- |
| Studio : `flutter test --no-pub test/presentation/brush_retention_transition_test.dart` | `+1: All tests passed!` — [brush-final](evidence/brush-final.txt). |
| Studio : `flutter test --no-pub test/characters test/terrain_canvas_test.dart` | `+10: All tests passed!` — [characters-final](evidence/characters-final.txt). |
| Studio : codec + publication réelle | `+9: All tests passed!` — [narrative-verified](evidence/narrative-verified.txt), [commande](evidence/narrative-verified.json). |
| Studio : édition + codec | `+9: All tests passed!` — [narrative-editing](evidence/narrative-editing.txt), [commande](evidence/narrative-editing.json). |
| Studio : garde d’historique | `+2: All tests passed!` — [narrative-history](evidence/narrative-history.txt). |
| Studio : projection/relecture native | `+3: All tests passed!` — [runtime-projection-verified](evidence/runtime-projection-verified.txt). |
| Studio : recette dans `PlayableMapGame` | `+1: All tests passed!` — [runtime-story-captures-v2](evidence/runtime-story-captures-v2.txt), [commande](evidence/runtime-story-captures-v2.json). |
| `map_core` : dialogue/portraits | `+9: All tests passed!` — [narrative-core-regression](evidence/narrative-core-regression.txt). |
| `map_core` : autorité, codecs, activation/configuration | `+96: All tests passed!` — [runtime-core-verified](evidence/runtime-core-verified.txt), [commandes](evidence/runtime-core-verified.json). |
| `map_gameplay` : table de dispatch existante | `+6: All tests passed!` — [runtime-gameplay-regression](evidence/runtime-gameplay-regression.txt). |
| `map_runtime` : dialogue/dispatch existants | `+37: All tests passed!` — [runtime-native-regression](evidence/runtime-native-regression.txt). |
| `map_runtime` : rendu auteur/personnages | `+10: All tests passed!` — [characters-runtime-regression](evidence/characters-runtime-regression.txt). |
| `map_authoring` : `dart test test/domains/narrative/narrative_document_publication_test.dart test/domains/narrative/dialogue_script_authoring_test.dart` | `+8: All tests passed!` — [narrative-jsonl-verified](evidence/narrative-jsonl-verified.txt). |
| MCP : `npm run build`, puis `POKEMAP_TEST_DART=/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart node --import tsx --test test/studio_narrative_publication.test.ts` | Build code 0 ; test réel stdio `pass 1`, `fail 0` — [build](evidence/narrative-mcp-build.txt), [MCP](evidence/narrative-mcp-live.txt). |
| Analyses ciblées Studio / authoring / runtime | `No issues found!` — [narrative-final-analysis](evidence/narrative-final-analysis.txt), [narrative-authoring-clean](evidence/narrative-authoring-clean.txt), [runtime-analysis-verified](evidence/runtime-analysis-verified.txt), [runtime-shared-analysis](evidence/runtime-shared-analysis.txt). |

Les tests de publication vérifient les vrais fichiers : carte sale conservée, édition arrivée après le snapshot restant sale, réouverture, conflit externe de carte/source, interruption après promotion, reprise réelle et refus d’écrasement lorsqu’une reprise est bloquée. Les tests d’édition prouvent le maintien des brouillons après échec, l’absence d’enregistrement à la consultation, la protection des sources avancées et l’absence de retour à une ancienne révision de source après undo.

La recette runtime exerce refus sans progression, acceptation, conversation dans l’ordre inverse, passage par la voyageuse, conclusion, répétition et zone à usage unique. Sauvegarde/rechargement du jeu et réouverture des données auteur sont des vérifications distinctes ; aucun résultat attendu n’est injecté directement dans l’état de progression pour remplacer les interactions.

Les sorties intermédiaires ne sont pas des succès finaux. La [reproduction du défaut de pinceau](evidence/brush-red-verified.txt) est conservée. La [première suite globale](evidence/studio-suite-final.txt) échouait uniquement sur la limite de taille de deux fichiers ; la construction du renderer et les responsabilités de session ont été réparties dans les fichiers concernés. Une assertion de test incorrecte sur un choix sans outcome a aussi été corrigée. Les sorties finales ci-dessous établissent l’état livré ; les compilations provisoires répétées ne sont pas conservées.

## Parité, captures et vérifications finales

L’action est exécutée directement par le port Studio, puis par JSONL et un serveur MCP réellement lancé en stdio : découverte, plan sans écriture, application, relecture de la source et de la carte, mode narratif inchangé. Ce succès ne certifie pas la connexion MCP configurée dans la session Codex. Les gestes PNJ réemploient les opérations natives ; les transports existants d’entités restent distincts de la nouvelle publication coordonnée.

Six captures réellement exécutées hors écran et examinées : [personnages et inspecteur](evidence/screenshots/01-carte-personnages.png), [Histoire et liens](evidence/screenshots/02-histoire.png), [dialogue à choix](evidence/screenshots/03-dialogue-choix.png), [conditions et séquence](evidence/screenshots/04-conditions-sequence.png), [choix dans le vrai runtime](evidence/screenshots/05-runtime-choix.png), [conclusion](evidence/screenshots/06-runtime-conclusion.png). Les sprites de la fixture sont des dessins de test, pas une validation artistique. Les petits raccourcis Flame sans police explicite apparaissent encore sous forme de blocs dans les captures hors écran ; les répliques et choix sont lisibles. Aucune mesure de FPS ni certification de clic natif n’en est déduite.

| Vérification globale | Résultat final |
| --- | --- |
| Suite Studio complète et non-régressions M1/M2 | `flutter test --no-pub` : `+229 ~2: All tests passed!` — [sortie](evidence/studio-final.txt). Deux tests nécessitant `AVELUNE_PROJECT_COPY` ignorés ; le gros atlas a été rejoué séparément, la capture Train optionnelle ne l’a pas été. |
| Gros atlas sur copie isolée, lecture seule | `flutter test --no-pub test/infrastructure/studio_large_atlas_test.dart` avec `AVELUNE_PROJECT_COPY` : `+1: All tests passed!`, 329 atlas indexés, 4096×5280, 1 lecture/1 décodage, 86 507 520 octets résidents — [preuve](evidence/large-atlas-regression.txt). Budget estimé, pas mesure RSS. |
| Parcours auteur et captures | `flutter test --no-pub test/presentation/m3_authoring_journey_test.dart test/m3_story_runtime_test.dart test/m3_conditions_widgets_test.dart` avec `AVELUNE_CAPTURE_DIR` : `+3: All tests passed!` — [preuve](evidence/captures-final.txt). Inspection → texte littéral → annulation fermeture → publication → histoire → variante conditionnelle. |
| Largeur 1024×640, texte agrandi et pinceaux | [Parcours compact](evidence/characters-compact-verified.txt) : `+3`, [personnages/portraits/pinceaux](evidence/characters-and-portraits-final.txt) : `+14`, [zones persistantes](evidence/characters-zone-overlay-green.txt) : `+3`, tous réussis. |
| Format et analyse globale Studio | `dart format --output=none --set-exit-if-changed lib test tool` : `Formatted 186 files (0 changed)` — [format](evidence/format-final.txt). `flutter analyze --no-pub` : `No issues found!` — [analyse](evidence/analysis-clean.txt). |
| Build macOS | `flutter build macos --debug --no-pub` : `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app` — [build](evidence/macos-final.txt). |
| Essai natif identifié | Nouveau binaire lancé, VM Service disponible. Premier attachement CUA : `AXError.cannotComplete` ; unique réattache sur l’ancienne fenêtre Train, donc aucune interaction. Seule l’instance M3 possédée a été arrêtée. [Trace](evidence/native-observation.txt), [lancement](evidence/native-corrected-build.txt). |
| Connexion MCP configurée | Échec frais `worker.exited`, code 78 — [trace](evidence/configured-mcp.txt). L’action fonctionne dans le serveur stdio réellement lancé pour le test distinct ci-dessus. |
| Ancien éditeur | `flutter test --no-pub test/editor_shell_page_smoke_test.dart --plain-name "root app can disable background startup effects"` depuis `packages/map_editor` : `+1: All tests passed!` — [preuve](evidence/legacy-editor-startup.txt). Aucun fichier de l’ancien éditeur modifié. |
| État Git final et hygiène | Branche/HEAD inchangés, index vide, modifications M3 laissées dans l’arbre — [état final](evidence/final-state.txt). Un seul nouveau Markdown de rapport ; [hygiène](evidence/markdown-hygiene.txt). Aucun Git write/Notion/original modifié. |

## Verdict des passes et limites

| Passe / responsable | Verdict à ce stade |
| --- | --- |
| Audit / architecture — root et trois agents bornés | Réemploi identifié ; frontière carte sale/ressources et pureté des couches traitées. Références visuelles absentes, non inventées. |
| Implémentation personnages — `m3_characters` | Commandes/rendu/palette/inspecteur intégrés, sélection superposée, zones persistantes ; tests ciblés et suite finale verts. |
| Implémentation narrative / tests — `m3_narrative` | Publication, texte sûr, CAS, reprise, historique et parité exécutés. Les effets de choix orphelins et les imports impurs trouvés en critique ont été corrigés. |
| Runtime / tests — `m3_runtime` | Recette conditionnelle exécutée dans le moteur réel, persistance de jeu isolée et régressions natives vertes. |
| Build / validation — root | Suite, analyse, format, macOS et démarrage de l’ancien éditeur vérifiés ; interaction native limitée par le pilote. |
| Critique finale — agents puis root | Aucun P1/P2 confirmé restant sur publication/fermeture/historique. [Gardes de fermeture et test](evidence/runtime-workspace-guards-final.txt) : 7 tests réussis. Source avancée et navigation erronée corrigées ; la suite finale couvre les liens d’Histoire. |

Limites conservées : conditions visuelles booléennes et sous-ensemble de scènes explicite ; narration avancée préservée sans prétendre l’éditer ; sauvegardes de test en mémoire, réinitialisées par « nouvelle partie », non assimilées à une sauvegarde personnelle durable. La publication récupérable peut nécessiter une reprise lorsque des fichiers ont été promus ; un conflit externe bloque alors la réussite et conserve le journal. Les limites M2 sur topologies supplémentaires, bordures et anciens atlas sans métadonnées ne sont pas élargies ici.

Le périmètre touche FG-081, FG-082, FG-088, FG-093 et FG-094 : **contribution PARTIAL**, sans clôture de ces lots historiques. M3 ne couvre pas toutes leurs conditions, commandes ou familles de modèles. Aucun statut de roadmap ou Notion modifié. La couverture de sauvegarde M3 complète les contrats existants sans annoncer une nouvelle certification globale FG-014.

Auto-critique : la recette runtime complète est construite par les mêmes modèles/projections/transactions, puis jouée par les interactions réelles ; le test UI exerce séparément l’édition depuis l’inspecteur, la publication et la création de variante/histoire. Il ne reconstitue pas toute la fixture à la souris. Les sources avancées restent volontairement limitées à la consultation, le pilote natif et le MCP configuré restent non certifiés. Les tests prouvent leurs couches respectives, pas une acceptation visuelle manuelle ni des performances natives.

## Lancement

Depuis la racine : `cd apps/avelune_studio && flutter run -d macos --no-pub`.

Exemple autonome : depuis `apps/avelune_studio`, exécuter `dart run tool/create_example_project.dart`, puis ouvrir le dossier temporaire indiqué. Utiliser exclusivement cet exemple ou une fixture dédiée pour la recette. Aucun projet, sprite ou fichier de sauvegarde original ne doit être écrit.
