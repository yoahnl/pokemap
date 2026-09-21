# AS-UI-011 — Cinématique de présentation

Livraison de l'image 07 du kit Narrative Studio, précédée des deux réparations
ciblées de UI10 (R1 et R2).

Le lot a été exécuté en deux sessions successives. La première a construit
l'essentiel du backend, des widgets et des tests. La seconde a repris le
chantier interrompu : elle a levé deux blocages rouges, trouvé une erreur de
compilation non détectée dans `map_editor`, nettoyé les analyses et produit ce
rapport. La section « Ce qui a été repris en seconde session » liste
exactement ce que la reprise a changé.

## Accès

| Élément | Emplacement |
| --- | --- |
| Page UI11 | `apps/avelune_studio/lib/presentation/features/presentations/` |
| Application UI11 | `apps/avelune_studio/lib/features/presentations/` |
| Publication canonique | `packages/map_authoring/lib/src/domains/narrative/presentation_publication_*.dart` |
| Contrôleur de montage | `packages/map_authoring/lib/src/domains/narrative/presentation_timeline_editing_controller.dart` |
| Géométrie du canevas | `packages/map_player_ui/lib/src/player/presentation_frame_geometry.dart` |
| Captures | `documentation/reports/avelune_studio/UI11_cinematique_presentation/captures/` |
| Journaux | `documentation/reports/avelune_studio/UI11_cinematique_presentation/logs/` |
| Build macOS | `apps/avelune_studio/build/macos/Build/Products/Debug/Avelune Studio.app` |

## R1 — Compatibilité des coordonnées avec l'ancien éditeur

La régression d'origine (`num` vers `int` et import redondant sous
`packages/map_editor/lib/src/ui/canvas/cinematics/`) est réparée. Les positions
visuelles restent fractionnaires jusqu'au rendu ; la conversion vers un index
de cellule entier se fait à la frontière d'accès de grille.

**Une seconde erreur, absente du mandat, a été trouvée en reprise.** L'extraction
de `PresentationTimelineEditingController` vers `map_authoring` — paquet Dart
pur, sans dépendance Flutter — lui a fait perdre sa nature de `Listenable`,
alors qu'un consommateur l'utilisait encore dans un `Listenable.merge` :

```
error - lib/src/ui/canvas/narrative_workspace_canvas.dart:3385
The element type 'PresentationTimelineEditingController'
can't be assigned to the list type 'Listenable?'
```

`map_editor` ne compilait donc pas. L'extraction a été conservée (elle répond à
la section 16 du mandat, réexport compris) et le raccord se fait par un
adaptateur `PresentationTimelineEditingListenable` posé sur le fichier-frontière
de `map_editor`, sur le même motif que `PresentationTransportListenable` déjà
utilisé côté Studio.

Étape CI rejouée à l'identique, dans `packages/map_editor` :

| Commande CI (`pokemap_quick_checks.yml`, étape Editor) | Résultat |
| --- | --- |
| `flutter test --no-pub --timeout 2m test/release/github_distribution_workflow_test.dart test/tileset_grid_metrics_test.dart test/map_editing_controller_test.dart` | 20 tests verts |
| `flutter analyze --no-pub lib test/release` | `No issues found!` |

## R2 — Une erreur ponctuelle ne bloque plus la page

Le parcours « cinématique sans acteur → action Déplacement → message → ajout et
sélection d'un acteur → nouvelle action → sauvegarde → aperçu → retour » est
couvert par `apps/avelune_studio/test/cinematics_ui10_error_recovery_test.dart`,
avec les vrais boutons. Le diagnostic d'action est distingué de l'échec de
publication et de la validation d'une saisie en cours : le message est réévalué
quand son prérequis est satisfait, sans que `flush()` efface globalement les
erreurs, et une valeur réellement invalide continue de refuser la publication.

## UI11 — Deux défauts de manipulation corrigés en reprise

Les deux tests de poignées étaient rouges et décrivaient des défauts réels de la
page, pas des artefacts de test.

**1. Les poignées d'échelle et de rotation n'accrochaient jamais.**
`onPanStart` de Flutter rapporte, avec le `DragStartBehavior.start` par défaut,
la position où le geste est *reconnu*, pas celle où le doigt s'est posé. Le
hit-test de poignée s'exécutait donc à environ un `kTouchSlop` du point pressé,
au-delà du rayon d'accroche de 14 px : le geste retombait sur `select()`, qui
désélectionnait, et mourait. Diagnostic mesuré à l'exécution — poignée à
`Offset(688.2, 262.1)`, point reçu `Offset(736.2, 262.1)`.

Correctif : un `Listener` capte la position réellement pressée et sert d'ancre
au hit-test, tandis que le calcul du delta continue de partir du point de
reconnaissance. Les poignées accrochent, et il n'y a pas de saut initial —
les deux exigences de la section 7 tiennent ensemble.

**2. Échap n'annulait pas une transformation en cours.**
L'annulation passait par `CallbackShortcuts`, qui dépend du focus : après un clic
sur un bouton de barre d'outils, Échap n'atteignait plus le canevas. Correctif
aligné sur le motif déjà présent dans `presentation_studio_responsive_canvas.dart`
de `map_editor` : un handler `HardwareKeyboard`, borné au geste armé, qui ne
consomme la touche que pendant un drag.

## Retour de validation : la création semblait ne rien faire

Signalé par Yoahn à la première prise en main. Créer une présentation paraissait
sans effet : après le nom et le choix du modèle, rien ne changeait pendant
plusieurs secondes, ni dans la bibliothèque ni au centre.

Le document arrivait bien, mais tard. `PresentationPort.prepare` relit le projet
depuis le disque avant d'instancier le modèle, et le `project.json` du Train
pèse environ 10,7 Mo. L'attente est donc réelle et attendue à cette taille.

Le défaut était l'absence totale de retour visuel. Le contrôleur publiait déjà
`busy` (`_loading || saving`) et le posait autour de la préparation, mais
**aucun widget ne le lisait** : `flutter analyze` ne signale pas un getter
public inutilisé. L'en-tête n'affichait une attente que pour la sauvegarde,
via `loading: controller.saving`.

Correctif, aligné sur le motif déjà utilisé par le pane Ressources et l'éditeur
de terrains (`if (busy) const LinearProgressIndicator()`) :

- une barre de progression sous l'en-tête de la page, qui couvre aussi
  l'ouverture d'une présentation existante, elle aussi tributaire d'une lecture
  disque ;
- `loading: controller.busy` sur « Nouvelle cinématique » et sur « Créer une
  présentation », ce qui affiche un indicateur dans le bouton et interdit un
  second départ pendant la préparation.

`ui11_presentation_busy_test.dart` verrouille le comportement : il retient
`prepare` derrière une porte, vérifie que la barre est présente et que le bouton
refuse un second clic, puis relâche et vérifie que le document ouvert est bien
le nouveau. Capture `ui11-03-busy-create.png`.

Aucune optimisation de la lecture disque n'a été tentée : elle est hors du
périmètre de ce lot et demanderait de toucher au chargement du projet.

## Composition livrée

Le cadre Avelune, la navigation et l'espace Histoire sont réutilisés tels quels.
La page pose la bibliothèque à gauche avec ses onglets, le canevas
sélectionnable au centre, le transport immédiatement sous le canevas, la
timeline absolue dessous et l'inspecteur à droite. Les panneaux se replient
réellement.

Réemployé sans duplication : `PresentationCinematicEvaluator` pour l'évaluation,
`PresentationFrameRenderer` pour le rendu, `PresentationStudioMediaSink` pour
l'audio et la vidéo, `PresentationPlaybackClock` pour l'horloge de consultation,
les actions et transactions canoniques de `map_authoring` pour la publication.
Aucun second évaluateur, aucun second renderer, aucun second mixer.

## Écarts assumés par rapport au PNG

| Dans la maquette | Livré | Raison |
| --- | --- | --- |
| « 1280 × 720 » et « 1920 × 1080 » | Sélecteur **Paysage 16:9 / Portrait 9:16** | L'asset relu ne porte pas de dimensions de sortie ; inventer une résolution d'export aurait fabriqué un contrat inexistant. |
| « Calques » | **Éléments** et ordre devant/derrière | Vocabulaire et gestes simplifiés ; les `PresentationLayer` canoniques sont conservés dans le format. |
| Boutons **Forme** et **Particules** | Absents | Aucun moteur correspondant n'existe ; un bouton inerte aurait menti. |
| Police « Playfair Display » | Polices réellement disponibles | Aucun téléchargement implicite de fonte. |
| Onglet « Effets » | Absent | Même raison que Forme et Particules. |
| Illustration du train | Fixture identifiée | Aucun asset extrait du PNG. |

## Parité aperçu / lecture

La leçon de UI10 est traitée frontalement : le montage et le runtime ne sont pas
mesurés séparément. `presentations_ui11_renderer_parity_test.dart` construit une
seule fois l'asset, les médias, le viewport (960 × 640, DPR 1) et le thème, puis
compare **la totalité des octets RGBA** du rendu de montage à celui de la surface
runtime réelle, sur neuf instants et dans les deux orientations :

`0`, `249 999`, `250 000`, `500 000`, `750 000`, `1 000 000`, `2 749 999`,
`2 750 000`, `2 999 999` microsecondes — soit avant apparition, aux bornes d'un
intervalle semi-ouvert, au milieu d'une transition, sur une superposition image
plus texte, juste avant la fin, à la fin exacte, et après un saut.

L'écart toléré est **zéro pixel**. Les captures
`ui11-parity-{landscape,portrait}-500000-{montage,runtime}.png` ont le même
condensat MD5 par orientation : c'est le résultat attendu d'une parité stricte,
pas une image recopiée — les deux passent par `_render` séparément, l'une depuis
`visuals.frame(...)`, l'autre depuis `RuntimePresentationFrameSurface`.

Ce test se figeait auparavant jusqu'au délai de dix minutes. La cause était dans
le test, pas dans le produit : `StudioPresentationVisuals` était construit dans
la zone `FakeAsync` de `flutter_test`, si bien que le `Future.value()` de son
champ `_releaseFuture` ne se résolvait jamais lorsqu'on l'attendait depuis la
zone réelle de `tester.runAsync`. La construction a été déplacée dans la même
zone que l'attente. Le test passe désormais en cinq secondes pour les deux
orientations.

## Tests exacts

Les nombres ci-dessous portent sur des périmètres distincts et ne s'additionnent
pas : la suite Studio contient déjà les tests ciblés UI11.

| Périmètre | Commande | Résultat |
| --- | --- | --- |
| Tests ciblés UI11 | `flutter test` sur les 12 fichiers UI11 et `test/presentations/` | 41 verts |
| Suite Studio complète | `flutter test` dans `apps/avelune_studio` | 637 verts, 2 ignorés |
| Analyse Studio | `flutter analyze` | `No issues found!` |
| Analyse `map_authoring` | `dart analyze` | `No issues found!` |
| Analyse `map_player_ui` | `dart analyze` | `No issues found!` |
| Analyse `map_editor` (étape CI) | `flutter analyze --no-pub lib test/release` | `No issues found!` |
| Tests CI `map_editor` | 3 fichiers de l'étape CI | 20 verts |
| Transport MCP | `node --import tsx --test test/mutation_server.test.ts` | 34 verts |
| Build macOS | `flutter build macos --debug` | `Avelune Studio.app` produit |

`test/presentation/desktop_workspace_layout_test.dart` a échoué une fois sur
une exécution de la suite complète, puis est repassé au vert seul comme en
suite. C'est un test de charge — deux cents diagnostics et de nombreux atlas —
sensible au temps de réponse de la machine. Il est signalé ici comme instable
plutôt que déclaré fiable.

Les deux tests ignorés de la suite Studio sont conditionnés à la variable
`AVELUNE_PROJECT_COPY` et à un chemin de projet réel. Ils préexistent au lot et
n'ont pas été désactivés pour ce lot.

L'action `presentationCinematic.publish` est enregistrée au dispatcher et porte
ses preuves de parité sur les quatre transports (API directe, CLI JSONL,
éditeur, MCP) dans `full_authoring_parity.dart`. Les dix-huit tests de
`test/parity/full_authoring_parity_test.dart` passent.

## Limites et échecs préexistants

Ces échecs ne viennent pas de ce lot. Ils sont établis par preuve de fichier :
toutes les sources et tous les tests concernés sont intacts dans l'arbre de
travail, et la dépendance mise en cause est déjà présente au commit de base.

| Suite | Échecs | Cause établie |
| --- | --- | --- |
| `map_player_ui` | 63 sur 1 347 | Tous dans `test/player/menu8_save_test.dart`. Les chaînes sont choisies par `_isFrench` dans `player_save_strings.dart` ; la locale de cette machine résout `en`, le widget rend « Stay » et le test attend « Rester ». Fichier non modifié par ce lot. |
| `map_authoring` | 6 sur 888 | `package_boundary_test.dart` (`freezed_annotation`, déjà déclaré dans le `pubspec.yaml` au commit de base, lequel n'est pas modifié ; taille de l'adaptateur de génération d'Environment), `registry/action_registry_test.dart` (ressource `element`, déclarée par `environment_preset_actions.dart` et `tileset_library_actions.dart`, non modifiés) et `smart_tile_layer_actions_test.dart`. Aucun de ces fichiers n'est touché par ce lot. |

Autres limites, annoncées et non contournées :

- **La lecture vidéo native n'est pas certifiée.** Le sink expose au plus une
  vidéo vivante à la fois, conformément au runtime. Un média vidéo est présenté
  comme **aperçu fixe** tant que l'hôte ne l'a pas réellement décodé ; aucun
  poster n'est présenté comme une preuve de lecture.
- **À 1024 × 640 avec texte à 150 %**, les panneaux se replient correctement en
  boutons « Bibliothèque » et « Inspecteur », le transport et « Enregistrer »
  restent atteignables, mais la timeline est à l'étroit et ses pistes sont
  tronquées verticalement. Aucune exception de débordement n'est levée. C'est un
  écart de confort, pas une perte de fonction.
- **Le SDK local n'est pas celui de la CI.** La CI épingle Flutter
  `3.46.0-0.3.pre` ; la machine de développement tourne en `3.48.0-0.4.pre`.
  Rejouer la commande CI en local ne suffit donc pas à prouver l'étape. Un
  premier push l'a démontré : `ScrollCacheExtent`, réexporté par
  `package:flutter/cupertino.dart` en 3.48 mais pas en 3.46, rendait l'import
  explicite « redondant » pour l'analyse locale et indispensable pour la CI.
  Supprimer cet import sur la foi du lint local a cassé l'étape Editor. Le
  fichier passe désormais par un import préfixé, forme acceptée par les deux
  versions sans directive `ignore`.

- **`map_workspace_screen.dart` est exactement à la limite de 300 lignes**
  imposée par `architecture_boundaries_test.dart`. La correction de lint de ce
  lot a dû être écrite pour tenir dans ce budget. La prochaine ligne ajoutée à
  ce fichier demandera une extraction.
- Aucune écriture Git ni Notion n'a été faite. Aucun projet personnel original
  n'a été modifié : les parcours passent par des fixtures temporaires.
- Aucun commentaire n'a été ajouté au code écrit à la main, et aucun commentaire
  préexistant n'a été supprimé.

## Ce qui a été repris en seconde session

| Fichier | Nature |
| --- | --- |
| `presentation_canvas.dart` | Ancre de hit-test sur le point pressé ; annulation par Échap bornée au geste |
| `presentation_canvas_gestures.dart` | Hit-test de poignée sur l'ancre pressée |
| `map_editor/.../presentation_timeline_editing_controller.dart` | Adaptateur `Listenable` ajouté au fichier-frontière |
| `map_editor/.../narrative_workspace_canvas.dart` | Usage de l'adaptateur, import redondant retiré, accolades |
| `map_player_ui/.../presentation_frame_geometry.dart` | Signature `updateRenderObject` sans type privé, accolades |
| `presentations_ui11_renderer_parity_test.dart` | Correction de zone async, traces de débogage retirées |
| `ui11_presentation_responsive_test.dart` | Tailles alignées sur le mandat : 1536 × 1024 et 1024 × 640 |
| `ui11_presentation_canvas_gesture_test.dart` | Capture du titre transformé |
| `presentation_workspace_publication.dart`, `map_workspace_screen.dart` | Accolades, dans le budget de lignes existant |

## Captures

Toutes les captures ont été régénérées sur le code livré. Ce sont des rendus de
vrais widgets, sans retouche ni assemblage de maquette.

| Fichier | Contenu |
| --- | --- |
| `ui11-01-early-composition.png` | Page complète, comparaison précoce avec l'image 07 |
| `ui11-02-title-scale-transformed.png` | Titre sélectionné et mis à l'échelle par sa poignée |
| `ui11-02-title-rotate-transformed.png` | Titre pivoté, overlay de sélection épousant le contenu transformé |
| `ui11-03-busy-create.png` | Préparation en cours : barre de progression et bouton de création verrouillé |
| `ui11-04-landscape-{1536,1440,1280,1024}.png` | Page complète aux quatre tailles, texte à 150 % à 1024 |
| `ui11-05-portrait-{1536,1440,1280,1024}.png` | Vue portrait |
| `ui11-06-compare-{1536,1440,1280,1024}.png` | Mode Comparer les formats |
| `ui11-07-library-archived.png` | Bibliothèque, archivage et restauration |
| `ui11-parity-*-500000-{montage,runtime}.png` | Parité montage et runtime au même instant |

La timeline visible dans `ui11-04-landscape-1440.png` montre deux clips actifs
au même instant sur des pistes distinctes : c'est la superposition légitime que
permet le temps absolu de Presentation, et que le montage séquentiel de UI10
n'aurait pas autorisée.

## Validation attendue

La validation visuelle de Yoahn est requise avant toute autre page. UI12 et UI13
ne sont pas commencées. Ce lot ne clôt pas les autres réserves du Narrative
Studio, et notamment pas la réserve UI07 sur la progression structurée d'une
histoire.
