# AS-UI-010 — Cinématique sur carte

## Résultat et périmètre

Éditeur UI10 ajouté à Avelune Studio : bibliothèque des cinématiques sur carte, carte réelle, acteurs liés, positions initiales, destinations, chemins manuels, timeline séquentielle manipulable, inspecteur, lecture isolée, transactions et retours contextualisés. C1 utilise le brouillon de dialogue courant plutôt qu’une ancienne session propre.

La validation visuelle de Yoahn reste ouverte. Aucune écriture Git ou Notion. Aucun projet personnel original modifié. Les scénarios de validation utilisent des fixtures isolées. Aucun éditeur de cinématique de présentation ajouté.

État initial : branche `main`, HEAD `6e67f71605e2aad98671889be5078e0cef511a6a`, arbre propre. Les changements restent locaux, sans commit ni push.

## Audit initial et interprétation du pack

Le pack UI10, ses références/annexes, les guides du Narrative Kit et la maquette 06 ont été lus ; l’image a été ouverte avant l’implémentation. UI05–UI09 fournissent déjà le cadre, les sessions partagées, les transactions et les retours de navigation. Le modèle `CinematicAsset`, ses opérations d’édition et les projections de preview existent dans map_core ; les transactions existent dans map_authoring ; les rendus de carte/personnage et le lecteur réel existent dans map_runtime.

Les risques identifiés étaient la conversion destructive des scènes complètes, deux brouillons concurrents pour une même cinématique, les réponses asynchrones tardives, la sauvegarde d’une saisie encore focalisée, les références de repères partagés et la confusion entre viewport de travail et caméra du jeu. L’ancienne résolution d’un dialogue pouvait préférer une session propre périmée : le test C1 a d’abord reproduit ce défaut.

La timeline reste séquentielle, selon les durées/ordres canoniques. Les pistes colorées classent les actions ; elles n’introduisent ni chevauchement exécutable ni scheduler parallèle. Les actions de quête/variable et les formes d’onde illustratives du dessin ne sont pas inventées. Aucun nouveau format narratif, moteur de lecture ou changement de dépendance/configuration native.

## Accès et parcours

Ouvrir une copie de projet, aller dans **Histoire → Cinématiques**, puis ouvrir ou créer une cinématique sur carte. Depuis UI06, sélectionner un bloc cinématique et utiliser son ouverture dédiée. Le retour retrouve le même document de scène, son bloc et son brouillon ; les origines UI07 et UI08 restent distinctes. L’ouverture d’un dialogue depuis UI10 revient ensuite dans la cinématique, puis dans la scène.

Choisir la carte et un acteur existant dans l’inspecteur, ajouter un déplacement, sélectionner le mode destination puis cliquer dans la carte. Les repères peuvent être déplacés ; leurs usages partagés sont annoncés avant modification. Les chemins manuels restent des données d’auteur canoniques. Le pan/zoom de travail ne crée aucune commande caméra.

Glisser un bloc réordonne la séquence. Glisser sa poignée change une durée réellement supportée. Chaque geste produit une seule entrée d’annulation ; Échap abandonne le geste. La tête de lecture inspecte un instant sans écrire les positions des entités source. Les dialogues et médias conservent leur durée d’aperçu indicative, distincte de leur attente effective au runtime.

Enregistrer traite les saisies focalisées, vérifie les conflits et publie par la transaction canonique. Les cinématiques complètes et les interactions simplifiées sont protégées dans les deux sens. Les réponses obsolètes ne remplacent pas la session courante ; les brouillons restent dans leur contrôleur partagé.

## Réemploi et changements partagés bornés

- Carte : `RuntimeAuthoringMapRenderer`, ressources/cache existants et carte chargée par `EventMapLoader`. Le viewport de peinture est borné à la surface réelle : un RepaintBoundary pouvait auparavant transmettre un clip gigantesque au parcours spatial.
- Acteurs : `RuntimeAuthoringCharacterRenderer` avec orientation, marche et animation personnalisée existantes. Aucune nouvelle découpe de sprites.
- Montage : opérations/projections canoniques de timeline, acteurs, caméra, chemins et playback. Le transport application reste Dart pur ; l’adaptation Listenable appartient à la présentation.
- Audio : extraction du contrôleur média existant vers map_core, réexporté depuis son ancien emplacement encore consommé par map_editor ; adaptateur Flame existant côté plateforme. Ce déplacement évite une dépendance Studio → ancien éditeur.
- Lecture native : le contrôleur média rejetait initialement tout plan contenant une capacité spatiale non prise en charge par son inspection, dont la caméra. Le bouton démarrait puis s’arrêtait immédiatement. La validation porte désormais sur ses seules étapes son/musique/FX ; les diagnostics de médias manquants restent bloquants et le plan temporel n’est pas modifié. Ce défaut a été découvert dans la vraie fenêtre après une première suite complète verte, puis couvert par une régression du bouton avec le port média réellement branché.
- Publication : `cinematic.upsert` reçoit un placement de bibliothèque optionnel, validé et atomique avec l’asset. API directe, JSONL et MCP empaqueté utilisent la même sémantique.
- Runtime : trois lignes dans `PlayableMapGame.onRemove` annulent la lecture avant destruction, afin de ne pas laisser continuer la scène après fermeture. La restauration reste celle du moteur existant.

## Comparaison visuelle

La composition reprend bibliothèque à gauche, carte au centre, timeline inférieure et inspecteur à droite. Les accents distinguent acteurs/déplacements, caméra, dialogues et médias. Le cadre et les logos Avelune sont conservés.

Après ouverture de la première capture réelle et comparaison à la maquette, la part de carte a été ramenée à 48 % du panneau central, la timeline se cadre automatiquement sur la séquence, les pistes utilisent les couleurs sémantiques, les graduations une police lisible et la bibliothèque de vraies miniatures de carte. À 150 % de texte, les panneaux se replient et la palette basse adapte sa hauteur. Les acteurs, arbres et sol sont ceux de la fixture réellement chargée ; aucun morceau de maquette n’est utilisé comme interface.

Les widgets capturés hors écran et les frames du vrai GameWidget sont des preuves différentes d’une manipulation native. La fenêtre macOS a été manipulée pour naviguer et sélectionner un déplacement avant le dernier correctif média. Le pilote CUA a ensuite échoué sur la nouvelle instance ; la lecture native après ce correctif n’est pas certifiée.

Captures accessibles :

- [Composition et déplacement sélectionné, widgets réels](captures/ui10-01-final-selected-move.png).
- [Fenêtre native macOS, sélection et inspecteur](captures/ui10-native-selected-move.png).
- [Destination après pan/zoom, tuiles 16 px](captures/ui10-02-destination-16.png) et [32 px](captures/ui10-02-destination-32.png).
- [Poignée de durée](captures/ui10-03-duration-drag.png) et [réorganisation temporelle](captures/ui10-04-order-drag.png).
- [Frame spatiale intermédiaire](captures/ui10-preview-movement.png), [caméra indicative](captures/ui10-preview-camera.png), [fondu](captures/ui10-preview-fade.png).
- [État après arrêt, temps revenu à zéro](captures/ui10-preview-stopped.png) et [inspecteur de caméra](captures/ui10-inspector-camera.png).
- [Compact 1024 × 640, texte 150 %](captures/ui10-responsive-1024.png).
- [Retour depuis l’origine UI07](captures/ui10-return-stories.png) et [UI08](captures/ui10-return-events.png).
- [Mouvement dans le vrai GameWidget](captures/runtime-02-movement.png) et [scène continuée, cadrage restauré](captures/runtime-05-scene-continued.png).

La capture « early-composition » est produite par un test rejouable et peut être actualisée à sa relance ; elle n’est pas présentée comme une archive immuable avant/après. Les images « native-…-before-fix » documentent l’échec natif découvert lors de la vérification, pas une lecture réussie.

## Vérifications et preuves

Les fichiers `logs/*.json` donnent la commande exacte, le code de sortie et les processus enfants possédés par chaque lancement ; `logs/*.txt` conservent la sortie. Les premiers journaux rouges sont conservés pour la reproduction et ne sont pas présentés comme le verdict final.

Les groupes de tests se recouvrent et ne doivent pas être additionnés. Une suite exploratoire interrompue par SIGINT a renvoyé 0 malgré son interruption : `studio-tests-interrupted-before-harness-freeze.*` n’est pas une preuve de réussite.

| Vérification | Résultat acquis | Journal |
| --- | --- | --- |
| C1 avant correction | 1 échec reproduit | `logs/c1-red.txt` |
| C1 après correction | 1 test passé | `logs/c1-green.txt` |
| Contrôleurs, coexistence, UI09 et histoire | 98 tests passés | `logs/application-current.txt` |
| Animation, duplication, inspecteur | 9 tests passés | `logs/animation-and-duplicate.txt` |
| Adapter/transactions et protections UI07/UI08 | 15 tests passés | `logs/cinematic-adapter-final.txt` |
| API canonique directe et JSONL | 21 tests passés | `logs/cinematic-canonical.txt` |
| Parité d’authoring | 18 tests passés | `logs/authoring-parity.txt` |
| MCP empaqueté | 83 tests passés | `logs/mcp-test.txt` |
| Publication cinématique avec placement via MCP | 1 test passé | `logs/mcp-atomic-placement.txt` |
| Réemploi du contrôleur média par l’ancien éditeur | 5 tests passés | `logs/editor-media-reuse.txt` |
| Transport/médias et destruction | 6 tests passés | `logs/cinematic-media-dispose-final.txt` |
| Géométrie 16/32 px et gestes timeline isolés | 3 tests passés | `logs/spatial-gestures-final.txt` |
| Runtime réel + renderer | 2 tests passés | `logs/runtime-renderer-final.txt` |
| Retours imbriqués et gestes timeline | 3 tests pérennes passés ; une préparation temporaire de fixture native également passée | `logs/navigation-timeline-final.txt` |
| Montage caméra + port média, média valide/absent, transport | 12 tests passés après correctif natif | [media-camera-verified.txt](logs/media-camera-verified.txt) |
| Régression ancien éditeur après correctif caméra/médias | 5 tests passés | [editor-media-camera-verified.txt](logs/editor-media-camera-verified.txt) |
| Vrai bouton Lecture avec port média + fenêtres/text scale | 4 tests passés | [ui10-play-fixed-targeted.txt](logs/ui10-play-fixed-targeted.txt) |
| Miniature A → B en attente/absente/supprimée | 1 test passé, après reproduction rouge | [thumbnail-stale-final.txt](logs/thumbnail-stale-final.txt) |

Commandes principales, depuis `apps/avelune_studio` :

```sh
flutter test --no-pub --reporter expanded
flutter analyze --no-pub
flutter build macos --debug --no-pub
flutter run -d macos
```

Dans `packages/map_authoring` :

```sh
dart analyze
dart test test/domains/narrative/cinematic_atomic_placement_test.dart test/domains/narrative/cinematic_authoring_gate_test.dart test/domains/narrative/cinematic_library_authoring_test.dart test/tooling/jsonl_cinematic_library_flow_test.dart
dart test test/parity/full_authoring_parity_test.dart
```

Dans `tools/pokemap_mcp` : `npm run check`, `npm run build`, `npm test`. Ces trois commandes ont réussi. La tentative du connecteur MCP vivant échoue avec `worker.exited`, code 78 (`logs/live-describe.json`). La certification globale PMCP-085 reste partielle : catalogue complet de 359 actions, mais reçus globaux de transport incomplets ; ce résultat ne devient pas artificiellement vert grâce aux tests ciblés.

### Validation finale

État historique après le premier correctif découvert en natif, avant la réparation de parité du 21 septembre ci-dessous :

- Suite Studio complète : **588 tests réussis, 2 ignorés, 1 échec**. L’échec est le délai d’E/S de 20 secondes de `desktop_workspace_layout_test.dart`, ligne 269, pendant son scénario ligne 184. [Sortie complète](logs/studio-tests-final.txt), [commande et processus](logs/studio-tests-final.json).
- Ce même test, rejoué seul sans aucune modification du code, des assertions ou du délai, passe : **1 test réussi**. [Rejeu isolé](logs/desktop-layout-isolated-final.txt). Une contention pendant la suite est plausible mais non démontrée ; le résultat complet reste déclaré avec cet échec, pas transformé en suite verte.
- Les deux tests ignorés sont les captures d’atlas et du Train conditionnées à `AVELUNE_PROJECT_COPY`. Aucune copie de projet personnel n’a été fournie pour les activer.
- Tous les scénarios UI10 passent dans la suite complète. La suite dédiée couvre 13 tests dans sept fichiers ; après le correctif média, le bouton Lecture et les trois tailles de fenêtre ont été rejoués avec **4 succès**, dont progression après 700 ms réelles puis retour à zéro à l’arrêt.
- **573 fichiers Dart** du Studio et des fichiers partagés concernés sont restés strictement identiques pendant la dernière suite : aucun ajout, retrait ou hash modifié. [Stabilité des entrées](logs/studio-tests-input-stability.json).
- Analyse Studio : **No issues found!**, via `dart analyze`. [Journal](logs/studio-analyze-final.txt). Le contrôleur média partagé passe aussi son analyse ciblée.
- Build final : **✓ Built build/macos/Build/Products/Debug/Avelune Studio.app**, via `flutter build macos --debug --no-pub`. [Journal livré](logs/native-build-delivered.txt).
- Inspection des descendants possédés par la dernière suite : aucun survivant avant le rejeu isolé. Aucun processus d’un autre travail terminé par nettoyage global.
- Contrôle natif final : `timeoutReached -10005` du pilote CUA après reconstruction ; tentative de récupération bornée, aucun changement de SDK ou installation. La capture native prouve la composition/navigation/sélection. Le test de widget prouve le bouton Lecture corrigé ; le GameWidget prouve séparément le moteur réel. [Receipt natif et portée des six hashes auteur inchangés](logs/native-final-receipt.json).
- `git diff --check` : code 0, sortie vide. Aucun fichier source Studio modifié ou nouveau au-delà de 300 lignes. Hygiène Markdown : **1 nouveau Markdown, emplacement canonique**, avec budget explicite de ce rapport unique. [Contrôles](logs/root-hygiene.txt).

Le précédent résultat complet de 586 tests réussis est conservé dans `studio-tests-final-before-native-play-fix.*` ; il précède la découverte native et ne remplace pas le verdict ci-dessus.

Git final : branche et HEAD initiaux inchangés ; modifications locales non indexées et fichiers nouveaux du lot, sans commit/push. L’inventaire de code ci-dessous et [le statut détaillé](logs/git-status-final.txt) rendent ces changements visibles. Aucun changement Notion, selon l’instruction explicite du lot.

## Fixtures et intégrité

Les tests créent des répertoires temporaires isolés. La fixture reprend des médias déjà présents dans le dépôt : sol/chemin/arbres du jeu de Selbrume et atlas d’acteur de fixture. Deux cartes et des acteurs homonymes permettent de vérifier les liaisons. Aucun média de fixture n’est ajouté aux assets de production.

Les tests vérifient les octets des cartes avant/après scrub, gestes et publication. Le test runtime joue une scène réelle avec cinématique, déplacement, caméra, fondu et reprise de scène ; il vérifie aussi annulation à la fermeture, restauration et non-consommation de l’événement lors de l’annulation. Les captures de ce test proviennent du vrai runtime Flutter/Flame, exécuté hors écran, pas d’un simulateur de résultats.

Le scénario runtime positif déplace le joueur lié comme acteur, attend la cinématique puis écrit le fait de continuation. Le second ferme le runtime pendant le déplacement : son dispatch interrompu est attendu et les assertions exigent l’absence de continuation/consommation. Les frames intermédiaires ont des octets distincts ; les images de départ et de fin peuvent être identiques parce que la position et la caméra sont restaurées. Ce résultat ne prétend pas certifier toutes les combinaisons de PNJ et de médias.

Les tests de capture réservés à `AVELUNE_PROJECT_COPY` restent conditionnels : aucun projet personnel n’a été fourni pour les activer.

## Passes et critique

- Audit/architecture — passe racine + agent backend : réemploi des contrats, séparation monde/présentation, transactions et imports vérifiés.
- Implémentation — racine pour composition/carte/timeline ; agent coexistence pour sessions/navigation/C1 ; backend pour port/transaction/inspecteur/audio.
- Tests — agent runtime pour vrais gestes, tailles de fenêtre, retours imbriqués et GameWidget ; racine pour transformations et annulation de gestes.
- Build/validation — agents backend et coexistence : build final et analyse réussis ; tous les tests UI10 passent, un timeout d’E/S de la suite complète passe au rejeu isolé sans modification. Le verdict global exact est conservé ci-dessus.
- Critique indépendante — les défauts de flush, diagnostic spatial bloquant, collision des familles, dossier de brouillon, confirmation de repère partagé, snapshot avant suppression et miniature périmée ont été identifiés et traités. L’agent backend ne confirme plus de blocage dans les zones inspectées ; son dernier correctif média passe 12 tests Studio et 5 de l’ancien éditeur. La certification native finale et la validation artistique restent ouvertes.

Le reformatage hors périmètre du gros fichier runtime a été retiré : son diff conserve uniquement l’annulation à la fermeture. Aucun commentaire manuel ajouté, conformément au prompt UI10 qui prévaut sur la suggestion générale du fichier Codex.

Auto-critique : la première suite complète (586 tests) couvrait le transport, la géométrie et les médias séparément, mais son hôte de page n’exerçait pas encore leur branchement complet. Le contrôle natif a révélé cette lacune. Le test de page utilise maintenant le port média de production et active le vrai bouton Lecture ; les résultats finaux distinguent explicitement l’état avant et après ce correctif.

## Limites exactes

- La lecture et le scrub utilisent maintenant la projection caméra du runtime, y compris son arrondi aux pixels physiques. La vue de travail conserve son propre cadrage. À contexte initial, dimensions et DPR identiques, les tests comparent les positions réellement dessinées ; une entrée de jeu dynamique sans placement explicite du joueur n'est pas un contexte d'aperçu universel.
- Le scrub est muet. La reprise audio utilise l’adaptateur existant et redémarre le fichier ; elle ne recherche pas un échantillon sonore précis. Le fade audio existant applique la cible de volume sans promettre une courbe continue. Une lecture décodée audible sur macOS n’est pas prouvée par les tests de port.
- Les émotes sont éditables et inspectables dans le statut de preview ; le montage n’affiche pas leur atlas animé au-dessus du personnage. Les FX restent partiels. Le tremblement et le fondu sont maintenant réellement rendus. Les ombres de contact des personnages restent présentes dans le runtime et absentes du montage ; les captures ne sont donc pas annoncées pixel-identiques.
- Les durées de dialogue/média sont indicatives en montage. Le moteur réel garde ses contrats d’attente. Aucun chevauchement parallèle ou waveform inventé.
- Le MCP connecté et la certification exhaustive de transport restent non validés pour les raisons documentées.
- Le contrôle manuel de la fenêtre native reste ouvert ; la compilation macOS et les captures du vrai moteur hors écran sont vérifiées. Le timeout de la première livraison reste documenté historiquement ; la suite complète après réparation passe sans assouplissement d'assertion ni de délai.
- La validation artistique appartient à Yoahn. Aucun autre écran commencé.

## Réparation de parité — 21 septembre 2026

Demande : corriger l'écart montré dans les deux enregistrements utilisateur, dans le périmètre UI10. L'audit initial a identifié une caméra simplement indicative, le tremblement absent, un fondu perdu dès la fin de son bloc, les placements ignorés dans le runtime, une orientation anticipée, des durées fictives de 300 ms, une interpolation différente des chemins et des ancres de sprites incohérentes. Les validations antérieures testaient les deux chemins séparément : elles ne prouvaient pas leur parité.

Le correctif réemploie les plans, modèles, opérations et moteurs existants. Les calculs purs de caméra, zoom physique, fondu, tremblement et trajectoire sont partagés avec le vrai moteur. Les placements et la caméra de départ sont temporaires, avec un snapshot distinct pour la restauration. Le handle cinématique du joueur utilise le centre de son sprite réel ; sa boîte de collision et sa caméra normale restent inchangées. La marche/course redémarre sa phase à chaque déplacement. Les actions instantanées n'ajoutent plus de durée fictive. Les outils de montage quittent explicitement l'aperçu ; Stop et la fin de lecture retrouvent la vue de travail. Un scrub explicite jusqu'à la fin permet toujours d'inspecter la dernière pose.

La première comparaison numérique a laissé échapper le décalage entre le centre de collision du joueur et son sprite. La comparaison réelle à 960 × 640, DPR 1, l'a montré ; une assertion sur l'enfant visuel du vrai PlayerComponent couvre maintenant ce cas, également avec des cellules 32 × 24. C'est la limite de la première passe, pas une preuve artificiellement déclarée complète.

Preuves visuelles finales : [page Studio à 1,95 s](captures/parity-studio-1950.png), [aperçu à viewport identique](captures/parity-preview-1950.png), [runtime au même instant](captures/parity-runtime-1950.png), [fondu maintenu dans Studio](captures/parity-studio-3749.png). La paire à viewport identique garde une différence de 4 551 pixels sur 614 400, limitée à la région des acteurs et de leurs ombres : [mesure](logs/parity-image-comparison.json). Les images proviennent de widgets de production et du vrai GameWidget Flutter/Flame, hors écran ; ce ne sont pas des maquettes ni une certification manuelle de la fenêtre native.

| Vérification fraîche | Résultat | Preuve |
| --- | --- | --- |
| Suite complète Studio après réparation | 595 réussis, 2 ignorés, aucun échec | [parity-studio-suite.txt](logs/parity-studio-suite.txt) |
| Géométrie, orientation, chemin et temps core | 69 tests réussis | [parity-core-actors-green.txt](logs/parity-core-actors-green.txt) |
| Projection caméra/fondu et plan core | 38 tests réussis | [parity-core-instant.txt](logs/parity-core-instant.txt) |
| Sink réel, contrôleur et intégration acteur | 21 tests réussis | [parity-runtime-actor-integration.txt](logs/parity-runtime-actor-integration.txt) |
| Joueur et animations | 10 tests réussis | [parity-player-regression.txt](logs/parity-player-regression.txt) |
| Sink et caméra physique | 23 tests réussis | [parity-sink-regression.txt](logs/parity-sink-regression.txt) |
| Parcours UI10, parité entre lecteurs, retour et captures | 17 tests réussis | [parity-ui10-targeted-final.txt](logs/parity-ui10-targeted-final.txt) |
| Transport, viewport, édition spatiale et animation | 6 tests réussis | [ui10-root-parity-verified.txt](logs/ui10-root-parity-verified.txt) |
| Analyse Studio | No issues found! | [parity-studio-analyze.txt](logs/parity-studio-analyze.txt) |
| Build macOS debug | Built Avelune Studio.app | [parity-native-build.txt](logs/parity-native-build.txt) |
| MCP check, build et tests | 83 tests réussis | [ui10-mcp-parity-tests.txt](logs/ui10-mcp-parity-tests.txt) |

Ces suites se recouvrent ; leurs nombres ne doivent pas être additionnés. Les commandes exactes et les PID possédés sont conservés dans les reçus JSON voisins. Les reproductions rouges et les essais échoués sont conservés, dont un premier test de viewport bloqué par des E/S dans la zone fake-async, arrêté puis corrigé en déplaçant la préparation en setUp. Ce journal n'est pas une preuve rouge du défaut produit. Les reproductions métier figurent dans `parity-core-actors-red`, `parity-fade-red`, `parity-runtime-actors-red` et `parity-runtime-animation-phase-red`.

La suite complète a terminé en 2 min 21 s ; les deux captures conditionnées à une copie de projet personnel restent ignorées. Les 192 descendants possédés ont été inspectés, aucun survivant à terminer. Les entrées et sorties restent sur `main`, HEAD `6e67f71605e2aad98671889be5078e0cef511a6a`, avec le travail UI10 déjà présent conservé et les corrections locales ajoutées. Aucun commit, push ou indexation. [Statut détaillé](logs/parity-git-status-final.txt), [contrôle Git et tailles des fichiers](logs/parity-git-final.json). `git diff --check` passe ; hygiène Markdown : un seul rapport nouveau déjà autorisé par UI10, aucun second Markdown créé. Analyse core/runtime ciblée sans problème ; trois informations de style restent dans les anciennes fixtures core de la passe plus large.

L'horloge a été contrôlée avec le même asset : la durée logique corrigée vaut 3 750 ms ; le test GameWidget piloté par temps réel cumule 3 766,842 ms sur 146 frames. Le décalage de durée apparent de la vidéo originale n'est pas entièrement expliqué par cette mesure et n'est pas présenté comme reproduit. Voir [mesure synchrone](logs/parity-wall-clock.txt).

Parité MCP : aucun nouveau schéma ni commande d'auteur n'est introduit ; les mêmes documents restent manipulables par les actions canoniques. Le check, build et les 83 tests de transport passent. Le connecteur vivant répond encore `worker.exited`, code 78 : cette certification reste partielle. Roadmap mécanique : correction de lecture liée aux commandes narratives FG-080/FG-092, aucun nouveau lot ni statut modifié. Aucune écriture Notion, conformément à la demande directe.

Passes : audit comparatif effectué par Tom ; implémentation spatiale/temps et revue de géométrie par `ui08_coexistence` ; projection caméra/effets et revue du raccord UI par `ui08_events_backend` ; preuves indépendantes, rectangles réels et captures par `ui08_runtime_proof` ; build, analyse et critique finale par Tom. Verdict : corrections fonctionnelles vérifiées, ombres et médias avancés encore partiels, validation visuelle utilisateur ouverte.

Fichiers supplémentaires ou zones reprises par cette réparation :

| Fichier ou groupe | Zone et raison |
| --- | --- |
| `packages/map_core/lib/src/read_models/cinematic_viewport_projection.dart` | Projection déterministe de la caméra et des effets à un instant. |
| `packages/map_core/lib/src/runtime/cinematic_visual_math.dart`, `pixel_perfect_camera_projection.dart` | Calculs réutilisés par le montage et le runtime. |
| `packages/map_core/lib/src/runtime/cinematic_actor_geometry.dart`, `cinematic_route_sampling.dart` | Focus visuel et échantillonnage des chemins en coordonnées de cellules. |
| `packages/map_core/lib/map_core_domain.dart` | Exports des contrats purs. |
| `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`, `cinematic_preview_playback_plan.dart`, `cinematic_timeline_time_layout_read_model.dart` | Orientation initiale, positions fractionnaires, fondu conservé, caméra prise en charge, actions instantanées. |
| `packages/map_runtime/lib/src/presentation/flame/flame_cinematic_runtime_playback_sink.dart` | Placements temporaires, snapshots, animation, chemins et projection commune. |
| `packages/map_runtime/lib/src/presentation/flame/pixel_perfect_overworld_camera.dart` | Réemploi des calculs physiques partagés. |
| `packages/map_runtime/lib/src/presentation/flame/player_component.dart`, `playable_map_game_support.dart` | Handle cinématique au centre visuel et état marche/course, sans changer le focus normal. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_preview_transport.dart` | État d'aperçu, scrub, Stop et fin de lecture. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_playback_viewport.dart` | Vue caméra réelle indépendante du transform de travail. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_map_scene.dart`, `cinematic_map_overlay.dart`, `cinematic_map_model.dart` | Raccordement, géométrie des sprites et cibles ; poignées masquées pendant la lecture. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_actor_animation.dart`, `cinematic_path_painter.dart` | Phase locale d'animation et dessin des trajets, extrait pour conserver des fichiers courts. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector.dart`, `cinematic_preview_status.dart` | Retour explicite à l'édition et suppression du faux avertissement de tremblement. |
| Tests core `cinematic_actor_geometry_parity_test.dart`, `cinematic_viewport_state_parity_test.dart`, et trois suites read-model existantes | Régressions géométrie/temps/effets et attentes anciennes corrigées. |
| Test runtime `flame_cinematic_runtime_playback_sink_test.dart` | Placements, route, phase et restauration. |
| Tests Studio `cinematic_viewport_parity_ui10_test.dart`, `cinematic_actor_animation_ui10_test.dart`, `cinematic_preview_transport_ui10_test.dart` | Vue effective, animations et retour à l'édition. |
| Tests Studio `cinematics_ui10_preview_runtime_parity_test.dart`, `cinematics_ui10_parity_viewport_test.dart`, `cinematics_ui10_runtime_test.dart`, support `ui10_parity_fixture.dart` | Comparaison au vrai runtime, captures et restauration du contexte d'entrée. |

## Inventaire des fichiers de code et tests

Chaque ligne précise les zones concernées. Pour les nouveaux fichiers, le fichier entier appartient au lot ; pour les fichiers existants, le diff Git reste la preuve exacte. Les journaux et captures de ce répertoire sont les artefacts d’exécution, pas des sources recopiées.

| Fichier | Zones et raison |
| --- | --- |
| `apps/avelune_studio/lib/app/di/cinematic_providers.dart` | Injection du port et du contrôleur cinématique dans le cycle de vie du workspace. |
| `apps/avelune_studio/lib/app/di/providers.dart` | Injection du port et du contrôleur cinématique dans le cycle de vie du workspace. |
| `apps/avelune_studio/lib/app/studio_bootstrap.dart` | `StudioBootstrap` — Injection du port et du contrôleur cinématique dans le cycle de vie du workspace. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_edit_session.dart` | `CinematicEditSession`, `CinematicWorkingSession` — Session/commande/projection UI10 selon la responsabilité du fichier ; modèles canoniques et application Dart pure. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_preview_media_session.dart` | `CinematicPreviewMediaSession` — Session/commande/projection UI10 selon la responsabilité du fichier ; modèles canoniques et application Dart pure. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_preview_transport.dart` | `CinematicPreviewTransport` — Session/commande/projection UI10 selon la responsabilité du fichier ; modèles canoniques et application Dart pure. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_workspace_actions.dart` | `CinematicWorkspaceActions` — Session/commande/projection UI10 selon la responsabilité du fichier ; modèles canoniques et application Dart pure. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_workspace_animation.dart` | `CinematicWorkspaceAnimation` — Session/commande/projection UI10 selon la responsabilité du fichier ; modèles canoniques et application Dart pure. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_workspace_controller.dart` | `CinematicWorkspaceController` — Session/commande/projection UI10 selon la responsabilité du fichier ; modèles canoniques et application Dart pure. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_workspace_publication.dart` | `CinematicWorkspacePublication` — Créer, dupliquer, sauvegarder/recharger, archiver/supprimer avec conflits et reçus. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_workspace_spatial.dart` | `CinematicWorkspaceSpatial` — Opérations spatiales canoniques atomiques ; préserver les chemins et bornes de carte. |
| `apps/avelune_studio/lib/features/cinematics/application/cinematic_workspace_timeline.dart` | `CinematicWorkspaceTimeline` — Session/commande/projection UI10 selon la responsabilité du fichier ; modèles canoniques et application Dart pure. |
| `apps/avelune_studio/lib/features/cinematics/data/local_cinematic_adapter.dart` | `LocalCinematicAdapter` — Port de publication canonique, conflits, références et transaction de bibliothèque. |
| `apps/avelune_studio/lib/features/cinematics/domain/cinematic_port.dart` | `CinematicSourceSnapshot`, `CinematicPublicationReceipt`, `CinematicFailure` — Contrat et reçus de publication du document cinématique. |
| `apps/avelune_studio/lib/features/dialogues/application/dialogue_working_source.dart` | `DialogueWorkingSource` — Résolution C1 : source sale courante avant source propre, détection des divergences et sources avancées préservées. |
| `apps/avelune_studio/lib/features/narrative/application/narrative_cinematic_coexistence.dart` | `NarrativeCinematicCoexistence` — Garde de coexistence des interactions et cinématiques complètes ; publication et invalidation des seules sessions propres. |
| `apps/avelune_studio/lib/features/narrative/application/narrative_interaction_loading.dart` | `NarrativeInteractionLoading` — Garde de coexistence des interactions et cinématiques complètes ; publication et invalidation des seules sessions propres. |
| `apps/avelune_studio/lib/features/narrative/application/narrative_session_coexistence.dart` | `NarrativeSessionCoexistence` — Garde de coexistence des interactions et cinématiques complètes ; publication et invalidation des seules sessions propres. |
| `apps/avelune_studio/lib/features/narrative/application/narrative_workspace_controller.dart` | `NarrativeWorkspaceController` — Garde de coexistence des interactions et cinématiques complètes ; publication et invalidation des seules sessions propres. |
| `apps/avelune_studio/lib/features/narrative/application/narrative_workspace_publication.dart` | `NarrativeWorkspacePublication` — Garde de coexistence des interactions et cinématiques complètes ; publication et invalidation des seules sessions propres. |
| `apps/avelune_studio/lib/features/narrative/data/local_narrative_catalog_transaction.dart` | `LocalNarrativeCatalogTransaction`, `NarrativeCatalogFailure` — Garde de coexistence des interactions et cinématiques complètes ; publication et invalidation des seules sessions propres. |
| `apps/avelune_studio/lib/platform/rendering/studio_character_thumbnail.dart` | `StudioCharacterThumbnail`, `_StudioCharacterThumbnailState`, `_CharacterPainter` — Paramètres de facing, état, temps et animation personnalisée transmis au renderer partagé. |
| `apps/avelune_studio/lib/platform/rendering/studio_cinematic_media.dart` | `StudioCinematicMedia`, `_UnavailableFxHost` — Adaptateur runtime de médias ; chemins projet bornés, symlinks et erreurs hôte explicites. |
| `apps/avelune_studio/lib/platform/rendering/studio_map_resource_recovery.dart` | `StudioMapResourceRecovery` — Méthodes de récupération extraites sans changement de contrat, taille du fichier principal bornée. |
| `apps/avelune_studio/lib/platform/rendering/studio_map_resources.dart` | `StudioMapResources` — Médias cinématiques et récupération des ressources séparée dans un part, caches existants conservés. |
| `apps/avelune_studio/lib/platform/rendering/studio_map_visual_widgets.dart` | `StudioMapVisual`, `_StudioMapVisualState`, `_MissingResourcePainter`, `_MapPainter` — _MapPainter.paint : intersection du clip et des limites du canvas ; empêcher une requête spatiale gigantesque sous RepaintBoundary. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_action_palette.dart` | `CinematicActionPalette` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_document_toolbar.dart` | `CinematicDocumentToolbar` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector_actors.dart` | `CinematicInspectorActors` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector_animation.dart` | `CinematicInspectorAnimation` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector_camera.dart` | `CinematicInspectorCamera` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector_commands.dart` | `CinematicInspectorCommands` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector_step.dart` | `CinematicInspectorStep` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector.dart` | `CinematicInspector` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_labels.dart` | Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_library_thumbnail.dart` | `CinematicLibraryThumbnail`, `_CinematicLibraryThumbnailState` — Miniature asynchrone réelle ; résultat utilisable uniquement pour la bonne carte terminée. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_library.dart` | `CinematicLibrary` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_map_model.dart` | `CinematicMapModel` — Projection acteurs/liaisons et carte de fond copiée ; résolution des usages de repères sans mutation source. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_map_overlay.dart` | `CinematicMapOverlay`, `CinematicPathPainter` — Poses canoniques, rendu des acteurs, chemins, points et cadre caméra indicatif. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_map_scene.dart` | `CinematicMapScene`, `_CinematicMapSceneState` — Viewport pan/zoom, transformation des clics en cellules, recadrage et fondu d’aperçu. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_page_commands.dart` | `_CinematicPageCommands` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_page_header.dart` | `_CinematicPageHeader` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_page_map.dart` | `_CinematicPageMap` — Chargement gardé, plan canonique, positions/destinations/trajets et confirmation des points partagés. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_page_timeline.dart` | `_CinematicPageTimeline` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_point_handle.dart` | `CinematicPointHandle`, `_CinematicPointHandleState` — Geste transitoire d’un repère, annulation Échap et un seul commit en fin de glisser. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_preview_status.dart` | `CinematicPreviewStatus`, `_CinematicPreviewStatusState` — Dialogue partagé, diagnostics, capacités et limites effectives des cues. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_timeline_editor.dart` | `CinematicTimelineEditor`, `_CinematicTimelineEditorState` — Pistes, sélection et disposition temporelle séquentielle canonique. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_timeline_gestures.dart` | `_CinematicTimelineGestures` — Réordre, redimensionnement, copier/coller, annuler/rétablir ; geste atomique et abandon Échap. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_timeline_painter.dart` | `CinematicTimelineGrid`, `CinematicPlayhead` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_transport_bar.dart` | `CinematicTransportBar` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_transport_listenable.dart` | `CinematicTransportListenable` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_view_state.dart` | `CinematicMapMode`, `CinematicViewState`, `CinematicViewStore` — Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_workspace_page.dart` | `CinematicWorkspacePage`, `_CinematicWorkspacePageState` — Composition responsive, fermeture/flush, panneaux, raccourci de sauvegarde et palette adaptée au texte. |
| `apps/avelune_studio/lib/presentation/features/cinematics/cinematic_workspace_visuals.dart` | Widget/part UI10 : composition, commandes ou inspecteur spécialisé ; état du contrôleur partagé, tokens existants. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_screen.dart` | `MapWorkspaceScreen`, `_MapWorkspaceScreenState` — Branchement UI10, conservation du contexte et des brouillons de navigation existants. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_actions.dart` | `WorkspaceActions` — Intégration aux gardes fermeture/sauvegarde/test ; refus de tester des dépendances non publiées. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_cinematic_binding.dart` | `_WorkspaceCinematicBinding` — Initialisation, ouverture depuis scène, dialogue imbriqué et localisation de carte avec garde de navigation. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_home_binding.dart` | `_WorkspaceHomeBinding` — Branchement UI10, conservation du contexte et des brouillons de navigation existants. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_screen_body.dart` | `_WorkspaceScreenBody` — Branchement UI10, conservation du contexte et des brouillons de navigation existants. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_secondary_content.dart` | `WorkspaceSpace` — Branchement UI10, conservation du contexte et des brouillons de navigation existants. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_story_binding.dart` | `_WorkspaceStoryBinding` — Branchement UI10, conservation du contexte et des brouillons de navigation existants. |
| `apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_header.dart` | `NarrativeOverviewHeader` — Garde de coexistence des interactions et cinématiques complètes ; publication et invalidation des seules sessions propres. |
| `apps/avelune_studio/lib/presentation/features/narrative/narrative_story_pane.dart` | `NarrativeStoryPane`, `_NarrativeStoryPaneState` — Garde de coexistence des interactions et cinématiques complètes ; publication et invalidation des seules sessions propres. |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_commands.dart` | `_SceneBuilderCommands` — Ouverture cinématique contextualisée et validation des saisies avant navigation. |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_page.dart` | `SceneBuilderPage`, `_SceneBuilderPageState` — Injection du contrôleur de dialogue partagé et callback d’ouverture UI10. |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_linked_document.dart` | `SceneLinkedDocuments` — Aperçus UI06/UI10 branchés sur la même résolution du document de dialogue. |
| `apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_commit_field.dart` | `StudioCommitField`, `_StudioCommitFieldState` — Validation sur perte de focus et soumission dédupliquée ; conserver le diagnostic jusqu’à une vraie nouvelle saisie. |
| `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_map_overlay_frame.dart` | `StudioMapOverlayFrame` — Primitive de présentation Avelune réutilisable ou entrée de navigation ; couleurs issues du thème. |
| `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_primary_navigation.dart` | `StudioPrimaryNavigation` — Primitive de présentation Avelune réutilisable ou entrée de navigation ; couleurs issues du thème. |
| `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_timeline_clip.dart` | `StudioTimelineClip` — Primitive de présentation Avelune réutilisable ou entrée de navigation ; couleurs issues du thème. |
| `apps/avelune_studio/lib/presentation/shell/studio_workspace_host.dart` | `StudioWorkspaceHost` — Injection du port et du contrôleur cinématique dans le cycle de vie du workspace. |
| `apps/avelune_studio/test/cinematics_ui10_nested_navigation_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics_ui10_renderer_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics_ui10_responsive_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics_ui10_runtime_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics_ui10_spatial_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics_ui10_timeline_gesture_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics_ui10_widget_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_adapter_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_animation_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_coexistence_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_controller_ui10_test.dart` | `_DelayedPort` — Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_independent_publication_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_inspector_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_library_thumbnail_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_platform_media_ui10_test.dart` | `_AudioDriver` — Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_preview_media_ui10_test.dart` | `_MediaPort` — Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_preview_transport_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_published_guard_ui10_test.dart` | `_Narrative`, `_Cinematic` — Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_spatial_gestures_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/cinematic_timeline_gestures_ui10_test.dart` | Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/cinematics/dialogue_working_source_ui10_test.dart` | `_WorkingFixture` — Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `apps/avelune_studio/test/support/cinematic_adapter_fixture.dart` | `CinematicAdapterFixture` — Fixture ou hôte isolé UI10 ; cartes, sessions et médias réels de test, sans projet personnel. |
| `apps/avelune_studio/test/support/ui08_workspace_harness.dart` | `Ui08WorkspaceHarness`, `Ui08MapPort`, `Ui08EventPort` — Fixture ou hôte isolé UI10 ; cartes, sessions et médias réels de test, sans projet personnel. |
| `apps/avelune_studio/test/support/ui10_cinematic_fixture.dart` | Fixture ou hôte isolé UI10 ; cartes, sessions et médias réels de test, sans projet personnel. |
| `apps/avelune_studio/test/support/ui10_fixture_visuals.dart` | Fixture ou hôte isolé UI10 ; cartes, sessions et médias réels de test, sans projet personnel. |
| `apps/avelune_studio/test/support/ui10_widget_port.dart` | `Ui10WidgetPort` — Fixture ou hôte isolé UI10 ; cartes, sessions et médias réels de test, sans projet personnel. |
| `apps/avelune_studio/test/support/ui10_workspace_harness.dart` | `Ui10WorkspaceHarness` — Fixture ou hôte isolé UI10 ; cartes, sessions et médias réels de test, sans projet personnel. |
| `packages/map_authoring/lib/src/domains/narrative/cinematic_actions.dart` | `CinematicAuthoringInspection`, `CinematicAuthoringInspector`, `CinematicActions` — cinematic.upsert : placement de bibliothèque optionnel dans la même publication canonique. |
| `packages/map_authoring/lib/src/domains/narrative/cinematic_library_placement.dart` | Validation v7, clés/types et placement par CinematicLibraryCatalogOperations. |
| `packages/map_authoring/test/domains/narrative/cinematic_atomic_placement_test.dart` | `_Fixture` — Scénarios et assertions du fichier : comportement nominal, refus/annulation, intégrité ou régression UI10 ; voir son journal de suite. |
| `packages/map_core/lib/map_core_domain.dart` | Export du contrôleur média pur partagé. |
| `packages/map_core/lib/src/runtime/cinematic_media_preview_controller.dart` | `MutableCinematicPreviewClock`, `CinematicMediaPreviewState`, `CinematicMediaPreviewException`, `CinematicMediaPreviewController` — Contrôleur pur existant partagé dans map_core ; ancien chemin map_editor réexporté. |
| `packages/map_editor/lib/src/ui/canvas/cinematics/preview/cinematic_media_preview_controller.dart` | Contrôleur pur existant partagé dans map_core ; ancien chemin map_editor réexporté. |
| `packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_character_renderer.dart` | `RuntimeAuthoringCharacterRenderer` — Paramètres d’animation facultatifs ; mêmes valeurs par défaut pour les consommateurs existants. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | `_RuntimeFlowPhase`, `_NarrativeOutcomeRetryPendingException`, `PlayableMapGame` — onRemove : annuler la cinématique avant nettoyage, réutiliser les garanties de restauration existantes. |
| `tools/pokemap_mcp/test/mutation_server.test.ts` | Publication et relecture de cinématique avec son placement via le transport MCP empaqueté. |
