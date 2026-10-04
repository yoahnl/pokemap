# Avelune — audit de soumission App Store, 1 octobre 2026

## Verdict

Le modèle de lecteur RPG Avelune peut être défendu devant App Review. Des applications comparables sont actuellement distribuées par Apple. En revanche, les vérifications présentes ne justifient pas une nouvelle soumission avec une promesse de conformité : il reste des contenus tiers sans autorisation démontrée, des déclarations privacy manquantes, deux chemins de blocage du moteur et des écarts entre le dossier et le comportement natif.

Recommandation : traiter les constats prioritaires, construire une nouvelle archive iOS, contrôler cette archive puis rejouer son parcours sur appareil physique. L'audit ne certifie ni l'absence de toute vulnérabilité, ni les droits sur tous les contenus, ni l'acceptation future par Apple.

Yoahn confirme une publication personnelle, gratuite, qui restera gratuite. Il n'a pas confirmé dans cette réponse la possession des licences RPG Maker XP et ERW Grass Land. Achat non confirmé ne signifie pas absence d'achat ; gratuité ne signifie pas autorisation de réutilisation.

## Périmètre, audit initial et méthode

Audit demandé explicitement par Yoahn : code, assets, fonctionnement de l'import, règles Apple et précédents. Lecture de `codex_rule.md`, `skills/README.md`, `dispatching-parallel-agents/SKILL.md` et `verification-before-completion/SKILL.md` avant le travail. Aucune implémentation de correctif dans ce lot.

- Checkout principal : `/Users/karim/Project/pokemonProject`, branche `main`, HEAD `a63ac8656d8456a91c1570b03ff91100de4f1a50`, 196 entrées Git préexistantes à l'ouverture de l'audit.
- Référence de code publié : clone `/private/tmp/avelune-media-release-20261001`, HEAD `37e143ab52d1f3653d5293ece52c3b4d30bcec1d`, propre initialement et après les compilations.
- Lecture du host SwiftUI, pont Flutter, installation, inspection des packages, validation de projet, interpréteurs, chargement des médias, réseau accessible et déclarations de dépendances.
- Inventaire par chemins et SHA256 des 305 fichiers runtime ; comparaison aux sources PSDK et au RTP officiel. Inspection visuelle de samples explicitement indiqués, sans prétendre avoir examiné chaque cellule d'animation.
- Reconstruction Debug SwiftPackage puis compilation native Simulator, hors checkout principal. Aucun Archive/Release/export/upload.
- Consultation primaire Apple, éditeurs des ressources, dépôts amont et fiches App Store. Lecture authentifiée du dossier réel dans Safari, sans modification de métadonnées.
- Contrelecture indépendante finale des résultats et de leurs limites. Pas de nouveau pentest exhaustif, campagne de fuzzing, analyse de tous les frameworks binaires ou nouvelle certification physique.

Les 305 fichiers runtime et leur pubspec sont identiques dans le checkout principal et le clone. SHA256 du pubspec : `dde8bcf0c53c215d48e3d5b80a8accef82f50e7fab2721aa17f2c372c780d632`. La compilation de référence repose donc sur les mêmes ressources, sans intégrer le chantier concurrent de catalogue des maps.

## Dossier App Store Connect observé en direct

Application `6794668311`, URL de version : https://appstoreconnect.apple.com/apps/6794668311/distribution/ios/version/inflight . Consultation du 1 octobre 2026 ; ces états peuvent changer après l'audit.

| Élément | Observation actuelle |
| --- | --- |
| Version | 1.0.2, Developer Rejected |
| Build sélectionnée | 376 |
| Soumission `8491aced-5b5b-4e86-a5b3-c6cc2cc20c49` | Removed ; item 1.0.2 (376) Removed ; date affichée 1 octobre, 10:08 AM |
| Motif initial enregistré | 2.1.0 Performance: App Completeness ; message du 15 août : Information Needed |
| Messages récents | Apple remercie pour les informations, puis demande une resoumission ; aucune approbation définitive du produit |
| Catégorie et langue principale | Games / Roleplaying ; French |
| Âge | 4+ global affiché, avec exceptions régionales |
| Droits sur contenus tiers | Attestation affirmative enregistrée dans App Information |
| Privacy | Data Not Collected ; URL https://yoahnl.github.io/avelune/privacy/ |
| Achats | Aucun produit listé dans In-App Purchases ; aucun groupe d'abonnement auto-renouvelable créé |
| Images | Trois screenshots, zéro app preview, slot iPhone 6,5 pouces |
| Accès | Sign-in required désactivé |
| Notes | 2 547 caractères relevés, donc sous 4 000 |
| Pièce jointe | Avelune_App_Review_Pack_with_Video.zip ; notes : Clairières 1.0.1 et vidéo de 85 secondes |

Les règles 2.3.3, 3.1.2 et 5.1.1 figurent dans les conseils généraux du message initial. Elles ne sont pas trois motifs de refus supplémentaires enregistrés. Developer Rejected/Removed ne constitue pas un nouveau rejet Apple sur le fond. Les définitions officielles sont dans [App and submission statuses](https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-submission-statuses).

Les Notes reconnaissent que la vidéo commence dans le sélecteur Fichiers, alors que la demande initiale exigeait un démarrage au lancement de l'app. Elles mentionnent l'iPhone 15 Pro sous iOS 27 et aucun autre appareil testé. Cet audit n'a pas refait ce test physique ni identifié la build filmée. Le dossier enregistré ne contient pas le nouvel export Clairières 1.0.2 du Bureau.

Les Notes et la description publique annoncent des réglages français/anglais. La lecture native ne confirme pas un changement réel de langue : voir le constat F5.

## Constats prioritaires

| ID | Niveau de preuve | Conséquence et action recommandée |
| --- | --- | --- |
| F1 — médias tiers embarqués | Bundle Debug frais et provenance confirmés ; autorisations incomplètes | Retirer/remplacer les contenus de franchises sans permission ; établir les licences des ressources conservées |
| F2 — PrivacyInfo du host | APIs actives et absence de catégories confirmées dans le bundle | Ajouter les raisons applicables dans le host, puis contrôler l'archive distribuable |
| F3 — interprétation non bornée | Reproductions ciblées, installation réelle acceptée, source recoupée | Prévenir le blocage sur boucles script/dialogue ; l'inspection et le smoke actuels ne suffisent pas |
| F4 — privacy accessible et purpose strings | Lecture exhaustive du host et comparaison du plist compilé | Ajouter le lien privacy dans les réglages ; aligner les descriptions d'accès avec les fonctions réellement offertes |
| F5 — langue annoncée | Préférence sauvegardée, aucun consommateur identifié | Implémenter le changement ou corriger les promesses du dossier |
| F6 — preuve de distribution | Aucun IPA App Store examiné | Une build Debug ne certifie pas la build 376 ; vérifier une nouvelle archive exacte et son parcours physique |

### F1 — ce qui reste effectivement dans le runtime

La suppression des 33 PNG Balls et du ZIP d'icônes est confirmée dans le nouveau bundle : zéro Balls, zéro ZIP. Elle ne signifie pas suppression de tous les contenus de franchises.

Déclaration : `packages/map_runtime/pubspec.yaml:48`. Inventaire physique : 305 fichiers, 20 471 033 octets, 299 SHA256 uniques. Un shader est également déclaré hors de ce répertoire ; il n'est pas inclus dans ce compteur.

| Groupe | Quantité | Résultat |
| --- | ---: | --- |
| battle_animations | 180 PNG + un catalogue binaire | PNG identiques aux sources PSDK |
| audio/battle/se | 104 | Identiques au projet PSDK |
| transitions | 15 PNG | Identiques au projet PSDK |
| battle/stats | 2 PNG | Identiques au projet PSDK |
| cinematics/emotes | 2 PNG | Identiques au projet PSDK ; conservation demandée par Yoahn |
| premium_splash_jingle | 1 WAV | Provenance/licence non retrouvée dans les sources consultées |

303 ressources sont identiques aux sources PSDK ; le catalogue est généré et le jingle est distinct. Désactiver Pokémon dans un projet ne retire pas les répertoires Flutter déclarés du bundle.

`goku_1.png` contient visuellement Goku et Super Saiyan ; `vegeta1_1.png` est également embarqué. `bulbasaur_vine_whip.png` porte un crédit explicite de ripping ; les pixels examinés montrent des effets, pas un personnage Bulbasaur. Ces feuilles ne sont pas référencées par le catalogue binaire, mais leurs fichiers entiers sont bien livrés. L'absence d'affichage pendant le jeu n'est pas une preuve de droit de distribution.

`ifrit_1.png`, `shiva_1.png` et `ryu_1.png` sont référencés par des animations. L'origine exacte de tous leurs personnages et l'affichage de chaque cellule en combat ne sont pas prouvés : noms de fichiers et ressemblance seuls ne suffisent pas à certifier une franchise ou une infraction.

Empreintes de samples : Goku `6bfdc48fad0eba3911025b73498ee0538caeac8c35a3637b009ba812a905e03e` ; Bulbasaur Vine Whip `ec36bebdefa8ba4ea0a86624e62e7edeb21fb28c1a598e77fd75953eeabd8c43`.

La provenance RPG Maker XP est démontrée pour **106 ressources** : 87 sons identiques par SHA256, 19 PNG identiques en dimensions et pixels RGBA au RTP officiel. 18 de ces images sont référencées par 186 animations. Le catalogue décodé compte 874 animations et 89 assetIds ; tous les octets sont consommés par le décodeur. Il ne s'agit donc pas uniquement de ressources mortes.

RTP officiel : https://assets.rpgmakerweb.com/xp_rtp104e.exe , 22 994 937 octets, SHA256 `b3bd20ad7f413b40ac233aafd2e061de1dc429c2eadb59d0b3157ba3c47f16b2`. 888 fichiers décodés sans exécution de l'installateur Windows. Exemple : `001-system01.ogg` identique à `app/Audio/SE/001-System01.ogg`, SHA256 `b48505f044c42dd495e8713c33b0f66f6999d28d8644f7a10e0e2564ada78708`.

Les [conditions officielles RPG Maker actuelles](https://rpgmakerofficial.com/en/support/rule/) incluent XP et permettent certains usages dans d'autres moteurs aux acquéreurs autorisés, sous leurs conditions. Il serait donc faux de conclure que Flutter est interdit par principe. Le [contrat RTP gratuit](https://www.rpgmakerweb.com/downloads) est plus limité. Licence applicable, achat, notices, exclusions et conditions de distribution restent à établir pour Yoahn. Les permissions RPG Maker ne couvrent pas automatiquement des personnages tiers.

Les [crédits PSDK](https://pokemonworkshop.com/en/sdk/credits/) établissent une attribution, pas toutes les permissions de republication. La [licence MIT de PSDKTechnicalDemo](https://raw.githubusercontent.com/PokemonWorkshop/PSDKTechnicalDemo/master/LICENSE) concerne ce dépôt ; aucune licence universelle des pixels Pokémon, Dragon Ball ou autres ne peut en être déduite. Aucun LICENSE du moteur local n'a été retrouvé : l'audit ne certifie pas « le moteur PSDK est MIT ».

[Pokémon Support](https://support.pokemon.com/hc/en-us/articles/360000634094-Can-I-use-Pok%C3%A9mon-images-or-materials) demande de ne pas utiliser/associer leurs personnages, noms et designs aux projets. [Nintendo](https://www.nintendo.com/au/legal/nintendo-intellectual-property/) indique que son silence ne vaut pas permission. Ces sources ne constituent pas une décision judiciaire sur chaque ressource ; elles empêchent de traiter la gratuité comme une autorisation.

Showdown/PokeAPI : imports de données retrouvés dans `map_authoring`, pas de client distant actif retrouvé dans le host/runtime. Les identifiants Showdown sont consommés localement par les résolveurs de bataille. [Serveur Showdown MIT](https://raw.githubusercontent.com/smogon/pokemon-showdown/master/LICENSE), [client AGPLv3](https://raw.githubusercontent.com/smogon/pokemon-showdown-client/master/LICENSE) : licences distinctes. Aucun JavaScript Showdown embarqué identifié, sans certification exhaustive de toute copie de code. [PokeAPI/sprites](https://raw.githubusercontent.com/PokeAPI/sprites/master/LICENCE.txt) et [smogon/sprites](https://github.com/smogon/sprites) distinguent expressément les droits des images ; code libre et données d'origine ne prouvent pas les droits sur les visuels.

Le jingle est joué par `runtime_splash_jingle_controller.dart:112–126`. Sa provenance n'a pas été retrouvée. Les textures eclipse ont un générateur interne (`packages/map_player_ui/tool/generate_splash_textures.py:21`). Les manifestes de branding documentent des générations et des logos fournis par l'utilisateur ; ils ne constituent pas une certification externe de tous les titres.

Complément notices confirmé dans le même bundle, sans rebuild : les trois TTF Cormorant, DM Sans et Marcellus sont livrées. Leurs copyright et de courtes mentions OFL/URL sont dans les métadonnées TTF ; les textes OFL complets ne sont ni dans ces métadonnées, ni dans `NOTICES.Z`, ni dans des fichiers séparés. `NOTICES.Z` fait 110 853 octets, 1 444 650 après décompression, zéro mention SIL OPEN FONT LICENSE ou nom de ces trois polices. Les textes complets sont disponibles dans les fichiers source OFL, mais leur livraison n'est pas déclarée. Ajouter ces notices à la distribution et les rendre accessibles ; ce constat documentaire n'est pas un motif Apple déjà enregistré. Receipt : `/tmp/avelune-ball-checks/native-ios-font-notices-20261001.json`.

### F2 — privacy manifest du host

`SettingsView.swift:4–5` utilise `@AppStorage` pour les préférences. `HubPlatformChannel.swift:35–44` lit les capacités disque ; le canal est instancié dans `AppComposition.swift:15`, appelé par `ios_hub_platform_adapter.dart:24` et par l'installer à la ligne 228 avant staging.

Le bundle compilé contient huit `PrivacyInfo.xcprivacy`. Aucun dans le host/App.framework ; aucune catégorie UserDefaults ou DiskSpace dans l'ensemble. Flutter déclare FileTimestamp et SystemBootTime ; les manifests SDK n'ajoutent pas les raisons manquantes du host.

Apple exige les déclarations des APIs à raison obligatoire : [documentation générale](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), [TN3183](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest). Les raisons proposées à vérifier pendant le correctif sont CA92.1 pour les préférences propres à l'app et E174.1 pour le contrôle d'espace avant écriture, conformément à [NSPrivacyAccessedAPITypeReasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons). Ne pas copier des raisons d'exemple sans vérifier leurs conditions et le comportement observable.

Ce défaut est confirmé pour le bundle Debug reconstruit ; l'audit n'affirme pas que l'IPA 376 contient exactement les mêmes manifests ni qu'Apple l'a déjà rejetée pour ce motif.

### F3 — deux boucles non bornées

L'import est fortement contrôlé : allowlist de données/médias/textes, rejet notamment de Dart, JS, Wasm et binaires exécutables, contrôles ZIP/chemins/symlinks, réinspection avant extraction, validation puis smoke avant promotion. Le format pilote néanmoins des comportements via les interpréteurs intégrés : « pas de code arbitraire importé » est plus exact que « aucun comportement exécutable ».

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:11341–11410` : consommation synchrone des steps script sans budget/yield.
- `packages/map_runtime/lib/src/application/script_runtime_controller.dart:121–125` : goto pouvant revenir au même point.
- `dialogue_runtime_models.dart:216–264` : résolution successive des jumps sans budget.
- `apps/pokemap_hub/lib/features/installation/data/repositories/installed_project_smoke.dart:30–36` : chargement du projet, sans jouer tous les événements.

La reproduction corrigée est acceptée par ProjectValidator, MapValidator, builder, inspector et installer de production avec `loadInstalledProjectSmoke`. Pour le script, 1 000 steps donnent 1 000 jumps, sans terminaison/suspension ni progression. Le chemin de consommation synchrone explique le risque de gel. Pour le dialogue, la méthode ne revient pas ; le worker est arrêté volontairement après 10,246 secondes. L'installation complète réussit, avec smokeCompleted=true : le contrôle de chargement ne détecte pas cette classe de défauts.

Le premier essai de fixture est correctement rejeté pour un ruleset manquant ; il n'est pas une preuve positive. Les receipts corrigés et la contrelecture finale confirment le constat. Aucune UI utilisateur n'a été volontairement bloquée, aucun appareil physique ni IPA 376 n'a été utilisé. Les limites présentes dans Scene/scenario ne protègent pas automatiquement ces deux interpréteurs.

Correctif recommandé : bornes et restitution de contrôle au moteur, diagnostic compréhensible, validation pertinente des chemins sans interdire toute boucle de gameplay légitime. Vérifier avec des tests de non-blocage et des projets normaux ; aucune correction appliquée ici.

### F4 et F5 — host natif, permissions et langue

Les 18 fichiers Swift du host et le Dart d'entrée ont été examinés : 2 152 lignes Swift, 218 lignes Dart. `SettingsView.swift` offre langue/debug/version, sans lien privacy accessible. Le lien existe dans le HubShell partagé, mais le host natif utilise `HubInstalledGamePlayer`, pas ce shell. L'URL correcte dans App Store Connect ne rend donc pas la politique accessible dans ce host.

`Info.plist:27–32`, confirmé dans le bundle, indique que caméra et localisation ne sont pas utilisées et invoque une dépendance technique. Photothèque : choix d'un fond personnalisé. Aucun appel de caméra/localisation/sélecteur photo ou fonction de fond personnalisable n'a été retrouvé dans le parcours natif étudié. Ces clés ne prouvent ni collecte ni affichage d'une permission ; si un accès est demandé, la justification technique ne décrit pas un bénéfice utilisateur. Supprimer les déclarations/dépendances inutiles ou fournir une vraie finalité pour toute fonctionnalité conservée, puis tester les prompts réels.

Le bouton English sauvegarde `preferredLocale` (`SettingsView.swift:33`), mais aucun autre consommateur natif/Dart n'a été identifié. Les libellés natifs restent codés en français et aucune injection de locale n'est trouvée. Le dossier annonce actuellement plus que ce qui est démontré. Ce point est moins grave que F1–F3 mais doit être aligné.

Recherche ciblée : pas de compte, StoreKit, abonnement, publicité, tracking ou client analytics actif trouvé dans le host et les packages de lecture. Pas de constructeur produit du serveur de contrôle local retrouvé dans le point d'entrée. Le chemin vidéo réseau générique existe, mais le resolver du Hub fournit un fichier local ; audio également local. Il ne s'agit pas d'une capture réseau, d'une certification de tous les SDK ni d'une preuve absolue d'absence de télémétrie. Les pages support/privacy publiques ont été relues ; leur fonctionnement local déclaré est cohérent avec ces recherches bornées.

## Cartouches et médias de review

| Archive du Bureau | Résultat actuel |
| --- | --- |
| Les_Clairieres_v1.0.2.avelunegame | 42 entrées dont inventaire, 41 payloads ; Pokémon désactivé ; zéro chemin Pokémon ; 17 PNG, dont 11 identiques au pack ERW local |
| Le_train_de_17h42_v0.1.9.avelunegame | 12 334 entrées dont inventaire, 12 333 payloads ; Pokémon activé ; description avec Pokémon ; 11 070 chemins contenant Pokémon ; aucun fichier de licence/crédits identifié par son nom |

SHA256 Clairières : `a00ab777ccd244d2e5925f912a9ec51afa50b551214b8e56eaf7529f1fafce8c`. Train : `5143c2d01fa4391da34d9b3bd459dc23247bcf6658636e6322f8ac0f85b16c9a`.

Les fichiers sont des exports `localTest`, pas une certification de publication. Le déplacement de médias vers le Train sépare moteur et contenu mais ne crée pas les droits de redistribuer ce contenu. Le pack de review actuellement déclaré contient uniquement Clairières 1.0.1, pas le Train.

Les [conditions ERW de RafaelMatos](https://rafaelmatos.itch.io/epic-rpg-world-pack-grass-land20-asset) permettent des projets personnels/commerciaux et modifications, avec restrictions de redistribution/revente des assets. Cela ne signifie pas qu'une cartouche de jeu est interdite parce que ses fichiers sont extractibles. Un pack réutilisable livré comme bibliothèque d'éditeur poserait une question différente. Le ZIP local ne prouve pas un achat ; les droits applicables restent à documenter.

Les trois captures de review montrent l'interface réelle de bibliothèque. Une capture de partie serait utile pour expliquer la fonction de lecture ; son absence ne suffit pas à conclure seule à un refus automatique. Refaire la vidéo depuis le lancement de l'app et contrôler qu'elle représente la build effectivement proposée.

## Règles actuelles et précédents

Synthèse courte des [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) : 2.1 concerne l'app complète et l'accès reviewer ; 2.3.3 les captures réelles ; 5.1.1 la confidentialité et son accès ; 5.2 les droits tiers. 2.5.2 et 4.7 demandent une qualification précise du lecteur. 1.2.1 fournit un cadre possible aux expériences de créateurs, avec obligations associées. Paiements 3.1.1 et abonnements 3.1.2 ne deviennent pertinents que pour une offre correspondante. Modération, index/liens et contrôles d'âge dépendent notamment de la classification retenue et du contenu proposé. Le 4+ déclaré n'est pas une preuve de conformité de tous les futurs jeux importés.

L'[accord Apple Developer Program, 3.3.1(B)](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) prévoit des conditions pour du code interprété téléchargé, dont la stabilité de la finalité principale et le respect de la sécurité. Ce texte, actualisé dans l'[annonce du 8 octobre 2025](https://developer.apple.com/news/?id=fnkpd51y), soutient une défense d'un moteur spécialisé ; il ne dispense pas des Guidelines. La finalité éducative est une justification peu adaptée à une app de lecture de jeux.

| Évolution Apple | Source primaire et portée |
| --- | --- |
| 25 janvier 2024 | [Streaming games et mini-apps](https://developer.apple.com/news/?id=f1v8pyay) : ouverture de modèles auparavant limités |
| 5 avril 2024 | [Émulateurs de consoles rétro](https://developer.apple.com/news/?id=0kjli9o1) |
| 1 août 2024 | [Émulateurs PC](https://developer.apple.com/news/?id=ty0avr2s) |
| 13 novembre 2025 | [Mise à jour HTML5/JavaScript et règles mini-apps](https://developer.apple.com/news/?id=ey6d8onl) |

Avelune n'émule pas automatiquement un PC ou une console rétro parce qu'il lit des jeux. Le [Mini Apps Partner Program](https://developer.apple.com/programs/mini-apps-partner/) n'est pas un certificat générique pour JSON ni une inscription automatiquement nécessaire à tous les lecteurs RPG.

Les applications suivantes ont une fiche et une présence vérifiées en France et aux États-Unis au moment de la recherche. Elles ne prouvent pas le motif précis de leur acceptation.

| Application | Pourquoi elle est pertinente | État relevé |
| --- | --- | --- |
| [hyperPad Hub](https://apps.apple.com/us/app/hyperpad-hub/id1484881474) | Lecteur de jeux créés avec un moteur visuel ; proche du modèle séparant outil et joueur ; [behaviors officiels](https://www.hyperpad.com/features/behavior-system) | 2.8, mise à jour 21 septembre 2026 |
| [iEasyRPG](https://apps.apple.com/us/app/ieasyrpg/id6749200577) | Import/lecture RPG Maker 2000/2003 ; port tiers, pas app officielle EasyRPG | 1.5, 19 mai 2026 |
| [RPGPlayer](https://apps.apple.com/us/app/rpgplayer-an-rpgmaker-player/id6754986970) | Import via Fichiers de jeux RPG Maker, avec technologies de lecture différentes | 2.3, 12 février 2026 |
| [Codea](https://apps.apple.com/us/app/codea/id439571171) | Création/exécution Lua ; contexte éducatif différent | 3.17, 5 mai 2026 |
| [iDOS 3](https://apps.apple.com/us/app/idos-3/id1580768213) | Émulateur PC, catégorie explicitement ajoutée par Apple | 3.3, 6 août 2025 |
| [RetroArch](https://apps.apple.com/us/app/retroarch/id6499539433) | Émulation rétro ; pas le même moteur qu'Avelune | 1.22.2, 18 novembre 2025 |

Historique contradictoire utile : le développeur iDOS documente un [refus 2.5.2 en 2021](https://litchie.com/2021/07/idos2-will-be-gone) lié notamment à l'import local ; l'app est retirée. En 2024, il décrit encore des [refus de classification](https://litchie.com/2024/04/new-hope), puis une [approbation le 9 août](https://litchie.com/2024/08/idos3-approved), après l'annonce Apple autorisant les émulateurs PC. Ces récits primaires montrent que les règles et la catégorie ont changé ; « import local » seul n'a jamais été une garantie.

Précédents écartés : LowRes NX n'est pas actuellement retrouvé dans les stores FR/US consultés ; son [auteur en 2023](https://lowresnx.inutilis.com/topic.php?id=3035) parle d'adhésion développeur payante, pas d'un refus de contenu. [RPG Architect](https://docs.rpg-architect.com/01-welcome/) annonce iOS/Android comme prévu, pas comme livraison prouvée. Les [downloads officiels EasyRPG](https://easyrpg.org/player/downloads/) ne suffisent pas à prouver sa distribution iOS officielle.

## Commandes, résultats et receipts

SDK : Flutter 3.48.0-0.4.pre, révision `e3005e3402d9cfa2043114c8bc53c59d12e9b98e`, Dart 3.14 beta. Xcode 27.0, build 27A5194q. Les exécutions longues passent par `/tmp/avelune_ball_check.py --reap-tests <label> -- <commande>` avec PID/descendants suivis.

| Vérification fraîche | Résultat exact |
| --- | --- |
| `dart test test/game_package_inspector_test.dart`, dans packages/map_distribution du clone | 21 tests, All tests passed!, exit 0 |
| `dart --packages=.../packages/map_runtime/.dart_tool/package_config.json /tmp/asc_execution_repro_20261001.dart check`, fixture corrigée | exit 0 ; validators/builder/inspector true ; 1 000 jumps sans progression |
| Même script, mode `hang-dialogue`, worker borné de l'audit | timeout 10,246 s ; arrêt ciblé SIGTERM, exit -15 attendu pour ce constat ; aucun descendant restant |
| `flutter test test/install_repro_test.dart --reporter expanded`, dans /private/tmp/asc_execution_install_20261001 | 1 test, All tests passed!, exit 0 ; installation et smoke acceptent le contenu concerné |
| `flutter pub get`, dans apps/Avelune iOS/flutter_runtime du clone | exit 0 ; aucun fichier suivi modifié |
| `flutter build swift-package --platform ios --build-mode debug --no-pub --no-codesign -o '/private/tmp/avelune-media-release-20261001/apps/Avelune iOS/flutter_runtime/build/swift-package'` | exit 0 |
| `python3 tool/patch_swift_package.py flutter_runtime/build/swift-package`, dans apps/Avelune iOS | exit 0 ; artifacts générés ignorés uniquement ; pas de xcodegen |
| `xcodebuild -project AveluneiOS.xcodeproj -scheme AveluneiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/avelune-native-ios-audit-derived-20261001 CODE_SIGNING_ALLOWED=NO build` | exit 0, BUILD SUCCEEDED ; 68 diagnostics directs warning, zéro error |

Les 22 tests verts comprennent un test prouvant l'acceptation d'un contenu qui bloque ensuite un interpréteur : ils ne constituent pas une correction du défaut. Pas de répétition des suites complètes ni analyse complète fraîche du monorepo ; code inchangé, vérifications ciblées ici. Les résultats de tests du lot de migration précédent sont distincts et ne sont pas présentés comme nouveaux.

Bundle frais : 1.0.2 (1), Simulator, minimum iOS 17, architectures arm64/x86_64 ; 452 fichiers Flutter assets dont les 305 runtime ci-dessus. Signature ad hoc du linker, sans TeamIdentifier ; aucun signing distribué. Ni ce bundle ni les versions techniques 1.0 des frameworks ne sont l'IPA App Store build 376.

Les warnings viennent principalement des plugins et d'un ancien search path Release inexistant dans project.yml. Ils n'empêchent pas cette compilation ; l'audit ne les transforme pas en 68 défauts de l'app.

Receipts temporaires : `/tmp/avelune-ball-checks/asc-exec-distribution-20261001a.{txt,json}`, `asc-exec-repro-check-20261001c.{txt,json}`, `asc-exec-install-20261001a.{txt,json}`, `native-ios-pub-20261001.{txt,json}`, `native-ios-swift-debug-20261001.{txt,json}`, `native-ios-xcode-debug-20261001.{txt,json}`, `native-ios-bundle-inspection-20261001.json`, `native-ios-xcode-cleanup-20261001.json` ; contrôle dialogue : `/tmp/asc_execution_repro_20261001.json`.

Les wrappers natifs suivent respectivement 3, 157 et 752 PID. Les deux ibtoold momentanément présents ont quitté naturellement ; receipt cleanup final : zéro descendant restant. Aucun kill par nom de processus. Contrôle SHA256 de 10 052 entrées Git suivies du clone : aucun écart.

Assets/licences : recherches rg ciblées ; inventaire SHA256 ; comparaison Pillow des pixels RGBA et dimensions ; inspection ZIP sans mutation des projets ; décodage du catalogue avec assertion de consommation intégrale ; téléchargement du RTP officiel et extraction innoextract temporaire. L'installateur n'est pas exécuté, aucune installation système persistante. Sources et outils RTP temporaires supprimés après contrôle.

## Inventaire des zones examinées et mutations

Zones principales : host SwiftUI complet, `flutter_runtime/lib/main.dart`, Info.plist, project.yml/pbxproj et scripts runtime/CI ; `map_distribution` inspector/ZIP/content policy ; `pokemap_hub` installer/smoke/adapter/startup ; `map_core` codecs/validators ; interpréteurs et render/media de `map_runtime` ; modèles et video adapter de `map_player_ui` ; importeurs battle/RMXP/SE/transitions/stats, résolveurs et catalogue binaire ; importeurs Showdown/PokeAPI authoring ; assets et manifestes branding/fonts ; sources PSDK externes, RTP officiel et deux cartouches du Bureau. Les référentiels PSDK sont lus, jamais modifiés ni copiés dans Git.

Fichier créé par cet audit : **uniquement ce rapport**, `documentation/reports/avelune/app_store_submission_audit_20261001.md`. Ses sections consignent verdict, audit initial, dossier live, constats, recherches, commandes, limites et critique. Aucun diff de production, aucune migration, aucune mutation de cartouche ou de metadata Apple, aucun commit/push/tag. Les artifacts de compilation et fixtures restent temporaires hors fichiers Git suivis.

Avant le rapport, le checkout principal passe de 196 à 226 entrées sales : 30 entrées concurrentes supplémentaires dans Studio/map_authoring/map_core, principalement catalogue/lifecycle de maps. Aucun des agents de cet audit ne les a écrites ; aucune entrée initiale n'a disparu dans la comparaison conservée. Elles restent intégralement préservées. Mesure intermédiaire après ajout du rapport : 228 entrées, dont `apps/avelune_studio/test/map_workspace/map_catalog_transaction_guard_test.dart` concurrent. Contrôle de clôture : 230 entrées, même HEAD ; le chantier concurrent continue d'ajouter des fichiers pendant la rédaction. Ce compteur décrit l'instant mesuré, pas une immobilisation du worktree partagé. Le seul fichier créé par cet audit reste le rapport. Clone release propre au même SHA, `git diff --check` final exit 0.

Le garde-fou Markdown est exécuté avec son plafond par défaut, sans override. Le rapport CI préexistant `documentation/reports/ci/post_ci_001_quick_checks_evidence_pack.md` dépassait déjà le budget de zéro avant l'audit. Le présent rapport unique demandé par le périmètre d'audit ajoute une deuxième pièce ; cette limitation de budget doit être signalée, pas contournée en changeant l'environnement ou en ajoutant des fichiers à l'index. Résultat frais : exit 1, `Markdown hygiene: 2 new Markdown files exceed the default limit of 0.` Les deux pièces sont dans les emplacements canoniques. `git diff --check` : exit 0. Le script d'hygiène du clone : exit 0, aucun nouveau Markdown.

## Passes indépendantes, critique et suivi

| Passe | Verdict |
| --- | --- |
| Audit exécution / architecture / tests | Import fortement contrôlé ; deux boucles non bornées prouvées. Le rendu final de l'agent n'a pas été produit ; ses receipts et constats ont été relus par la critique indépendante |
| Audit assets / licences | Provenance détaillée confirmée ; droits non démontrés pour tout le bundle ; pas de conclusion générale d'interdiction RPG Maker |
| Recherche Apple / précédents | Modèle défendable, classification et résultat non garantis ; précédents et contre-exemple historique vérifiés |
| Build / validation native | Debug compilé et bundle contrôlé ; défaut privacy du host confirmé ; aucune preuve de distribution ou parcours physique |
| Passe parent iOS / ASC | Dossier réel vérifié en lecture seule ; F4/F5 et état Developer Rejected/Removed confirmés ; pas de nouveau motif Apple inventé |
| Implémentation | Non applicable à ce lot d'audit ; aucun correctif appliqué |
| Critique finale indépendante | Aucun faux positif sur les boucles/privacy. Séparer source, Debug et IPA ; ne pas confondre provenance et droits, reader JSON et exemption 4.7, retrait développeur et refus Apple |

Suivi dans le contexte existant [POST-AVL-IOS-UI-002](https://app.notion.com/p/3e7197a7bfa581dbac82d3f1bb426820), famille unique Post Bêta 12 — Avelune Player. Statut TO REVIEW, aucun DONE, aucun ticket nouveau, aucune extension de critères beta ou UI signés. Les bugs et conditions de prochaine soumission sont consignés dans ce contexte de release.

Auto-critique : l'audit est approfondi sur les chemins ciblés, mais ne peut prouver « zéro risque dans tout le code ». Les ressources de franchises ont été établies par pixels/crédits lorsque possible, pas uniquement par noms. Les licences ne sont pas inférées d'un dépôt permissif. Les données interprétées peuvent produire un comportement même sans JS/Dart importé. Les statuts ASC et les droits dépendent d'informations qui peuvent changer. Les preuves de build ne couvrent ni App Review ni le parcours réel de la build distribuée.

## Conditions recommandées avant une nouvelle soumission

1. Constituer un bundle Player dont chaque média livré a une provenance et un droit d'usage démontrés ; retirer les feuilles de franchises inutilisées, remplacer les ressources sans permission et documenter les notices. Une copie déplacée dans une cartouche publique conserve la même question de droits.
2. Corriger les déclarations privacy du host et rendre sa politique accessible ; vérifier les accès réels et les purpose strings.
3. Borner les interpréteurs script/dialogue et vérifier l'absence de blocage, sans casser les boucles de jeu légitimes.
4. Aligner langue annoncée, captures, Notes, sample et vidéo. Garder Clairières comme démonstration originale avec licence ERW documentée. Vérifier la pertinence de l'âge déclaré et expliquer précisément le moteur fermé/import local.
5. Construire une nouvelle archive iOS distribuable contenant ces changements ; inspecter assets/manifests/notices de cette archive et sélectionner cette build dans ASC.
6. Sur iPhone physique, rejouer lancement, import, navigation, jeu, dialogues, sauvegarde/reprise, pause et retour. Réaliser une vidéo depuis l'icône de lancement, puis actualiser les vrais appareils/OS testés.

Une fois ces conditions vérifiées, une soumission est raisonnable. Les précédents rendent le modèle crédible ; ils ne remplacent ni les droits sur les médias ni l'appréciation finale d'Apple.
