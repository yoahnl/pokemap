# Revue exhaustive des tickets TO REVIEW — clôture honnête

Date de la revue : 2026-09-14  
Projet : PokeMap  
Révision examinée : `6e8df07da95d556c912658dcc5263b1071594f43` (`main))  
Rapport demandé : mission de revue et de nettoyage, sans suppression de tickets de maps.

## Résumé

La revue ne passe aucun ticket en DONE. Ce n’est pas un échec de la mission : les preuves fraîches montrent soit un défaut fonctionnel réel, soit une validation manuelle/visuelle/matérielle encore explicitement exigée. Les 42 tickets dont le résultat principal est une map, un asset ou du contenu de niveau ont été exclus comme demandé et listés séparément pour suppression future.

| Mesure | Résultat |
|---|---:|
| TO REVIEW au relevé initial | 84 |
| Tickets de création de maps exclus | 42 |
| Tickets réellement reviewés | 42 |
| Passés en DONE | 0 |
| Conservés en TO REVIEW — écart fonctionnel/technique | 6 |
| Conservés en TO REVIEW — validation manuelle nécessaire | 36 |
| Obsolètes/doublons déclarés | 0 |
| Correctifs laissés dans le checkout | 0 |
| Commentaires Notion ajoutés | 42/42 |
| Tickets maps supprimés | 0 |

Aucun statut Notion n’a été changé : les 42 tickets reviewés restent `TO REVIEW`. Les tickets maps n’ont reçu aucune modification.

## Règles de périmètre et classification

- F — création de map : contenu spécifique, import d’un lot de contenu, asset de map, carte régionale ou reprise d’un niveau. Exclu de la review ; recommandation DELETE future.
- C — travail fonctionnel restant : défaut/gap actuel identifié dans le code ou un critère non rempli. Verdict `KEEP_TO_REVIEW`.
- D — validation manuelle nécessaire : code et preuves structurelles présents, mais la fiche demande un appareil, un build installé, une écoute, une capture ou l’acceptation artistique de Yoahn. Verdict `NEEDS_MANUAL_VALIDATION`.
- Aucun ticket n’a été classé A/DONE, B/correctif clôturant, ou E/obsolète-doublon. L’absence d’identifiant stable n’est pas considérée seule comme preuve d’obsolescence.
- Les cas frontières ont été tranchés par le résultat principal : `BETA-WLD-001` et `POST-WLD-NPC-HITBOX-001` restent des capacités génériques ; `POST-UI-OW-010` reste un ticket de runtime/voyage ; les lots Train/asset/map spécifiques sont exclus.

## Audit initial obligatoire

```text
=== pwd ===
/Users/karim/Project/pokemonProject
=== git branch --show-current ===
main
=== git status --short --untracked-files=all ===
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
=== git diff --stat ===
 .../lib/src/presentation/flame/battle_overlay_component.dart        | 3 +++
 packages/map_runtime/test/playable_map_game_input_test.dart         | 6 ++++++
 2 files changed, 9 insertions(+)
=== git log --oneline -n 10 ===
6e8df07da update
45cea6b41 feat(runtime): add presentation cinematic depth and music management tests
97cf81829 feat(player): prepare presentation video sources and adjust touch controls
fe80a47fd fix(player): neutralize held inputs across runtime transitions (OW-007)
c0c61a0d1 fix/player: add contextual taps and hidden item search (OW-006)
eb26dbfc8 feat(player): integrate touch running gestures and preferences (OW-005)
cee90931 feat(player): replace fixed joystick with floating touch gestures (OW-004)
297172a3d feat(player): add minimal overworld HUD primitives (OW-003)
e289b4c54 feat(player): arbitrate touch keyboard and controller input (OW-002)
487a3352a feat(runtime): project and revalidate overworld interactions (OW-001)
```

Les deux fichiers runtime/test étaient déjà modifiés avant la mission. Ils recouvrent directement `BETA-BAT-007` ; ils n’ont pas été édités, restaurés ni attribués à cette revue. Pendant la mission, `packages/map_player_ui/analysis_options.yaml` a reçu un hunk `exclude: build/**` provenant d’une action concurrente/outillage ; il a été préservé et n’est pas attribué à la mission.

## Inventaire initial exhaustif — 84 tickets TO REVIEW

| # | Code/ID | Ticket | URL Notion | Gate bêta | Catégorie | Création de map ? | Type de validation |
|---:|---|---|---|---|---|---|---|
| 1 | `BETA-CIN-084` | Certifier localement performance et teardown des holds interactifs | <https://app.notion.com/p/3c2197a7bfa581a8b7c3d30eca28d83f> | Oui | D — validation manuelle nécessaire | Non | Profile/appareil + visuel |
| 2 | `BETA-CIN-086` | Revoir et clôturer la gate Bêta Presentation interactive | <https://app.notion.com/p/3c2197a7bfa5811fa2ade09ab537f857> | Oui | D — validation manuelle nécessaire | Non | Profile/appareil + visuel |
| 3 | `—` | POST-WLD-ASSET-L00-01 — Vérifier le socle et l’état des imports V2 | <https://app.notion.com/p/3d0197a7bfa5814abbc2cc6a1503221f> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 4 | `BETA-WLD-001` | Implémenter un contrat générique de porte animée | <https://app.notion.com/p/3b9197a7bfa581809751e2983d9777b5> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 5 | `—` | POST-WLD-ASSET-L02-01 — Créer le gravier raccordable de la gare | <https://app.notion.com/p/3d0197a7bfa5818e8d0be04df8d7ba28> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 6 | `—` | POST-WLD-ASSET-L02-02 — Créer les sols secondaires et leurs transitions | <https://app.notion.com/p/3d0197a7bfa5815e8db2c2a3f1f7f96b> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 7 | `BETA-BAT-009` | Rendre l’interface de combat lisible et non occultante | <https://app.notion.com/p/3be197a7bfa581bb9d6cfe7bbdefc0b8> | Oui | D — validation manuelle nécessaire | Non | Player/Hub + visuel/audio |
| 8 | `—` | POST-WLD-ASSET-L02-03 — Créer les sols intérieurs en bois et tatami | <https://app.notion.com/p/3d0197a7bfa58181ac6cd4db17a47a56> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 9 | `—` | POST-WLD-ASSET-L02-04 — Créer les surfaces régionales et les réseaux d’eau | <https://app.notion.com/p/3d0197a7bfa581dc8378ceb1375b5337> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 10 | `—` | POST-WLD-ASSET-L02-05 — Créer les silhouettes d’arbres complémentaires | <https://app.notion.com/p/3d0197a7bfa5819eb633deaff41fded6> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 11 | `—` | POST-WLD-ASSET-L02-06 — Créer la végétation basse et les cultures | <https://app.notion.com/p/3d0197a7bfa581fd8ca5c4d2ebb8e1f8> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 12 | `—` | POST-WLD-ASSET-L02-07 — Créer les rochers et le bois mort | <https://app.notion.com/p/3d0197a7bfa581c7b108e5d86f492eff> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 13 | `—` | POST-WLD-ASSET-L02-08 — Créer les escaliers, ponts et entrées de tunnel | <https://app.notion.com/p/3d0197a7bfa581e0aa1cdf78906d17bf> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 14 | `—` | POST-WLD-ASSET-L05-01 — Créer les patrons des objets de quête dans le monde | <https://app.notion.com/p/3d0197a7bfa581c28c83c38bd7d117f7> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 15 | `—` | POST-WLD-ASSET-L05-02 — Créer les icônes de quête et les poinçons | <https://app.notion.com/p/3d0197a7bfa581f1b2c6ef7ecb5d443c> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 16 | `—` | POST-WLD-ASSET-L05-03 — Créer les documents inspectables et le carnet | <https://app.notion.com/p/3d0197a7bfa581119ee4e863c3523aca> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 17 | `—` | POST-WLD-ASSET-L05-04 — Établir le roster et produire les sprites overworld | <https://app.notion.com/p/3d0197a7bfa581bb8724d25d6f05e602> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 18 | `BETA-ENC-007` | Porter les rencontres directement sur les calques Smart Tile | <https://app.notion.com/p/3c5197a7bfa58123afc6e2cfc1cd8753> | Oui | D — validation manuelle nécessaire | Non | Player/Hub + visuel/audio |
| 19 | `—` | POST-WLD-ASSET-L05-05 — Créer les portraits et les silhouettes de dresseurs | <https://app.notion.com/p/3d0197a7bfa581978196d432d1f9f2f1> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 20 | `—` | POST-WLD-ASSET-L05-06 — Créer les éléments visuels des scènes narratives | <https://app.notion.com/p/3d0197a7bfa5812d8784c6c8c25b8871> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 21 | `—` | POST-WLD-ASSET-L06-01 — Créer la rame de la ligne des Cèdres | <https://app.notion.com/p/3d0197a7bfa581358628ee6385693728> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 22 | `—` | POST-WLD-ASSET-L06-03 — Créer les modules de voiture et les panoramas de trajet | <https://app.notion.com/p/3d0197a7bfa5812ea5f5fc17e6ddc303> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 23 | `—` | POST-WLD-ASSET-L06-04 — Créer les lumières et les effets électriques | <https://app.notion.com/p/3d0197a7bfa5811095b7fa8436c2e3b6> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 24 | `BETA-BAT-007` | Certifier la surface joueur de combat et son focus | <https://app.notion.com/p/3b9197a7bfa5815baff8eb63e15cee89> | Oui | D — validation manuelle nécessaire | Non | Player/Hub + visuel/audio |
| 25 | `—` | POST-WLD-ASSET-L06-05 — Créer la pluie, la brume et la poussière | <https://app.notion.com/p/3d0197a7bfa5811d8286d4557151469a> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 26 | `—` | POST-WLD-ASSET-L06-06 — Créer les fonds de combat par environnement | <https://app.notion.com/p/3d0197a7bfa5815c9836cd6711ed39f2> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 27 | `—` | POST-WLD-ASSET-M00 — M00 — Décliner les assets de Chambre de la pension d’Hanazuki | <https://app.notion.com/p/3d0197a7bfa5818a9d5cc6055246c943> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 28 | `—` | POST-WLD-ASSET-M01 — M01 — Décliner les assets de Village d’Hanazuki | <https://app.notion.com/p/3d0197a7bfa58189808be259404dffe4> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 29 | `—` | POST-WLD-ASSET-M02 — M02 — Décliner les assets de Colline du sanctuaire | <https://app.notion.com/p/3d0197a7bfa58199b65ed8ae43ff9be7> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 30 | `—` | POST-WLD-ASSET-M03 — M03 — Décliner les assets de Gare d’Hanazuki | <https://app.notion.com/p/3d0197a7bfa581bebc9bec71e00d4859> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 31 | `—` | POST-WLD-ASSET-M03-I — M03-I — Décliner les assets de Intérieur de la gare d’Hanazuki | <https://app.notion.com/p/3d0197a7bfa581729ab2de8a3e1a6f0b> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 32 | `BETA-TRN-001` | Construire et certifier le cycle ligne de vue → exclamation → approche → dialogue → combat | <https://app.notion.com/p/3b9197a7bfa581888eaafac89f2a40e8> | Oui | D — validation manuelle nécessaire | Non | Player/Hub + visuel/audio |
| 33 | `BETA-BAT-011` | Faire parler le journal de combat dans la langue du joueur | <https://app.notion.com/p/3c4197a7bfa58135a470e680c6fd7e6c> | Oui | C — travail fonctionnel restant | Non | Code/tests + correction et revalidation |
| 34 | `BETA-BAT-014` | Donner un son aux attaques, aux coups et aux K.O. | <https://app.notion.com/p/3c5197a7bfa5811a9809f3cabb0ea0f8> | Oui | C — travail fonctionnel restant | Non | Code/tests + correction et revalidation |
| 35 | `BETA-BAT-015` | Mettre la musique des combats, par défaut, par dresseur et par zone | <https://app.notion.com/p/3c5197a7bfa581a1b2cce39758e1f99f> | Oui | C — travail fonctionnel restant | Non | Code/tests + correction et revalidation |
| 36 | `BETA-BAT-018` | Précharger les effets de combat sous le noir de la transition | <https://app.notion.com/p/3c6197a7bfa5814d9de5ec33a462a0f9> | Non | C — travail fonctionnel restant | Non | Code/tests + correction et revalidation |
| 37 | `BETA-BAT-019` | Offrir un panel de transitions de combat par zone et par dresseur | <https://app.notion.com/p/3c6197a7bfa581ebaa1dd04ea671bfc5> | Non | D — validation manuelle nécessaire | Non | Player/Hub + visuel/audio |
| 38 | `BETA-BAT-020` | Faire entendre et lire l'efficacité des attaques en jeu réel | <https://app.notion.com/p/3c6197a7bfa58150aad6c1bc81154eed> | Non | D — validation manuelle nécessaire | Non | Player/Hub + visuel/audio |
| 39 | `BETA-BAT-021` | Donner un retour visuel aux capacités de statut et aux changements de stats | <https://app.notion.com/p/3c6197a7bfa581939313d01784c06002> | Non | D — validation manuelle nécessaire | Non | Player/Hub + visuel/audio |
| 40 | `BETA-BAT-022` | Faire sortir les Pokémon de leur Poké Ball en début de combat | <https://app.notion.com/p/3c6197a7bfa58135aa50fd6d2f01219e> | Non | C — travail fonctionnel restant | Non | Code/tests + correction et revalidation |
| 41 | `—` | POST-UI-OW-010 — Orienter la course et débloquer le voyage en train | <https://app.notion.com/p/3d9197a7bfa581278432fa5cf792e5b9> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 42 | `—` | POST-UI-OW-009 — Corriger le menu mobile et maîtriser la course après essai iPhone | <https://app.notion.com/p/3d9197a7bfa5818e92fbed3ac0e89fea> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 43 | `—` | POST-WLD-TRAIN-COLLISIONS — Corriger les collisions des 38 maps et les zones sans rencontres | <https://app.notion.com/p/3d9197a7bfa581e18485f0ef46091366> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 44 | `POST-UI-OW-007` | POST-UI-OW-007 — Sécuriser les transitions, le multitouch et le cycle de vie | <https://app.notion.com/p/3d9197a7bfa581e1ab36defdffc340c9> | Non | D — validation manuelle nécessaire | Non | iOS/Android + tactile/visuel |
| 45 | `POST-UI-OW-006` | POST-UI-OW-006 — Brancher les actions contextuelles et le toucher direct à portée | <https://app.notion.com/p/3d9197a7bfa5811aa3b8e42e6b127f6d> | Non | D — validation manuelle nécessaire | Non | iOS/Android + tactile/visuel |
| 46 | `POST-UI-OW-005` | POST-UI-OW-005 — Intégrer marche et course au geste tactile | <https://app.notion.com/p/3d9197a7bfa581fda94dcf5748f2f61e> | Non | D — validation manuelle nécessaire | Non | iOS/Android + tactile/visuel |
| 47 | `POST-UI-OW-004` | POST-UI-OW-004 — Remplacer le joystick fixe par un joystick flottant | <https://app.notion.com/p/3d9197a7bfa5812dab8bec1a6d084153> | Non | D — validation manuelle nécessaire | Non | iOS/Android + tactile/visuel |
| 48 | `POST-UI-OW-003` | POST-UI-OW-003 — Créer les primitives premium et les layouts du HUD minimal | <https://app.notion.com/p/3d9197a7bfa581828c8dee764d28f5f7> | Non | D — validation manuelle nécessaire | Non | iOS/Android + tactile/visuel |
| 49 | `—` | POST-WLD-FIDELITY-001 — Reprendre toutes les maps selon les références du Train | <https://app.notion.com/p/3d4197a7bfa5817588cbd9fd0d62c014> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 50 | `—` | POST-START-TRAIN-OPEN-001 — Diagnostiquer l’ouverture du Train bloquée par les fichiers iCloud | <https://app.notion.com/p/3d4197a7bfa58107bed0f12ccfb612a5> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 51 | `—` | POST-WLD-DIALOGUE-002 — Supprimer le clignotement pendant la révélation du texte | <https://app.notion.com/p/3d4197a7bfa581199d9ec016a0ee344a> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 52 | `—` | POST-WLD-MAPS-001 — Classer les maps du Train par région et sous-dossiers | <https://app.notion.com/p/3d4197a7bfa581ca8a71cc17a9346ccd> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 53 | `—` | POST-WLD-LIBRARY-001 — Regrouper et classer les tilesets du Train de 17h42 | <https://app.notion.com/p/3d4197a7bfa5818e83b0c542ad8eeebb> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 54 | `—` | POST-WLD-NPC-HITBOX-001 — Réduire les collisions PNJ aux pieds | <https://app.notion.com/p/3d4197a7bfa581939799c4192e3fb6a7> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 55 | `—` | Corriger l’échec de nouvelle partie et conserver une erreur explicite | <https://app.notion.com/p/3d4197a7bfa58129a5a5d5fed5a92376> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 56 | `—` | MEDIA-07 — Consolidation auteur et preuve de livraison | <https://app.notion.com/p/3d3197a7bfa581579d0ef52624ec12ca> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 57 | `—` | MEDIA-06 — Insertion de médias dans un dialogue compilé | <https://app.notion.com/p/3d3197a7bfa581a1b80cffc0c5bfdd6d> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 58 | `—` | POST-WLD-ASSET-CLEAN-001 — Ranger les assets propres du Train V2 | <https://app.notion.com/p/3d3197a7bfa581be90b4fd78657e8144> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 59 | `POST-UI-MENU-013` | POST-UI-MENU-013 — Certifier fidélité visuelle, navigation, accessibilité et stabilité | <https://app.notion.com/p/3d2197a7bfa581ffa849d141c6a3de95> | Non | D — validation manuelle nécessaire | Non | Hub natif + visuel/accessibilité |
| 60 | `POST-UI-MENU-012` | POST-UI-MENU-012 — Réaliser les Options et leurs réglages réellement appliqués | <https://app.notion.com/p/3d2197a7bfa581f1ac19ce447f0314a5> | Non | D — validation manuelle nécessaire | Non | Hub natif + visuel/accessibilité |
| 61 | `POST-UI-MENU-011` | POST-UI-MENU-011 — Harmoniser sauvegarde, confirmations et retour au titre | <https://app.notion.com/p/3d2197a7bfa58191adf1d8e398a8d899> | Non | C — travail fonctionnel restant | Non | Code/tests + correction et revalidation |
| 62 | `POST-UI-MENU-007` | POST-UI-MENU-007 — Réaliser la carte régionale illustrée et les lieux interactifs | <https://app.notion.com/p/3d2197a7bfa581d29d20de497b776928> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 63 | `POST-UI-MENU-004` | POST-UI-MENU-004 — Réaliser le menu principal illustré et sa navigation | <https://app.notion.com/p/3d2197a7bfa5810c83bfe6b87e7c300a> | Non | D — validation manuelle nécessaire | Non | Hub natif + visuel/accessibilité |
| 64 | `POST-CIN-MEDIA-003` | MEDIA-03 — Audio, focus et lifecycle communs | <https://app.notion.com/p/3d2197a7bfa5813cbc21fa6d8fb8e44c> | Non | D — validation manuelle nécessaire | Non | Hub + audio/vidéo |
| 65 | `—` | Le train de 17h42 — Réparer le chargement project.item_catalog_invalid | <https://app.notion.com/p/3d2197a7bfa5815d864bd9916dd4cca3> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 66 | `—` | POST-WLD-ASSET-L08-IMPORT — Importer le kit Aohara validé et vérifier son usage dans PokeMap | <https://app.notion.com/p/3d2197a7bfa5817bb639eea41a2177c6> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 67 | `POST-WLD-TRAIN-M00-M03-001` | POST-WLD-TRAIN-M00-M03-001 — Reconstruire les quatre vues du Train dans PokeMap | <https://app.notion.com/p/3d2197a7bfa5818db420cb2bf9af1cbe> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 68 | `—` | POST-WLD-L03-PLAY-001 — Intégrer les bâtiments du lot 3 dans une zone jouable | <https://app.notion.com/p/3d1197a7bfa58166a450e172d880873e> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 69 | `—` | POST-WLD-ASSET-L01-IMPORT — Importer le lot ferroviaire L01 approuvé dans le Train | <https://app.notion.com/p/3d0197a7bfa581a88755e7bd749d7fcf> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 70 | `—` | POST-WLD-ASSET-CHARTE-001 — Charte et bible de production des assets V2 | <https://app.notion.com/p/3d0197a7bfa581cbb09cedeed3c5bd9e> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 71 | `—` | POST-WLD-ASSET-RAILS-001 — Créer les rails horizontaux de Hanazuki | <https://app.notion.com/p/3d0197a7bfa581d69578d323efd63818> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 72 | `—` | POST-WLD-ASSET-PROPS-001 — Créer les accessoires de la gare de Hanazuki | <https://app.notion.com/p/3d0197a7bfa581f8add0e37d37e22221> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 73 | `—` | POST-WLD-ASSET-GARE-001 — Créer la gare rurale de Hanazuki depuis la référence | <https://app.notion.com/p/3d0197a7bfa581e1a4b2feeebacf748d> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 74 | `—` | POST-WLD-ASSET-PATRONS-001 — Mesurer le corpus PSDK et préparer les patrons d’assets Avelune | <https://app.notion.com/p/3cf197a7bfa58111a3f2d824c623f93b> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 75 | `POST-AVL-ICON-001` | Intégrer l’identité Avelune — icônes natives, démarrage et accueil | <https://app.notion.com/p/3cf197a7bfa581f9a2bfc463cdfd443e> | Non | D — validation manuelle nécessaire | Non | Build/appareil + visuel |
| 76 | `POST-WLD-ART-001` | POST-WLD-ART-001 — Préparer les premiers essais de terrains du Train de 17h42 | <https://app.notion.com/p/3cf197a7bfa581db8ef8de93b9dddd4c> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 77 | `POST-WLD-SMART-004` | Refondre le parcours no-code du Smart Tiles Studio | <https://app.notion.com/p/3cd197a7bfa5816f9716e134e43f32a5> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 78 | `POST-WLD-SMART-003` | Simplifier le parcours Chemin du Smart Tiles Studio et prévisualiser les images | <https://app.notion.com/p/3cd197a7bfa581729e16e53792c49526> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 79 | `POST-AVL-CONTROL-001` | Piloter Avelune via une API locale et un MCP de certification macOS | <https://app.notion.com/p/3ca197a7bfa581918d20e1439329d2b2> | Non | D — validation manuelle nécessaire | Non | Build/appareil + visuel |
| 80 | `POST-WLD-GRASS-001` | Refondre les hautes herbes du Train de 17h42 | <https://app.notion.com/p/3c8197a7bfa581309a18d78fbce90fb5> | Non | F — création de map | Oui | Exclue de la revue ; suppression future |
| 81 | `—` | Refondre l’intro et la pré-session du Train dans une grammaire proche de Pokémon Platine | <https://app.notion.com/p/3c7197a7bfa581d6877cd9a65a7028c7> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 82 | `—` | Nettoyer les artefacts obsolètes du projet Train de 17h42 | <https://app.notion.com/p/3c7197a7bfa581f8b9a8edefc52247a5> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 83 | `—` | Découpler les mutations Smart Tile des dettes globales de sauvegarde | <https://app.notion.com/p/3c5197a7bfa581da9436efaee3dea0d9> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |
| 84 | `POST-SYS-002` | Corriger le contraste des dialogues joueur dans le Hub | <https://app.notion.com/p/3c2197a7bfa581248f48cf171543ed8d> | Non | D — validation manuelle nécessaire | Non | Projet/Hub + validation Yoahn |

## Tableau complet des 42 tickets réellement reviewés

| Code/ID | Ticket | Catégorie | Gate bêta | Verdict | Critères vérifiés | Tests | Correctif effectué ? | Blocage restant | Statut Notion final |
|---|---|---:|---|---|---|---|---|---|---|
| `BETA-CIN-084` | Certifier localement performance et teardown des holds interactifs | D | Oui | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Mesurer localement la réactivité et la libération des ressources sur des holds longs et répétés. Bloquant : Le run profile local sur device qui produit measurements.json. Le validateur, le CLI et la certification de teardown sont en place et n'attendent que ça. | Harnais/certification structurels relus ; profile/receipt frais absent. | Non | Les latences, frames lentes, RSS et compteurs de teardown respectent les seuils, sans faux décodeur. | TO REVIEW |
| `BETA-CIN-086` | Revoir et clôturer la gate Bêta Presentation interactive | D | Oui | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Effectuer la revue finale des contrats, preuves, UX réelle et limites avant de déclarer Presentation dialoguée terminée. Bloquant : Confondre tests verts, ancienne preuve bêta ou statut Notion avec une validation produit actuelle. | Harnais/certification structurels relus ; profile/receipt frais absent. | Non | Parcours positif/négatif lisible, risques résiduels acceptés, aucune dépendance ouverte. | TO REVIEW |
| `BETA-WLD-001` | Implémenter un contrat générique de porte animée | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Implémenter un contrat générique de porte animée Bloquant : Fonctionnalité utile mais explicitement hors gate bêta. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | One-shot, verrouillage et warp sont cohérents sans casser le parcours. | TO REVIEW |
| `BETA-BAT-009` | Rendre l’interface de combat lisible et non occultante | D | Oui | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. HUD PV/XP aligné sur la direction sombre Field Manual : plaque biseautée, hiérarchie nom/niveau/PV/XP, contraste stable même avec une ancienne palette battle claire. Bloquant : Le critère géométrique est certifié. Il reste UNIQUEMENT la preuve produit finale déjà consignée depuis le 2026-08-17 : une capture réelle du combat dans le Hub, qui exige de réexporter/réinstaller Le Train de  | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Aucune commande ni information critique n’est occultée ; le défaut compact est accepté ou corrigé. | TO REVIEW |
| `BETA-ENC-007` | Porter les rencontres directement sur les calques Smart Tile | D | Oui | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Les hautes herbes portent directement leur table de rencontres ; peinture et effacement prennent effet immédiatement. Bloquant : Aucun manque d’implémentation identifié. Reste la validation visuelle manuelle par Yoahn dans le Player installé. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Seules les sources Smart Tile attendues déclenchent une rencontre jouable. | TO REVIEW |
| `BETA-BAT-007` | Certifier la surface joueur de combat et son focus | D | Oui | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Certifier la surface joueur de combat et son focus Bloquant : Après autorisation utilisateur, version iOS profile corrigée installée et lancée sur l’iPhone physique. Validation des boutons en combat encore attendue ; pilote Marionette non connecté. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Chaque commande reste touchable, le focus ne se perd pas et aucun overlay ne recouvre l’action. | TO REVIEW |
| `BETA-TRN-001` | Construire et certifier le cycle ligne de vue → exclamation → approche → dialogue → combat | D | Oui | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Certifier le cycle complet ligne de vue → approche → combat Bloquant : La machine à états qui enchaîne emote, approche, dialogue et combat. Toutes les briques appelées existent. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Exclamation bien placée/lisible, approche cohérente et combat déclenché une seule fois. | TO REVIEW |
| `BETA-BAT-011` | Faire parler le journal de combat dans la langue du joueur | C | Oui | `KEEP_TO_REVIEW` | Écart actuel confirmé : Le chemin de switch conserve des IDs d’espèce bruts et le resolver n’est pas injecté partout ; corriger les messages concernés et renforcer le test d’ordre avant le replay français. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Le chemin de switch conserve des IDs d’espèce bruts et le resolver n’est pas injecté partout ; corriger les messages concernés et renforcer le test d’ordre avant le replay français. | TO REVIEW |
| `BETA-BAT-014` | Donner un son aux attaques, aux coups et aux K.O. | C | Oui | `KEEP_TO_REVIEW` | Écart actuel confirmé : Le son de capacité/impact/chute est présent, mais le cri d’espèce au K.O. manque dans le planner ; brancher le média et tester espèce/pitch/ordre. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Le son de capacité/impact/chute est présent, mais le cri d’espèce au K.O. manque dans le planner ; brancher le média et tester espèce/pitch/ordre. | TO REVIEW |
| `BETA-BAT-015` | Mettre la musique des combats, par défaut, par dresseur et par zone | C | Oui | `KEEP_TO_REVIEW` | Écart actuel confirmé : La musique de victoire repose sur un booléen global sans distinction sauvage/dresseur ; corriger l’ordre XP/musique et prouver les sorties/fuite/capture. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | La musique de victoire repose sur un booléen global sans distinction sauvage/dresseur ; corriger l’ordre XP/musique et prouver les sorties/fuite/capture. | TO REVIEW |
| `BETA-BAT-018` | Précharger les effets de combat sous le noir de la transition | C | Non | `KEEP_TO_REVIEW` | Écart actuel confirmé : Le callback de reveal peut contourner la préchauffe pendante ; partager la barrière readiness/budget et ajouter le test host d’ordonnancement. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Le callback de reveal peut contourner la préchauffe pendante ; partager la barrière readiness/budget et ajouter le test host d’ordonnancement. | TO REVIEW |
| `BETA-BAT-019` | Offrir un panel de transitions de combat par zone et par dresseur | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Le projet n'a qu'une transition sauvage et une dresseur pour tout le jeu ; la référence en a 23, variées par génération et par contexte Bloquant : battleTransitions ne porte qu'un wildTransitionId et un trainerTransitionId globaux ; le registre moteur ne connaît que rby_wild et dpp_trainer. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Choix, tirage déterministe, fallback et rendu des transitions sont compréhensibles. | TO REVIEW |
| `BETA-BAT-020` | Faire entendre et lire l'efficacité des attaques en jeu réel | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. En recette, aucun combat ne montre le message d'efficacité ni ne différencie le son d'impact — alors que toute la mécanique existe déjà côté moteur Bloquant : Rien à CODER a priori : le mécanisme complet existe (BAT-013/014) — le problème est en aval, très probablement dans la DONNÉE du projet. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Le joueur entend/lit l’efficacité au bon moment et la décision de badge est explicite. | TO REVIEW |
| `BETA-BAT-021` | Donner un retour visuel aux capacités de statut et aux changements de stats | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Une capacité sans dégâts (Jet de Sable, Intimidation, Rétrécissement…) ne montre RIEN à l'écran ; la référence joue une animation d'aura sur la cible à chaque hausse/baisse de stat Bloquant : battle_turn_animation_planner ne connaît ni modifyStats ni statStage : un move de statut produit ses messages mais aucun accent visuel. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Les étapes restent lisibles et ordonnées ; les limites précision/évasion sont documentées. | TO REVIEW |
| `BETA-BAT-022` | Faire sortir les Pokémon de leur Poké Ball en début de combat | C | Non | `KEEP_TO_REVIEW` | Écart actuel confirmé : Le critère Ball individuelle reste partiel : capturedWith manque et le runtime retombe sur ball_1 ; propager la source de Ball puis rejouer send-out/remplacement. | Ciblé runtime/core : +409 runtime ou suites core/gameplay/battle vertes ; gaps non couverts par ces assertions. | Non | Le critère Ball individuelle reste partiel : capturedWith manque et le runtime retombe sur ball_1 ; propager la source de Ball puis rejouer send-out/remplacement. | TO REVIEW |
| `—` | POST-UI-OW-010 — Orienter la course et débloquer le voyage en train | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Rails/attaches affinés et ballast plus fin dans les deux plans alpins.50s et audioV8 préservés. Cartouche0.1.8 SHA2565ff59576bc8ed155672140b7032585e3d1fd7061648795e2df4e02a546ce7ea0 ;10référ Bloquant : Revue visuelle des railsV9 et replay téléphone. Raffinement des fenêtres proposé précédemment reste non implémenté, vitres encoreV8. Aucun verdict artistique sur l’escalier pension inclus dans le snapshot. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `—` | POST-UI-OW-009 — Corriger le menu mobile et maîtriser la course après essai iPhone | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. 220 tests Flutter ciblés +8tests MCP PASS ; analyses propres ; build Avelune iOS release installé/lancé sur iPhone15Pro. Nouveau menu validé sur simulateur portrait/paysage. Train valid=true Bloquant : Importer la cartouche0.1.1 dans Avelune et confirmer visuellement le nouveau personnage/la course sur téléphone ; confort seuil95/85 à accepter par Yoahn. Code non committé. Override version export MCP non expo | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `POST-UI-OW-007` | POST-UI-OW-007 — Sécuriser les transitions, le multitouch et le cycle de vie | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Aucune direction, course ou interaction fantôme après un menu, une scène, une rotation, une perte de focus ou une déconnexion. Bloquant : Revue de Yoahn ; certification matérielle, visuelle finale et performance OW008. Tests manette simulés uniquement ; MCP configuré worker.exited code78. | Pass indépendant UI : 118 passés, 1 skip, 6 échecs ; voir § Tests. | Non | Aucun geste fantôme, input bloqué ou état incohérent après lifecycle. | TO REVIEW |
| `POST-UI-OW-006` | POST-UI-OW-006 — Brancher les actions contextuelles et le toucher direct à portée | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Une action réelle, un emplacement stable : capsule tactile ou invite matérielle, avec tap direct sur une cible admissible et aucune configuration auteur. Bloquant : Revue de Yoahn. Certification matérielle/performance et visuelle finale OW008 ; interactions Train non certifiées à cause de l'erreur EventV2 uwu préexistante ; MCP live code78. | Pass indépendant UI : 118 passés, 1 skip, 6 échecs ; voir § Tests. | Non | Hitbox, latence et action contextuelle correspondent au geste attendu. | TO REVIEW |
| `POST-UI-OW-005` | POST-UI-OW-005 — Intégrer marche et course au geste tactile | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Course demandée par l’éloignement du pouce, sans bouton R permanent et avec autorisation runtime, hystérésis et relâchement sûrs. Bloquant : Calibration et essais physiques iOS/Android, vidéo et recette Player réel au lot 008 ; serveur MCP configuré worker.exited code78, checkout isolé vérifié. | Pass indépendant UI : 118 passés, 1 skip, 6 échecs ; voir § Tests. | Non | Course fiable, seuils confortables, aucune dérive ni conflit avec les autres inputs. | TO REVIEW |
| `POST-UI-OW-004` | POST-UI-OW-004 — Remplacer le joystick fixe par un joystick flottant | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Un joystick invisible au repos, ancré au pouce dans une zone autorisée, réactif et compatible avec le multitouch. Bloquant : Revue utilisateur ; calibration/vidéo téléphone et certification physique008. Ancien devhost brut inchangé. Serveur MCP configuré worker exit78, serveur checkout isolé vérifié. | Pass indépendant UI : 118 passés, 1 skip, 6 échecs ; voir § Tests. | Non | Placement, direction, relâchement et confort sont acceptables à l’échelle joueur. | TO REVIEW |
| `POST-UI-OW-003` | POST-UI-OW-003 — Créer les primitives premium et les layouts du HUD minimal | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Menu discret, capsules contextuelles et joystick en verre sombre, intégrés au design system Player et adaptés aux orientations. Bloquant : Primitives vérifiées et committées, validation utilisateur attendue. | Pass indépendant UI : 118 passés, 1 skip, 6 échecs ; voir § Tests. | Non | Les primitives restent lisibles et ne promettent pas une intégration non livrée. | TO REVIEW |
| `—` | POST-START-TRAIN-OPEN-001 — Diagnostiquer l’ouverture du Train bloquée par les fichiers iCloud | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Copie conservée : /Users/karim/Desktop/pokeMap Project/le_train_de_17h42, manifest du 7 septembre 2026 22:50, 38 cartes. Copie ancienne : /Users/karim/Desktop/le_train_de_17h42, manifest du  Bloquant : Validation utilisateur du diagnostic et du rangement. L’ouverture de la copie récente est vérifiée ; aucune certification globale de jouabilité ou d’intégrité des médias n’est revendiquée. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `—` | POST-WLD-DIALOGUE-002 — Supprimer le clignotement pendant la révélation du texte | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. 28 tests de dialogue et portraits réussis ; analyse ciblée sans erreur. Clé du fondu stabilisée par mode de dialogue ; les révisions de commandes restent actuelles. Commit source poussé sur  Bloquant : Rejouer le dialogue dans le build natif puis validation visuelle par Yoahn. La tentative de build macOS a été interrompue ; aucune preuve native revendiquée. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `—` | POST-WLD-NPC-HITBOX-001 — Réduire les collisions PNJ aux pieds | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Contact PNJ proportionnel à la grille (24×16 px sur grille 32), réservé aux pieds. Les déplacements scriptés réservent leur contact au sol au lieu du sprite 2×2. Terrain et collisions explic Bloquant : Rejeu natif du contournement, du contact et des interactions puis validation par Yoahn ; le build macOS a été interrompu, aucun verdict visuel revendiqué. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `—` | Corriger l’échec de nouvelle partie et conserver une erreur explicite | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Cause reproduite sur le Train, correction validée avec les vrais fichiers/images et révision stable. 96 tests passants dans les commandes finales. Commit ciblé : 10 fichiers, +295/-18. Six m Bloquant : Rejouer sur l’iPhone avec un nouveau build contenant 204bb497f. Échec indépendant du test existant de popup d’options/manette, également reproduit avec sa version HEAD ; aucun changement de ce flux. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `—` | MEDIA-07 — Consolidation auteur et preuve de livraison | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. MEDIA07 implémenté : historique canonique, formulaires de droits partagés, configuration et aperçu synchronisés, navigation Dialogue vers Presentation, fixtures PNJ/objet et livraison offlin Bloquant : Dernier contrôle visuel/sonore sur Mac déverrouillé et verdict visuel de Yoahn. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `—` | MEDIA-06 — Insertion de médias dans un dialogue compilé | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Contre-audit MEDIA06 : 3 défauts Editor corrigés (durée de vie du lecteur, cadrage, faux warning de branche). 185 tests Dart/Flutter +2 MCP verts. Validation finale retenue : images vidéo na Bloquant : Captures pendant la vidéo noires ; reprise du dialogue confirmée mais contenu vidéo non confirmé. Pilotage macOS intermittent : Session suspendue puis CUA noWindowsAvailable. Réponse à la demande de remettre Hu | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `POST-UI-MENU-013` | POST-UI-MENU-013 — Certifier fidélité visuelle, navigation, accessibilité et stabilité | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Refonte mobile : accueil en grille, six Pokémon visibles en portrait, listes et fiches côte à côte en paysage, images compactes et barre de carte tactile. Réordonnancement sauvegardé puis vé Bloquant : Revue artistique et prise en main mobile par Yoahn ; Android natif et appareils physiques, accessibilité native/manette, export installé frais et parcours globaux. Quêtes reportées à plus tard. Certification gl | Pass indépendant UI : 118 passés, 1 skip, 6 échecs ; voir § Tests. | Non | Navigation, cibles, accessibilité, stabilité et rendu respectent la fiche. | TO REVIEW |
| `POST-UI-MENU-012` | POST-UI-MENU-012 — Réaliser les Options et leurs réglages réellement appliqués | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Lot 8 / 012 : six catégories Options, préférences persistées et appliquées au titre et en pause ; revue de clôture avec défauts réels corrigés et commit isolé. Bloquant : Revue Yoahn avant DONE. Écoute physique des volumes, manette réelle, vibrations mobiles et observation chronométrée d'un vrai dialogue narratif restent non certifiées. Transmission runtime, persistance, rendu F | Pass indépendant UI : 118 passés, 1 skip, 6 échecs ; voir § Tests. | Non | Chaque réglage est réellement appliqué et persiste selon le contrat. | TO REVIEW |
| `POST-UI-MENU-011` | POST-UI-MENU-011 — Harmoniser sauvegarde, confirmations et retour au titre | C | Non | `KEEP_TO_REVIEW` | Écart actuel confirmé : La suite actuelle menu8_save_test.dart échoue sur 6 scénarios : le tap Retour au titre tombe à y=1007,5 hors de la racine 1100x1000 ; réparer, obtenir 14/14, puis rejouer en natif. | menu8_save_test.dart : 14 tests, 8 passés, 6 échoués. | Non | La suite actuelle menu8_save_test.dart échoue sur 6 scénarios : le tap Retour au titre tombe à y=1007,5 hors de la racine 1100x1000 ; réparer, obtenir 14/14, puis rejouer en natif. | TO REVIEW |
| `POST-UI-MENU-004` | POST-UI-MENU-004 — Réaliser le menu principal illustré et sa navigation | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. MENU-D validé selon la demande explicite de Yoahn, après correction de deux P2 : retour au titre inaccessible si Options indisponible et durée standalone perdue à la sauvegarde. Revue indépe Bloquant : Correction du 2026-09-07 : rejouer dans le Hub compilé l'ouverture du menu pendant combat et ses transitions ; validation Yoahn requise. Échec séparé du test de focus Options signalé. Acceptation historique MEN | Pass indépendant UI : 118 passés, 1 skip, 6 échecs ; voir § Tests. | Non | Navigation et illustration restent correctes après les corrections récentes. | TO REVIEW |
| `POST-CIN-MEDIA-003` | MEDIA-03 — Audio, focus et lifecycle communs | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Revue conditionnelle effectuée. P2 du driver BGM corrigé : dispose tenté après échec prepare/play/stop. Tests RED→GREEN, build macOS et sortie native vérifiés. Écoute réelle seule condition  Bloquant : Retour d'écoute réelle avant/pendant/après la fixture MEDIA-03, explicitement demandé par le plan. Question en attente, aucune réponse positive reçue. La certification sur manette physique n'est pas requise. | Contrats runtime relus ; certification fraîche compilée partiellement. | Non | Un seul decoder actif, continuité et libération correctes à l’oreille. | TO REVIEW |
| `—` | Le train de 17h42 — Réparer le chargement project.item_catalog_invalid | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Réparation appliquée à items.json et vérifiée avec le décodeur strict. Les 45 objets sont intacts. Bloquant : Réouvrir le projet dans l’éditeur et validation de Yoahn. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `POST-AVL-ICON-001` | Intégrer l’identité Avelune — icônes natives, démarrage et accueil | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Identité native iOS/macOS/Android intégrée, puis symbole blanc et wordmark du Brand Kit branchés sur l’accueil et le splash. 60 tests UI/ressources réussis, analyses ciblées propres, trois b Bloquant : Revue de Yoahn sur applications relancées/appareils. iOS non signé, aucune installation/publication. Cinq goldens globaux déjà en échec avant cette extension, non régénérés. Android Material You monochrome touj | Tests Hub/MCP ciblés verts ; session native manquante. | Non | Identité Avelune, icône et accueil sont cohérents et stables. | TO REVIEW |
| `POST-WLD-SMART-004` | Refondre le parcours no-code du Smart Tiles Studio | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Le parcours rapide Chemin est implémenté avec deux patrons confirmés : Chemin classique et Contour fermé. Le contour conserve son patron principal 3x3 et ajoute un bloc Coins 2x2, soit 13 as Bloquant : Le Studio est organisé autour du modèle technique du moteur au lieu de la tâche utilisateur « créer un chemin ». | Tests ciblés relus ; rejeu installé absent. | Non | Parcours no-code, feedback, preview et publication sont compréhensibles. | TO REVIEW |
| `POST-WLD-SMART-003` | Simplifier le parcours Chemin du Smart Tiles Studio et prévisualiser les images | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Le sélecteur affiche désormais un aperçu et les dimensions avant confirmation ; le parcours Chemin utilise des libellés concrets, prépare automatiquement un matériau et masque les réglages t Bloquant : Aucun manque d’implémentation identifié dans ce scope ; reste la validation humaine du flux desktop. | Tests ciblés relus ; rejeu installé absent. | Non | Images et états restent lisibles, rapides et cohérents. | TO REVIEW |
| `POST-AVL-CONTROL-001` | Piloter Avelune via une API locale et un MCP de certification macOS | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. API de contrôle debug loopback + token, lanceur macOS éphémère et MCP Avelune global avec six outils sémantiques. Bloquant : Revue manuelle de Yoahn. Intégration main explicitement autorisée malgré 3 tests ciblés rouges hors vertical Avelune: dry-run RailJourney, resource kind element, gate capability truth Smart Tile. Espaces finaux | Tests Hub/MCP ciblés verts ; session native manquante. | Non | Contrôle live et erreurs sont stables ; les rouges ont une décision explicite. | TO REVIEW |
| `—` | Refondre l’intro et la pré-session du Train dans une grammaire proche de Pokémon Platine | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. La piste musicale de la pré-session est désormais authorée pour continuer pendant les holds de dialogue, et ses sept segments bouclent jusqu’à la transition suivante. Un paquet Avelune 0.1.6 Bloquant : Importer la version 0.1.6 dans Avelune, relancer la pré-session complète et confirmer à l’oreille que la musique reste continue pendant chaque texte, puis vérifier la sortie finale vers M00. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `—` | Nettoyer les artefacts obsolètes du projet Train de 17h42 | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Nettoyage conservateur du projet réel : 12 Go placés dans la Corbeille, dossier ramené à 706 Mo, fingerprint et validation PokeMap inchangés. Bloquant : Validation utilisateur du projet nettoyé ; vider la Corbeille seulement après accord. Les 892 assets runtime-inutilisés détectés par l’audit ont volontairement été conservés car ils peuvent rester utiles à l’au | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `—` | Découpler les mutations Smart Tile des dettes globales de sauvegarde | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Les mutations Smart Tile map-only ne sont plus bloquées ni absorbées par une dette narrative sans rapport. Bloquant : Le préflight et l’adoption canonique sont projet-scoped alors que smart_tile.cell.* et smart_tile.pattern.* sont map-scoped. | Tests ciblés relus ; rejeu installé absent. | Non | Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable. | TO REVIEW |
| `POST-SYS-002` | Corriger le contraste des dialogues joueur dans le Hub | D | Non | `NEEDS_MANUAL_VALIDATION` | Relus code/critères/rapport. Le pont de thème joueur laissait plusieurs rôles typographiques hérités du thème sombre Avelune sur une surface de dialogue claire. La projection sémantique couvre désormais tous les rôles,  Bloquant : Contraste illisible dans les surfaces de dialogue joueur lorsqu’un thème hôte sombre enveloppe un projet à surface claire. | Tests ciblés/MCP verts selon le périmètre ; validation projet/Hub manquante. | Non | Contraste réellement lisible, sans écriture blanche sur surface claire. | TO REVIEW |

## KEEP_TO_REVIEW — 6 tickets avec écart fonctionnel ou technique

### `BETA-BAT-011` — Faire parler le journal de combat dans la langue du joueur

Le planner localisé existe, mais la revue du chemin de switch a retrouvé des IDs d’espèce bruts et une injection incomplète du resolver. Le test d’ordre doit également être renforcé pour suivre les groupes d’animation actuels. Action restante : corriger les messages concernés, lancer `cd packages/map_runtime && flutter test test/battle_turn_animation_planner_test.dart`, puis rejouer un combat en français. Le ticket reste `TO REVIEW`.

### `BETA-BAT-014` — Donner un son aux attaques, aux coups et aux K.O.

Les sons de capacité, d’impact et de chute sont présents et les tests ciblés passent. Le cri d’espèce au K.O. reste absent du planner courant ; les `PlayCryStep` retrouvés concernent l’intro, pas le K.O. Action restante : brancher le média d’espèce, tester espèce/pitch/ordre, puis écouter sur build réel.

### `BETA-BAT-015` — Mettre la musique des combats, par défaut, par dresseur et par zone

Le runtime utilise encore `_battleVictoryMusicActive` comme booléen global dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`. La branche ne distingue pas proprement victoire sauvage/dresseur et ne prouve pas l’ordre victoire dresseur après XP. Action restante : corriger le séquençage, ajouter la preuve wild/trainer/XP/fuite/capture et rejouer les sorties.

### `BETA-BAT-018` — Précharger les effets de combat sous le noir de la transition

Le cache et le budget sont couverts directement, mais le callback de reveal peut observer un overlay chargé alors que la préchauffe est encore pendante. Action restante : partager la barrière de readiness entre `_openBattleOverlay` et `_maybeRevealBattleScene`, ajouter le scénario host chargé/préchauffe bloquée/noir tenu, puis rejouer le premier effet.

### `BETA-BAT-022` — Faire sortir les Pokémon de leur Poké Ball en début de combat

La timeline lancer/ouverture/croissance et les rappels sont présents. Le critère de Ball individuelle est explicitement partiel : `capturedWith` manque et le runtime retombe sur `ball_1`. Action restante : propager la source de Ball dans les données de session/animation, ajouter la preuve, puis rejouer send-out et remplacement.

### `POST-UI-MENU-011` — Harmoniser sauvegarde, confirmations et retour au titre

La vérification actuelle a un échec reproductible : `menu8_save_test.dart` contient 14 scénarios, dont 6 échouent. Le tap `Retour au titre` est calculé à `y=1007,5` hors d’une racine `1100×1000`, puis les confirmations attendues ne sont pas trouvées. Un essai de contrainte de hauteur du frame a été annulé car il ne corrigeait pas la cause ; aucun patch ne reste. Action restante : isoler la cause de layout/navigation, obtenir 14/14, puis refaire la capture native demandée.

## NEEDS_MANUAL_VALIDATION — 36 tickets

Pour chacun, le code seul ne suffit pas parce que le critère restant est explicitement réel, visuel, audio, tactile, matériel ou produit.

### `BETA-CIN-084` — Certifier localement performance et teardown des holds interactifs

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : appareil profile cible, paysage et portrait.
- Étapes : Lancer le journey 50 cycles avec décodeur réel, produire measurements.json puis le receipt au SHA courant.
- Résultat attendu : Les latences, frames lentes, RSS et compteurs de teardown respectent les seuils, sans faux décodeur.
- Passage ultérieur en DONE : Receipt certifié + mesures brutes + relecture de Yoahn. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-CIN-086` — Revoir et clôturer la gate Bêta Presentation interactive

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Hub et Studio, 16:9 et 9:16.
- Étapes : Jouer la Presentation compilée, répondre et refuser une confirmation dans les deux orientations.
- Résultat attendu : Parcours positif/négatif lisible, risques résiduels acceptés, aucune dépendance ouverte.
- Passage ultérieur en DONE : Recette visuelle signée après BETA-CIN-084. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-WLD-001` — Implémenter un contrat générique de porte animée

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Player/éditeur sur projet de test.
- Étapes : Ouvrir une vraie porte de station, Cmd-S, traverser/warper et observer l’animation.
- Résultat attendu : One-shot, verrouillage et warp sont cohérents sans casser le parcours.
- Passage ultérieur en DONE : Capture/rejeu et validation visuelle du contrat générique. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-BAT-009` — Rendre l’interface de combat lisible et non occultante

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Hub installé, orientations ciblées.
- Étapes : Entrer en combat et capturer les états de layout, commandes et overlay, notamment le viewport compact.
- Résultat attendu : Aucune commande ni information critique n’est occultée ; le défaut compact est accepté ou corrigé.
- Passage ultérieur en DONE : Capture native + verdict produit. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-ENC-007` — Porter les rencontres directement sur les calques Smart Tile

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Player installé, trois secteurs.
- Étapes : Traverser nord, forêt et station ; déclencher on_enter et suivre l’animation jusqu’au combat.
- Résultat attendu : Seules les sources Smart Tile attendues déclenchent une rencontre jouable.
- Passage ultérieur en DONE : Trace/rejeu des trois secteurs. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-BAT-007` — Certifier la surface joueur de combat et son focus

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Appareil cible, portrait et paysage.
- Étapes : Jouer FIGHT, BAG, POKÉMON et RUN au toucher avec rotation et changement de focus.
- Résultat attendu : Chaque commande reste touchable, le focus ne se perd pas et aucun overlay ne recouvre l’action.
- Passage ultérieur en DONE : Replay combat complet ; les hunks dirty préexistants restent hors attribution. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-TRN-001` — Construire et certifier le cycle ligne de vue → exclamation → approche → dialogue → combat

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Player installé.
- Étapes : Entrer dans la LOS d’un dresseur, vérifier l’exclamation, approcher, dialoguer puis combattre.
- Résultat attendu : Exclamation bien placée/lisible, approche cohérente et combat déclenché une seule fois.
- Passage ultérieur en DONE : Capture et validation humaine du cycle. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-BAT-019` — Offrir un panel de transitions de combat par zone et par dresseur

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Studio + build Hub.
- Étapes : Configurer une zone multi-transitions, un dresseur rby_trainer et la Zone de Combat, puis entrer en combat.
- Résultat attendu : Choix, tirage déterministe, fallback et rendu des transitions sont compréhensibles.
- Passage ultérieur en DONE : Recette visuelle des panneaux et relecture des familles. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-BAT-020` — Faire entendre et lire l'efficacité des attaques en jeu réel

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Hub avec son, matchup réel.
- Étapes : Jouer super efficace, résisté/neutre et immunité ; vérifier message, son et badge persistant.
- Résultat attendu : Le joueur entend/lit l’efficacité au bon moment et la décision de badge est explicite.
- Passage ultérieur en DONE : Captures/écoute + décision de Yoahn. Le ticket reste alors en TO REVIEW jusque-là.

### `BETA-BAT-021` — Donner un retour visuel aux capacités de statut et aux changements de stats

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Hub installé.
- Étapes : Déclencher Intimidation/Rugissement et une montée/refus de stats, puis observer aura, texte et son.
- Résultat attendu : Les étapes restent lisibles et ordonnées ; les limites précision/évasion sont documentées.
- Passage ultérieur en DONE : Replay visuel/audio accepté. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-UI-OW-007` — POST-UI-OW-007 — Sécuriser les transitions, le multitouch et le cycle de vie

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : iOS/Android physiques.
- Étapes : Exécuter OW008 : multitouch, interruption, reprise, rotation et déconnexion/reconnexion contrôleur.
- Résultat attendu : Aucun geste fantôme, input bloqué ou état incohérent après lifecycle.
- Passage ultérieur en DONE : Matrice matérielle verte + captures. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-UI-OW-006` — POST-UI-OW-006 — Brancher les actions contextuelles et le toucher direct à portée

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : iOS/Android ou Player cible.
- Étapes : Inspecter/interagir à portée en marchant, y compris les actions Train/contextuelles.
- Résultat attendu : Hitbox, latence et action contextuelle correspondent au geste attendu.
- Passage ultérieur en DONE : Replay réel + mesure de confort. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-UI-OW-005` — POST-UI-OW-005 — Intégrer marche et course au geste tactile

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : iOS puis Android.
- Étapes : Calibrer marche/course, maintenir, relâcher, annuler et reprendre dans les orientations prévues.
- Résultat attendu : Course fiable, seuils confortables, aucune dérive ni conflit avec les autres inputs.
- Passage ultérieur en DONE : Campagne tactile device + vidéo. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-UI-OW-004` — POST-UI-OW-004 — Remplacer le joystick fixe par un joystick flottant

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Téléphone physique.
- Étapes : Calibrer le joystick flottant, jouer plusieurs directions, relâcher et changer d’orientation.
- Résultat attendu : Placement, direction, relâchement et confort sont acceptables à l’échelle joueur.
- Passage ultérieur en DONE : Replay/vidéo accepté. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-UI-OW-003` — POST-UI-OW-003 — Créer les primitives premium et les layouts du HUD minimal

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Hub/Player à player scale.
- Étapes : Ouvrir les surfaces HUD dans le flux réel et vérifier lisibilité, occlusion et contraste.
- Résultat attendu : Les primitives restent lisibles et ne promettent pas une intégration non livrée.
- Passage ultérieur en DONE : Revue visuelle de Yoahn. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-UI-MENU-013` — POST-UI-MENU-013 — Certifier fidélité visuelle, navigation, accessibilité et stabilité

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Hub frais, Android physique, manette/accessibilité.
- Étapes : Exécuter menus, Quest Book, parcours globaux, lecteur d’écran et manette.
- Résultat attendu : Navigation, cibles, accessibilité, stabilité et rendu respectent la fiche.
- Passage ultérieur en DONE : Matrice native complète + validation artistique. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-UI-MENU-012` — POST-UI-MENU-012 — Réaliser les Options et leurs réglages réellement appliqués

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Appareil physique.
- Étapes : Modifier chaque option, quitter/revenir, vérifier audio, vibration, manette et narration temporisée.
- Résultat attendu : Chaque réglage est réellement appliqué et persiste selon le contrat.
- Passage ultérieur en DONE : Replay matériel + décision de Yoahn. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-UI-MENU-004` — POST-UI-MENU-004 — Réaliser le menu principal illustré et sa navigation

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Hub installé.
- Étapes : Parcourir toutes les entrées du menu principal, retour, nouvelle partie et combat.
- Résultat attendu : Navigation et illustration restent correctes après les corrections récentes.
- Passage ultérieur en DONE : Capture native + verdict. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-CIN-MEDIA-003` — MEDIA-03 — Audio, focus et lifecycle communs

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Application cible avec audio.
- Étapes : Écouter avant/pendant/après le média, interrompre, reprendre et changer de focus.
- Résultat attendu : Un seul decoder actif, continuité et libération correctes à l’oreille.
- Passage ultérieur en DONE : Écoute positive documentée. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-AVL-ICON-001` — Intégrer l’identité Avelune — icônes natives, démarrage et accueil

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : macOS/iOS ou appareils disponibles.
- Étapes : Relancer l’application depuis l’icône, vérifier startup et accueil sur export installé.
- Résultat attendu : Identité Avelune, icône et accueil sont cohérents et stables.
- Passage ultérieur en DONE : Capture appareil/Hub et acceptation. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-WLD-SMART-004` — Refondre le parcours no-code du Smart Tiles Studio

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur sur projet réel.
- Étapes : Exécuter le parcours Smart Tiles sans JSON manuel : choix, aperçu, édition et sauvegarde.
- Résultat attendu : Parcours no-code, feedback, preview et publication sont compréhensibles.
- Passage ultérieur en DONE : Rejeu visuel/ergonomique + verdict. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-WLD-SMART-003` — Simplifier le parcours Chemin du Smart Tiles Studio et prévisualiser les images

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur sur projet réel.
- Étapes : Rejouer Chemin : sélectionner, prévisualiser, revenir, appliquer et rouvrir.
- Résultat attendu : Images et états restent lisibles, rapides et cohérents.
- Passage ultérieur en DONE : Validation ergonomique. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-AVL-CONTROL-001` — Piloter Avelune via une API locale et un MCP de certification macOS

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : macOS, Hub installé.
- Étapes : Lancer la session de contrôle, naviguer, revenir et requalifier les trois tests rouges signalés.
- Résultat attendu : Contrôle live et erreurs sont stables ; les rouges ont une décision explicite.
- Passage ultérieur en DONE : Parcours live + décision de portée. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `—` — POST-UI-OW-010 — Orienter la course et débloquer le voyage en train

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Éditeur du projet Train externe.
- Étapes : Ouvrir la copie réparée, relire les 45 items et leurs références, puis lancer une nouvelle ouverture.
- Résultat attendu : Catalogue valide, aucune erreur project.item_catalog_invalid, projet exploitable.
- Passage ultérieur en DONE : Confirmation explicite ou décision de fusion avec l’autre ticket. Le ticket reste alors en TO REVIEW jusque-là.

### `POST-SYS-002` — Corriger le contraste des dialogues joueur dans le Hub

- Pourquoi le code seul ne suffit pas : la fiche exige une observation réelle, visuelle, audio, tactile, matérielle ou une acceptation produit.
- Plateforme : Hub, thèmes clair/sombre.
- Étapes : Ouvrir dialogues joueur, titres, champs et boutons dans les variantes utiles.
- Résultat attendu : Contraste réellement lisible, sans écriture blanche sur surface claire.
- Passage ultérieur en DONE : Capture visuelle et validation Yoahn. Le ticket reste alors en TO REVIEW jusque-là.

## OBSOLETE_TICKETS

Aucun verdict `OBSOLETE_OR_DUPLICATE` n’a été retenu. Quelques sujets nécessitent une réconciliation séparée, mais pas une suppression automatique :

- la fiche externe `project.item_catalog_invalid` n’a pas d’identifiant stable et peut chevaucher le diagnostic d’ouverture Train ; elle reste reviewée comme tâche externe valide jusqu’à décision de fusion ;
- `POST-CIN-MEDIA-003/006/007` sont des passes cumulatives sur un même univers de média, pas trois preuves indépendantes, mais leurs objectifs ne sont pas identiques ;
- `POST-WLD-SMART-003` est un sous-parcours de `POST-WLD-SMART-004`, sans preuve suffisante pour fusionner silencieusement ;
- `POST-UI-OW-003` à `007` sont des lots séquentiels, non des doublons.

## MAP_TICKETS_TO_DELETE

Ces tickets ont été volontairement ignorés techniquement. Leur résultat principal est du contenu de niveau ou d’asset spécifique au Train/Avelune ; ils sont candidats à DELETE dans une passe séparée. Aucun n’a été supprimé.

| Code/ID | Ticket | URL/ID Notion | Raison | Recommandation |
|---|---|---|---|---|
| `—` | POST-WLD-ASSET-L00-01 — Vérifier le socle et l’état des imports V2 | <https://app.notion.com/p/3d0197a7bfa5814abbc2cc6a1503221f> | Résultat principal spécifique au contenu de map : post-wld-asset-l00-01 — vérifier le socle et l’état des imports v2. | DELETE |
| `—` | POST-WLD-ASSET-L02-01 — Créer le gravier raccordable de la gare | <https://app.notion.com/p/3d0197a7bfa5818e8d0be04df8d7ba28> | Résultat principal spécifique au contenu de map : post-wld-asset-l02-01 — créer le gravier raccordable de la gare. | DELETE |
| `—` | POST-WLD-ASSET-L02-02 — Créer les sols secondaires et leurs transitions | <https://app.notion.com/p/3d0197a7bfa5815e8db2c2a3f1f7f96b> | Résultat principal spécifique au contenu de map : post-wld-asset-l02-02 — créer les sols secondaires et leurs transitions. | DELETE |
| `—` | POST-WLD-ASSET-L02-03 — Créer les sols intérieurs en bois et tatami | <https://app.notion.com/p/3d0197a7bfa58181ac6cd4db17a47a56> | Résultat principal spécifique au contenu de map : post-wld-asset-l02-03 — créer les sols intérieurs en bois et tatami. | DELETE |
| `—` | POST-WLD-ASSET-L02-04 — Créer les surfaces régionales et les réseaux d’eau | <https://app.notion.com/p/3d0197a7bfa581dc8378ceb1375b5337> | Résultat principal spécifique au contenu de map : post-wld-asset-l02-04 — créer les surfaces régionales et les réseaux d’eau. | DELETE |
| `—` | POST-WLD-ASSET-L02-05 — Créer les silhouettes d’arbres complémentaires | <https://app.notion.com/p/3d0197a7bfa5819eb633deaff41fded6> | Résultat principal spécifique au contenu de map : post-wld-asset-l02-05 — créer les silhouettes d’arbres complémentaires. | DELETE |
| `—` | POST-WLD-ASSET-L02-06 — Créer la végétation basse et les cultures | <https://app.notion.com/p/3d0197a7bfa581fd8ca5c4d2ebb8e1f8> | Résultat principal spécifique au contenu de map : post-wld-asset-l02-06 — créer la végétation basse et les cultures. | DELETE |
| `—` | POST-WLD-ASSET-L02-07 — Créer les rochers et le bois mort | <https://app.notion.com/p/3d0197a7bfa581c7b108e5d86f492eff> | Résultat principal spécifique au contenu de map : post-wld-asset-l02-07 — créer les rochers et le bois mort. | DELETE |
| `—` | POST-WLD-ASSET-L02-08 — Créer les escaliers, ponts et entrées de tunnel | <https://app.notion.com/p/3d0197a7bfa581e0aa1cdf78906d17bf> | Résultat principal spécifique au contenu de map : post-wld-asset-l02-08 — créer les escaliers, ponts et entrées de tunnel. | DELETE |
| `—` | POST-WLD-ASSET-L05-01 — Créer les patrons des objets de quête dans le monde | <https://app.notion.com/p/3d0197a7bfa581c28c83c38bd7d117f7> | Résultat principal spécifique au contenu de map : post-wld-asset-l05-01 — créer les patrons des objets de quête dans le monde. | DELETE |
| `—` | POST-WLD-ASSET-L05-02 — Créer les icônes de quête et les poinçons | <https://app.notion.com/p/3d0197a7bfa581f1b2c6ef7ecb5d443c> | Résultat principal spécifique au contenu de map : post-wld-asset-l05-02 — créer les icônes de quête et les poinçons. | DELETE |
| `—` | POST-WLD-ASSET-L05-03 — Créer les documents inspectables et le carnet | <https://app.notion.com/p/3d0197a7bfa581119ee4e863c3523aca> | Résultat principal spécifique au contenu de map : post-wld-asset-l05-03 — créer les documents inspectables et le carnet. | DELETE |
| `—` | POST-WLD-ASSET-L05-04 — Établir le roster et produire les sprites overworld | <https://app.notion.com/p/3d0197a7bfa581bb8724d25d6f05e602> | Résultat principal spécifique au contenu de map : post-wld-asset-l05-04 — établir le roster et produire les sprites overworld. | DELETE |
| `—` | POST-WLD-ASSET-L05-05 — Créer les portraits et les silhouettes de dresseurs | <https://app.notion.com/p/3d0197a7bfa581978196d432d1f9f2f1> | Résultat principal spécifique au contenu de map : post-wld-asset-l05-05 — créer les portraits et les silhouettes de dresseurs. | DELETE |
| `—` | POST-WLD-ASSET-L05-06 — Créer les éléments visuels des scènes narratives | <https://app.notion.com/p/3d0197a7bfa5812d8784c6c8c25b8871> | Résultat principal spécifique au contenu de map : post-wld-asset-l05-06 — créer les éléments visuels des scènes narratives. | DELETE |
| `—` | POST-WLD-ASSET-L06-01 — Créer la rame de la ligne des Cèdres | <https://app.notion.com/p/3d0197a7bfa581358628ee6385693728> | Résultat principal spécifique au contenu de map : post-wld-asset-l06-01 — créer la rame de la ligne des cèdres. | DELETE |
| `—` | POST-WLD-ASSET-L06-03 — Créer les modules de voiture et les panoramas de trajet | <https://app.notion.com/p/3d0197a7bfa5812ea5f5fc17e6ddc303> | Résultat principal spécifique au contenu de map : post-wld-asset-l06-03 — créer les modules de voiture et les panoramas de trajet. | DELETE |
| `—` | POST-WLD-ASSET-L06-04 — Créer les lumières et les effets électriques | <https://app.notion.com/p/3d0197a7bfa5811095b7fa8436c2e3b6> | Résultat principal spécifique au contenu de map : post-wld-asset-l06-04 — créer les lumières et les effets électriques. | DELETE |
| `—` | POST-WLD-ASSET-L06-05 — Créer la pluie, la brume et la poussière | <https://app.notion.com/p/3d0197a7bfa5811d8286d4557151469a> | Résultat principal spécifique au contenu de map : post-wld-asset-l06-05 — créer la pluie, la brume et la poussière. | DELETE |
| `—` | POST-WLD-ASSET-L06-06 — Créer les fonds de combat par environnement | <https://app.notion.com/p/3d0197a7bfa5815c9836cd6711ed39f2> | Résultat principal spécifique au contenu de map : post-wld-asset-l06-06 — créer les fonds de combat par environnement. | DELETE |
| `—` | POST-WLD-ASSET-M00 — M00 — Décliner les assets de Chambre de la pension d’Hanazuki | <https://app.notion.com/p/3d0197a7bfa5818a9d5cc6055246c943> | Résultat principal spécifique au contenu de map : post-wld-asset-m00 — m00 — décliner les assets de chambre de la pension d’hanazuki. | DELETE |
| `—` | POST-WLD-ASSET-M01 — M01 — Décliner les assets de Village d’Hanazuki | <https://app.notion.com/p/3d0197a7bfa58189808be259404dffe4> | Résultat principal spécifique au contenu de map : post-wld-asset-m01 — m01 — décliner les assets de village d’hanazuki. | DELETE |
| `—` | POST-WLD-ASSET-M02 — M02 — Décliner les assets de Colline du sanctuaire | <https://app.notion.com/p/3d0197a7bfa58199b65ed8ae43ff9be7> | Résultat principal spécifique au contenu de map : post-wld-asset-m02 — m02 — décliner les assets de colline du sanctuaire. | DELETE |
| `—` | POST-WLD-ASSET-M03 — M03 — Décliner les assets de Gare d’Hanazuki | <https://app.notion.com/p/3d0197a7bfa581bebc9bec71e00d4859> | Résultat principal spécifique au contenu de map : post-wld-asset-m03 — m03 — décliner les assets de gare d’hanazuki. | DELETE |
| `—` | POST-WLD-ASSET-M03-I — M03-I — Décliner les assets de Intérieur de la gare d’Hanazuki | <https://app.notion.com/p/3d0197a7bfa581729ab2de8a3e1a6f0b> | Résultat principal spécifique au contenu de map : post-wld-asset-m03-i — m03-i — décliner les assets de intérieur de la gare d’hanazuki. | DELETE |
| `—` | POST-WLD-TRAIN-COLLISIONS — Corriger les collisions des 38 maps et les zones sans rencontres | <https://app.notion.com/p/3d9197a7bfa581e18485f0ef46091366> | Résultat principal spécifique au contenu de map : post-wld-train-collisions — corriger les collisions des 38 maps et les zones sans rencontres. | DELETE |
| `—` | POST-WLD-FIDELITY-001 — Reprendre toutes les maps selon les références du Train | <https://app.notion.com/p/3d4197a7bfa5817588cbd9fd0d62c014> | Résultat principal spécifique au contenu de map : post-wld-fidelity-001 — reprendre toutes les maps selon les références du train. | DELETE |
| `—` | POST-WLD-MAPS-001 — Classer les maps du Train par région et sous-dossiers | <https://app.notion.com/p/3d4197a7bfa581ca8a71cc17a9346ccd> | Résultat principal spécifique au contenu de map : post-wld-maps-001 — classer les maps du train par région et sous-dossiers. | DELETE |
| `—` | POST-WLD-LIBRARY-001 — Regrouper et classer les tilesets du Train de 17h42 | <https://app.notion.com/p/3d4197a7bfa5818e83b0c542ad8eeebb> | Résultat principal spécifique au contenu de map : post-wld-library-001 — regrouper et classer les tilesets du train de 17h42. | DELETE |
| `—` | POST-WLD-ASSET-CLEAN-001 — Ranger les assets propres du Train V2 | <https://app.notion.com/p/3d3197a7bfa581be90b4fd78657e8144> | Résultat principal spécifique au contenu de map : post-wld-asset-clean-001 — ranger les assets propres du train v2. | DELETE |
| `POST-UI-MENU-007` | POST-UI-MENU-007 — Réaliser la carte régionale illustrée et les lieux interactifs | <https://app.notion.com/p/3d2197a7bfa581d29d20de497b776928> | Carte régionale illustrée et lieux spécifiques : contenu de map, pas capacité générique. | DELETE |
| `—` | POST-WLD-ASSET-L08-IMPORT — Importer le kit Aohara validé et vérifier son usage dans PokeMap | <https://app.notion.com/p/3d2197a7bfa5817bb639eea41a2177c6> | Résultat principal spécifique au contenu de map : post-wld-asset-l08-import — importer le kit aohara validé et vérifier son usage dans pokemap. | DELETE |
| `POST-WLD-TRAIN-M00-M03-001` | POST-WLD-TRAIN-M00-M03-001 — Reconstruire les quatre vues du Train dans PokeMap | <https://app.notion.com/p/3d2197a7bfa5818db420cb2bf9af1cbe> | Création, import ou reprise d’un contenu/asset spécifique du monde Train. | DELETE |
| `—` | POST-WLD-L03-PLAY-001 — Intégrer les bâtiments du lot 3 dans une zone jouable | <https://app.notion.com/p/3d1197a7bfa58166a450e172d880873e> | Résultat principal spécifique au contenu de map : post-wld-l03-play-001 — intégrer les bâtiments du lot 3 dans une zone jouable. | DELETE |
| `—` | POST-WLD-ASSET-L01-IMPORT — Importer le lot ferroviaire L01 approuvé dans le Train | <https://app.notion.com/p/3d0197a7bfa581a88755e7bd749d7fcf> | Résultat principal spécifique au contenu de map : post-wld-asset-l01-import — importer le lot ferroviaire l01 approuvé dans le train. | DELETE |
| `—` | POST-WLD-ASSET-CHARTE-001 — Charte et bible de production des assets V2 | <https://app.notion.com/p/3d0197a7bfa581cbb09cedeed3c5bd9e> | Résultat principal spécifique au contenu de map : post-wld-asset-charte-001 — charte et bible de production des assets v2. | DELETE |
| `—` | POST-WLD-ASSET-RAILS-001 — Créer les rails horizontaux de Hanazuki | <https://app.notion.com/p/3d0197a7bfa581d69578d323efd63818> | Résultat principal spécifique au contenu de map : post-wld-asset-rails-001 — créer les rails horizontaux de hanazuki. | DELETE |
| `—` | POST-WLD-ASSET-PROPS-001 — Créer les accessoires de la gare de Hanazuki | <https://app.notion.com/p/3d0197a7bfa581f8add0e37d37e22221> | Résultat principal spécifique au contenu de map : post-wld-asset-props-001 — créer les accessoires de la gare de hanazuki. | DELETE |
| `—` | POST-WLD-ASSET-GARE-001 — Créer la gare rurale de Hanazuki depuis la référence | <https://app.notion.com/p/3d0197a7bfa581e1a4b2feeebacf748d> | Résultat principal spécifique au contenu de map : post-wld-asset-gare-001 — créer la gare rurale de hanazuki depuis la référence. | DELETE |
| `—` | POST-WLD-ASSET-PATRONS-001 — Mesurer le corpus PSDK et préparer les patrons d’assets Avelune | <https://app.notion.com/p/3cf197a7bfa58111a3f2d824c623f93b> | Résultat principal spécifique au contenu de map : post-wld-asset-patrons-001 — mesurer le corpus psdk et préparer les patrons d’assets avelune. | DELETE |
| `POST-WLD-ART-001` | POST-WLD-ART-001 — Préparer les premiers essais de terrains du Train de 17h42 | <https://app.notion.com/p/3cf197a7bfa581db8ef8de93b9dddd4c> | Création, import ou reprise d’un contenu/asset spécifique du monde Train. | DELETE |
| `POST-WLD-GRASS-001` | Refondre les hautes herbes du Train de 17h42 | <https://app.notion.com/p/3c8197a7bfa581309a18d78fbce90fb5> | Création, import ou reprise d’un contenu/asset spécifique du monde Train. | DELETE |

## Correctifs réalisés

Aucun correctif n’a été laissé dans le checkout.

- Aucun fichier de production n’a été modifié par cette mission.
- Le patch temporaire de contrainte de hauteur tenté dans `packages/map_player_ui/lib/src/foundation/player_menu_components.dart` n’a pas réglé `menu8_save_test.dart` et a été entièrement réverti ; le fichier ne figure pas dans le diff final.
- Les modifications préexistantes de `battle_overlay_component.dart` et `playable_map_game_input_test.dart` ont été conservées.
- Le hunk concurrent `packages/map_player_ui/analysis_options.yaml` a été conservé.
- Aucun Git write n’a été exécuté : pas de add, commit, reset, restore, checkout, stash, merge, rebase, tag, push, clean, rm ou mv.

## Tests lancés et résultats exacts

### Tests ciblés propres

- `cd packages/map_core && dart test test/project_item_catalog_codec_test.dart test/project_item_catalog_model_test.dart test/project_item_catalog_validator_test.dart test/encounter_contract_test.dart test/smart_tile_encounter_source_test.dart test/smart_tiles/smart_tile_animation_activation_test.dart test/project_trainer_lifecycle_test.dart test/project_trainer_validation_test.dart test/map_entity_collision_footprint_test.dart`  
  Exit 0 — `00:00 +56: All tests passed!`
- `cd packages/map_gameplay && dart test test/encounter_resolution_contract_test.dart test/smart_tile_native_encounter_test.dart test/smart_tile_generated_gameplay_zone_bridge_test.dart test/npc_default_collision_footprint_test.dart test/npc_map_presence_predicate_test.dart test/new_game_state_builder_test.dart test/project_new_game_state_builder_test.dart test/runtime_movement_collision_regression_test.dart`  
  Exit 0 — `00:00 +82: All tests passed!`
- `cd packages/map_battle && dart test test/battle_flow_integration_test.dart test/battle_session_flow_test.dart test/battle_switch_test.dart test/battle_capture_flow_test.dart test/battle_move_effects_test.dart test/battle_parity_target_test.dart test/battle_parity_target_ruleset_agreement_test.dart`  
  Exit 0 — `00:00 +96: All tests passed!`
- `cd packages/map_runtime && flutter test --no-pub --reporter compact test/battle_command_menu_model_localization_test.dart test/battle_mobile_command_overlay_test.dart test/battle_effectiveness_presentation_test.dart test/battle_move_effects_precache_test.dart test/battle_stat_stage_presentation_test.dart test/battle_transition_spec_test.dart test/battle_transition_overlay_component_test.dart test/battle_intro_animation_planner_test.dart test/battle_intro_parity_test.dart test/battle_ball_capture_component_test.dart test/battle_music_resolver_test.dart test/battle_outcome_music_notification_test.dart test/battle_overlay_component_test.dart test/battle_scene_layout_test.dart test/battle_turn_animation_planner_test.dart test/battle_surface_orientation_test.dart test/battle_presentation_coordination_test.dart test/battle_presentation_command_contract_test.dart test/battle_gate_diagnostics_test.dart test/player/runtime_audio_fade_and_pool_test.dart test/player/runtime_presentation_audio_controller_test.dart test/player/runtime_presentation_cue_outcome_test.dart test/player/runtime_presentation_media_playback_controller_test.dart test/player/runtime_presentation_scene_playback_controller_test.dart test/runtime_music_intro_loop_test.dart test/runtime_music_service_test.dart test/player/runtime_player_input_test.dart test/runtime_input_authority_test.dart test/player/runtime_player_lifecycle_matrix_test.dart test/playable_map_game_input_test.dart test/playable_map_game_music_battle_exits_test.dart test/playable_map_game_runtime_music_integration_test.dart`  
  Exit 0 — `00:11 +409: All tests passed!`
- `cd tools/pokemap_mcp && npm test`  
  Exit 0 — build TypeScript OK ; `tests 80, pass 80, fail 0, cancelled 0, skipped 0` ; `duration_ms 366158.197292`.

### Échecs conservés comme preuve

- `cd packages/map_core && dart test test/project_item_reference_index_test.dart`  
  Exit 1. Le test attend 17 références et en obtient 18 :
  `Expected length <17>; Actual length <18>`. Ce défaut courant n’a pas été transformé en faux vert.
- `cd packages/map_player_ui && flutter test --no-pub --reporter compact test/player/menu8_save_test.dart`  
  Exit 1 — 14 tests, 8 passés, 6 échecs décrits ci-dessus.
- Passe large UI : `cd packages/map_player_ui && flutter test --no-pub --reporter compact test/player/interactive_hold_teardown_test.dart test/player/menu11_certification_test.dart test/menu11_contrast_test.dart test/player/menu8_options_test.dart test/player/menu8_save_test.dart test/player/menu9_region_map_test.dart test/menu_components_test.dart test/player/player_battle_occlusion_test.dart test/player/player_choice_option_readability_test.dart test/player/player_message_dialogue_box_test.dart test/player/runtime_player_floating_touch_controls_test.dart test/player/runtime_player_floating_touch_golden_test.dart test/player/runtime_player_input_navigation_test.dart test/player/runtime_player_live_game_interruptions_test.dart test/player/runtime_player_overlay_transition_matrix_test.dart test/player/runtime_player_pause_focus_lifecycle_test.dart test/player/runtime_player_touch_transition_matrix_test.dart test/player/runtime_player_resize_stress_test.dart test/player/runtime_player_presentation_test.dart`  
  Exit 1 — `00:21 +584 ~1 -28`; les points racine sont ceux de la suite menu8 et de sa matrice.
- Passe indépendante Popper sur la sélection UI overworld/menu : `00:03 +118 ~1 -6: Some tests failed.` Les échecs incluent le golden `overworld_primitives/running.png` et des scénarios OW-007 de transfert/libération des pointeurs.
- Passe indépendante de certification : `00:20 +20 -6: Some tests failed.` Les six échecs de chargement viennent notamment de `golden_item_system_journey.dart:645` avec paramètre `zoneId` inconnu et des paramètres `encounterSourceId/encounterSourceKind` désormais requis.
- `cd packages/map_runtime && flutter analyze`  
  Exit 1 — 3 issues : import Flutter inutile, switch non exhaustif sur `SceneBattleRuntimeOutcomePort.captured` dans `test/scene_event_runtime_hook_test.dart:987`, import relatif interdit dans un outil.
- `cd packages/map_core && dart analyze`  
  Exit 0 — 121 issues de niveau info.
- `cd packages/map_gameplay && dart analyze`  
  Exit 0 — 1 issue de niveau info.
- `cd packages/map_battle && dart analyze`  
  Exit 0 — `No issues found!`
- `cd packages/map_player_ui && flutter analyze`  
  Exit 0 — `No issues found!`

### Vérifications d’hygiène et processus

- `bash tools/scripts/check_markdown_hygiene.sh` avant génération du rapport : exit 0 — `Markdown hygiene: no new Markdown files.`
- Après génération, le même contrôle retourne exit 1 — `Non-canonical Markdown location: reports/review/pokemap_to_review_cleanup_2026-09-14.md`. La dérogation explicite `POKEMAP_MARKDOWN_MAX_NEW=1` lève bien le budget de nouveaux documents mais pas la règle de chemin canonique. Le chemin `reports/review/...` est néanmoins imposé par cette mission ; ce conflit de règles est conservé comme limite, sans déplacer ni dupliquer le rapport.
- Aucun `flutter_tester` abandonné après les suites exécutées.
- Trois serveurs `pokemap_mcp` âgés de plus de deux heures ont été vérifiés par PID/commande puis terminés explicitement ; aucun processus MCP ancien ne restait ensuite. Aucun kill par nom générique n’a été utilisé.

## Parité PokeMap MCP

La mission n’ajoute ni comportement d’auteur, ni nouveau contrat, ni nouvelle action. Aucune exposition MCP nouvelle n’était donc à implémenter. La suite actuelle de `tools/pokemap_mcp` a néanmoins été reconstruite et exécutée : 80/80 tests passent, couvrant notamment les contrats canoniques, transports JSONL/MCP, projets, Smart Tile, rencontres, export, handles et garde-fous de workspace.

## Passes indépendantes et verdicts croisés

- **Meitner — audit architecture** : veto à DONE ; a confirmé les gaps BAT-011, BAT-015, BAT-018, BAT-022 et les limites de provenance/receipt.
- **Poincare — audit implémentation** : a retrouvé les points de code BAT-011/BAT-018 et n’a retenu aucun correctif local sûr pour BAT-014/BAT-015/BAT-022.
- **Franklin — audit tests** : packages ciblés verts (+48/+62/+45 sur ses sélections), analyses sans erreur bloquante Dart, mais aucune clôture possible sans replay réel.
- **Popper — build/validation** : Hub ciblé 34/34, contrôle Avelune 8/8 ; suite UI et certification globale encore rouges, et validation matérielle absente.
- **Aquinas — critique finale** : veto global à DONE ; a insisté sur les tests creux, la provenance d’anciens SHA, les validations manuelles et les preuves MEDIA cumulées.

Les passes divergent sur certains classements frontières, notamment l’obsolescence de fiches sans ID et la portée de `BETA-WLD-001`. La décision retenue ici suit la source Notion intégrale et le résultat principal du ticket : pas de suppression ni de DONE sans preuve directe.

## Notion

- Inventaire initial : vue Notion `view://3b9197a7-bfa5-81b1-8c0f-000c117c0307`, 84 lignes, toutes `TO REVIEW`.
- 42 commentaires de revue datés du 2026-09-14 ont été créés, un par ticket hors map.
- Tous les tickets reviewés conservent `Statut = TO REVIEW`. Aucun champ de readiness ou de date n’a été falsifié pour simuler une clôture.
- Les 42 tickets maps restent inchangés et sont uniquement listés dans `MAP_TICKETS_TO_DELETE`.

## Git — sorties finales

Les lignes ci-dessous sont les sorties capturées après génération du rapport ; le rapport lui-même étant non suivi, il n’apparaît pas dans `git diff`.

### `git diff --stat`

```text
 packages/map_player_ui/analysis_options.yaml                        | 3 +++
 .../lib/src/presentation/flame/battle_overlay_component.dart        | 3 +++
 packages/map_runtime/test/playable_map_game_input_test.dart         | 6 ++++++
```

Le rapport nouvellement créé est non suivi et n’apparaît donc pas dans `git diff`; il est visible dans la sortie `git status` ci-dessous.

### `git diff --name-only`

```text
packages/map_player_ui/analysis_options.yaml
packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
packages/map_runtime/test/playable_map_game_input_test.dart
```

### `git diff --check`

```text
(aucune sortie)
```

### `git status --short --untracked-files=all`

```text
 M packages/map_player_ui/analysis_options.yaml
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
?? reports/review/pokemap_to_review_cleanup_2026-09-14.md
```

## Limites de la review

Vérifié statiquement : code actuel, critères Notion intégraux, rapports présents, tests et assertions ciblés, analyse Dart/Flutter, suite MCP, état Git, hygiène Markdown et processus orphelins.

Exécuté : suites ciblées core/gameplay/battle/runtime, analyse des packages, tests MCP 80/80, test menu8 reproduit, hygiène et contrôles de processus.

Non validé : iPhone/Android physiques, manette physique, écoute audio humaine, lecture vidéo native complète, VoiceOver/accessibilité native, performance profile avec receipt certifié au SHA exact, validation artistique de Yoahn, replay complet du projet Train installé, correction de `golden_item_system_journey.dart`, correction de `map_runtime analyze`, correction de `menu8_save_test.dart`.

## Auto-review finale

Aucun ticket n’a été fermé pour réduire le compteur. Pour chaque candidat historique affichant `PASS` ou `Terminé`, la revue a recherché un critère manuel, un défaut actuel ou une preuve fraîche manquante. Les 6 tickets KEEP ont un manque concret ; les 36 tickets manuels ont un protocole et une condition de fermeture ; les maps sont séparées sans être blanchies ni supprimées. La conclusion la plus défendable est donc un backlog encore en `TO REVIEW`, mais désormais honnête et actionnable.
