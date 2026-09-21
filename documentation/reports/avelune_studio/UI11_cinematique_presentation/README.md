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

## Deuxième retour de validation : messages, raccourcis et tête de lecture

Trois reproches de Yoahn à la prise en main, qui ont mis au jour cinq défauts.

**Des bannières d'erreur venues de nulle part.** Deux causes distinctes.

`update()` de la timeline écrivait « Déplacement refusé » dans l'état de vue,
mais ne faisait un `setState` que sur la timeline : la bannière est rendue par
le corps de page, qui ne se reconstruisait pas. Le message n'apparaissait donc
qu'au gré d'un rebuild provoqué par autre chose, et ne disparaissait pas
davantage. La timeline notifie désormais la page, **au seul changement d'état
du message** et non à chaque frame de glissement, pour respecter la section 19.

`finish()` et `cancel()` ne remettaient jamais `actionError` à `null` : le
diagnostic d'un geste survivait au geste. C'est le défaut R2 de UI10 reproduit
dans la timeline, que la section 16 interdit nommément. Le canevas avait le
même oubli dans son `cancel()`.

**« Aperçu fixe » affiché comme une panne.** `currentDiagnostic` renvoyait
indifféremment une vraie erreur de média et l'étiquette « Aperçu fixe », qui
signale un état parfaitement normal — le sink n'anime qu'une vidéo à la fois et
la section 10 exige précisément cette étiquette. L'en-tête peignait les deux en
rouge. La sévérité est maintenant portée par `diagnosticIsFailure` et l'en-tête
s'y conforme.

**Aucun raccourci clavier.** Les liaisons existantes passaient par
`CallbackShortcuts`, donc par le focus : après un clic sur un bouton, plus rien
ne répondait. Même défaut que l'annulation par Échap du canevas. La page
enregistre désormais un gestionnaire `HardwareKeyboard`, sur le motif du
`presentation_studio_responsive_canvas.dart` de `map_editor` : Espace pour
lire et mettre en pause, flèches pour avancer et reculer d'un pas, Début et Fin
pour les bornes, ainsi que Cmd/Ctrl+S et Cmd/Ctrl+Z. Le gestionnaire se retire
lorsqu'une saisie de texte a le focus, lorsqu'aucun document n'est ouvert et
lorsqu'une boîte de dialogue est au premier plan. La timeline reçoit le même
traitement pour Échap pendant un glissement.

**Tête de lecture immobile.** La règle ne portait qu'un `onTapDown` : on
pouvait viser un point, jamais faire glisser. Le scrub demandé par la section 13
n'existait pas. La règle accepte maintenant le glissement, affiche un curseur de
redimensionnement, et la tête de lecture porte une poignée visible qui traverse
toute la hauteur au lieu de commencer sous la règle.

**Un déplacement non validé.** En cherchant à reproduire le refus, la validation
des bornes s'est révélée ne porter que sur `editing.selectedClipIds`. Glisser un
clip **non sélectionné** — le cas normal juste après ouverture — laissait la
liste vide : aucune borne vérifiée, aucun refus, aucun message. Le clip glissé
est désormais toujours inclus dans l'ensemble validé, la sélection s'y ajoutant
pour un déplacement groupé.

`ui11_presentation_transport_controls_test.dart` couvre les trois parcours :
glissement puis clic sur la règle, clavier sans panneau focalisé, et refus de
déplacement qui cesse d'avertir une fois le geste relâché. La sévérité du
diagnostic est vérifiée sur sa branche de panne dans
`presentations_ui11_visuals_test.dart` ; sa branche informative est établie par
construction, la fixture ne comportant pas de média vidéo.

## Troisième retour : le canevas clignotait pendant le scrub

Signalé par Yoahn avec une capture d'écran vidéo : l'interface « faisait une
crise d'épilepsie » pendant le défilement de la tête de lecture.

Mesure sur l'enregistrement, en extrayant la luminance moyenne du canevas à dix
images par seconde : pendant le geste, elle oscillait entre 65 et 5 avec dix
inversions en 1,4 seconde, soit environ **sept battements par seconde**, puis se
stabilisait dès le relâchement. Ce n'est pas un panneau qui bouge, c'est un
stroboscope, et sept hertz tombe dans la bande à laquelle la photosensibilité
est documentée.

Cause. `PresentationPreviewTransport.seek` incrémente `mediaEpoch`, et
`_syncMedia` lit tout changement d'epoch comme une discontinuité : il appelle
`sink.release()` puis republie. Chaque seek détruisait donc le décodeur vidéo et
le relançait. `resolveVisual` bascule entre le lecteur vivant, lorsque
`sink.videoFor` répond, et le poster sinon : le sous-arbre alternait entre un
lecteur en cours d'initialisation, donc noir, et l'image fixe.

Le défaut existait avant, mais restait invisible : seul un clic pouvait déplacer
la tête de lecture, ce qui produisait un unique battement. Le glissement livré
au retour précédent en produit sept par seconde, ce qui l'a rendu manifeste.

Première tentative, insuffisante : la synchronisation média a été coalescée
pendant le geste, c'est-à-dire suspendue de bout en bout. Le stroboscope a
disparu, mais la vidéo ne suivait plus la tête de lecture et le basculement
poster vers lecteur se produisait au relâchement, à l'endroit le plus visible.
Le remède traitait le symptôme du mauvais côté.

Correctif retenu, après lecture du sink. `_applyVideo` ne détruit rien quand la
ressource et le clip ne changent pas : il se contente de déplacer le décodeur,
et son commentaire le dit explicitement. Le teardown venait donc entièrement de
`_syncMedia`, qui appelait `sink.release()` sur tout changement d'epoch, seek
compris.

La sémantique de `mediaEpoch` est conservée — un test existant affirme
délibérément qu'un scrub manuel invalide l'epoch, et le contrat n'a pas été
touché. Seule la réaction change : pendant un geste, l'epoch est adopté et la
frame publiée sans libération. Le décodeur reste vivant et cherche sa position,
donc **l'image suit la tête de lecture**, et plus rien n'est détruit puis
reconstruit entre deux échantillons. Le basculement unique poster vers lecteur
se produit désormais au premier échantillon du geste plutôt qu'à sa fin.

Le test `UI11 scrubbing does not churn the media between frames` compte les
libérations et les publications des visuals : sur un glissement de six
échantillons il exige que les publications augmentent — l'image suit — et que
les libérations n'augmentent pas. Sans le correctif il en relève huit au lieu
de deux.

`_UnavailableContent` a été extraite vers `presentation_unavailable_content.dart`
pour rendre au fichier la marge nécessaire sous la limite de trois cents lignes.

## Quatrième retour : l'image ne suivait que vers l'arrière

Après le correctif précédent, Yoahn a constaté que le scrub « ne fonctionne que
pour revenir en arrière ».

Mesure sur l'enregistrement, en suivant la colonne de la tête de lecture et le
contenu du canevas image par image : la tête se déplaçait bien dans les deux
sens, mais l'écart d'image valait 0,00 à 0,07 sur les vingt échantillons du
glissement vers l'avant, contre 1,3 à 28 vers l'arrière. L'image était donc
strictement figée en avançant.

Cause, dans `PresentationStudioMediaSink` :

```dart
return timeUs < previous || timeUs - previous > continuityToleranceUs;
```

Reculer satisfait toujours la première condition. Avancer n'est retenu que
au-delà de la tolérance de continuité, quatre cent millisecondes. Ce seuil
existe pour ne pas confondre l'écoulement normal du temps pendant une lecture
avec un saut délibéré, et il est correct pour ce qu'il visait. Mais un
glissement échantillonne à la fréquence de l'écran : chaque pas n'avançait que
d'environ cent cinquante millisecondes de contenu, sous le seuil. Aucun
`seek` n'était donc envoyé au décodeur.

Le sink ne pouvait pas distinguer les deux situations, puisqu'il ne voit que
des écarts de temps. Le transport, lui, sait désormais qu'un geste est en
cours : `synchronize` accepte un paramètre `scrubbing`, faux par défaut, et un
échantillon annoncé comme geste est traité comme un saut quelle que soit son
amplitude. La tolérance de continuité garde son rôle pour tout le reste.

Le test `a paused scrub seeks forward even in steps below the tolerance` envoie
trois pas de cent cinquante millisecondes en pause et exige trois `seek`. Sans
le correctif il n'en relève aucun.

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
| Suite Studio complète | `flutter test` dans `apps/avelune_studio` | 641 verts, 2 ignorés |
| Analyse Studio | `flutter analyze` | `No issues found!` |
| Analyse `map_authoring` | `dart analyze` | `No issues found!` |
| Analyse `map_player_ui` | `dart analyze` | `No issues found!` |
| Analyse `map_editor` (étape CI) | `flutter analyze --no-pub lib test/release` | `No issues found!` |
| Tests CI `map_editor` | 3 fichiers de l'étape CI | 20 verts |
| Transport MCP | `node --import tsx --test test/mutation_server.test.ts` | 34 verts |
| Build macOS | `flutter build macos --debug` | `Avelune Studio.app` produit |

`test/presentation/desktop_workspace_layout_test.dart` échoue sur cette machine
pour une cause d'environnement, et non à cause de ce lot. Son message est
explicite : « Les E/S réelles ne terminent pas entre les frames en 20
secondes ». Le helper `_awaitWhilePumping` impose un budget de vingt secondes
d'horloge réelle à un test qui charge deux cents diagnostics et de nombreux
atlas depuis le disque.

L'attribution a été vérifiée plutôt que supposée : les modifications non
publiées ont été mises de côté par copie, l'arbre ramené au commit de base, et
le test relancé seul **trois fois de suite — trois échecs**, à une charge
machine pourtant plus basse que lors des exécutions réussies du matin. Le
défaut préexiste donc au lot.

Ce test est repassé au vert, dans la suite complète, une fois la machine
revenue au calme, ce qui confirme l'attribution.

Deux facteurs mesurés sur la machine au moment des essais : `fileproviderd`
consommait 94 % d'un cœur en continu, saturant le système de fichiers, et
`/var/folders/.../T/` contenait 533 entrées pour 2,3 Go de fixtures
temporaires laissées par des exécutions précédentes. Ce dossier n'a pas été
nettoyé : d'autres sessions peuvent s'en servir, et sa suppression n'appartient
pas à ce lot. Le budget de vingt secondes n'a pas été relevé non plus — ce
serait masquer la fragilité du test plutôt que la traiter.

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
| `ui11-08-playhead-scrub.png` | Tête de lecture déplacée au glissement, avec sa poignée dans la règle |
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
