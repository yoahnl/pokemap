# Contrat vidéo d’introduction V0

## Cible

La V0 lit les vidéos d’introduction des jeux installés sur Android, iOS et
macOS. Le Hub utilise le lecteur Flutter officiel
[`video_player`](https://pub.dev/packages/video_player), qui annonce ces trois
plateformes ainsi que le Web. PokeMap n’active cependant pas la lecture depuis
un fichier local sur le Web, car
[`VideoPlayerController.file`](https://pub.dev/documentation/video_player/latest/video_player/VideoPlayerController/VideoPlayerController.file.html)
n’y est pas pris en charge.

Windows et Linux ne font pas partie de la cible vidéo V0. Sur une plateforme
non prise en charge, ou si le décodeur refuse le média, le joueur voit le poster
installé puis peut continuer vers le titre. Sans poster valide, le titre est
affiché directement.

## Profil média accepté

- conteneur MP4 ;
- vidéo H.264 (`avc1` ou `avc3`) ;
- audio AAC (`mp4a`) optionnel ;
- 1920 × 1080, 12 000 kbit/s, 100 Mio et 2 minutes maximum ;
- poster PNG, JPEG ou WebP obligatoire dans le projet ;
- sous-titres WebVTT UTF-8 optionnels.

L’éditeur copie les sources validées dans les assets du projet. L’export
reprojette ces fichiers sous `presentation/intro/` et l’installation vérifie
leur inventaire, leur type et leur contenu avant exposition au lecteur.

## Comportement joueur

- l’action **Passer** reste disponible pendant la lecture ;
- la préférence de mouvement réduit affiche le poster ou saute l’intro selon
  le choix de l’auteur ;
- une mise en arrière-plan suspend la vidéo et une reprise restaure la lecture ;
- le volume vaut `volume principal × volume musique` ;
- les sous-titres WebVTT sont rendus par la surface joueur ;
- une erreur d’initialisation ou de décodage ne bloque jamais l’écran titre ;
- **Rejouer** n’est proposé qu’après un fallback et si l’auteur l’autorise.

Le format reste volontairement étroit pour que la prévalidation de l’éditeur,
le paquet installé et les décodeurs mobiles/desktop partagent le même contrat.
