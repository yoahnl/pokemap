# Avelune — Asset Context and Asset Packs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: utiliser [executing-plans](../../../../skills/executing-plans/SKILL.md), ou [subagent-driven-development](../../../../skills/subagent-driven-development/SKILL.md) si le mode de délégation est retenu. Exécuter les lots dans leur ordre de dépendance et conserver les preuves de chaque gate.

**Goal:** distinguer les ressources d'intérieur et d'extérieur, puis exporter et installer des bibliothèques natives 2D/3D complètes et sélectionnables, contenant des milliers de ressources sans écraser le travail du projet.

**Architecture:** la classification appartient au catalogue transversal de map_core. Le format portable est contrôlé par map_distribution ; map_authoring possède la fermeture de dépendances, le remappage, les opérations longues, les transactions et les reçus. Avelune Studio et le MCP consomment ces contrats communs.

**Tech Stack:** Dart/Flutter, contrats JSON natifs, ZIP STORE déterministe, SHA-256, staging privé sur disque, transactions journalisées, API directe/JSONL/MCP, design system Studio.

---

## 0. Statut, demande et périmètre

- Date : 16 octobre 2026.
- Ticket existant : [POST-WLD-ASSET-PACK-001](https://app.notion.com/p/3fb197a7bfa581379199ceec8afe5486).
- Domaine unique : Monde & narration, Post Bêta. Aucun changement de gate ou dépendance bêta.
- Plan initial puis suivi d’exécution autorisée : les statuts, commits et preuves actuels sont en section13. Les descriptions des lots fixent la cible ; elles ne prouvent pas à elles seules sa réalisation.
- La rédaction initiale ne modifiait aucun code ; Yoahn a ensuite autorisé l’implémentation et un commit par lot. P13, constitution des galeries, est explicitement reporté.
- Source inspectée : main, 00c3112c0754ee54553584d38f7e44598c3077c3 ; checkout partagé avec modifications préexistantes/concurrentes.
- Autorisation ultérieure : commits propres par lot et prérequis natifs précis. Aucun push, rebase, changement de branche ou worktree autorisé.
- Un seul document persistant est prévu pour cette mission. Les futures preuves de réalisation complètent ce document ou le ticket ; aucun rapport par agent.

La demande couvre deux capacités livrables : la classification des ressources et le transport de bibliothèques. Les cinq collections Pokémon sont le contenu destiné à utiliser ces capacités, avec une qualification distincte :

| Collection | Univers stable | Cible demandée |
|---|---|---|
| Rubis / Saphir / Émeraude | pokemon.rse | 2D |
| Rouge Feu / Vert Feuille | pokemon.frlg | 2D |
| Diamant / Perle / Platine | pokemon.dppt | 3D, avec sprites si nécessaires |
| HeartGold / SoulSilver | pokemon.hgss | 3D, avec sprites si nécessaires |
| Noir / Blanc | pokemon.bw | 3D, avec sprites si nécessaires |

Noir 2 / Blanc 2 n'est pas ajouté implicitement. La présence d'images n'est pas une preuve de disponibilité de modèles 3D, de collisions préparées ou d'une collection complète.

### Hors du premier système

Boutique distante, abonnement, téléchargement automatique, extraction de ROM, conversion universelle de modèles DS, synchronisation de bibliothèques externes, remplacement automatique de ressources locales, mises à jour en place, désinstallation destructive de packs et nouveau moteur de gameplay.

L'import copie les ressources dans le projet. Le projet reste utilisable sans le fichier du pack ni un service distant.

## 1. Audit de départ et conséquences

| Code actuel | Preuve et conséquence |
|---|---|
| packages/map_core/lib/src/models/resource_library_catalog.dart:41–108 | Overlay par identité typée kind:id, famille, portée carte et rôle. Ajouter un contexte ici. |
| Même fichier:168–205,224–227 | Format strict v1 ; sept kinds ; availableForMap est une vraie restriction de portée, indépendante du futur contexte. |
| packages/map_authoring/lib/src/domains/assets/resource_library_actions.dart:14–84,201–221 | Classification individuelle et batch100, sémantique absent/null, suppression des entrées neutres. Étendre ce contrat. |
| packages/map_authoring/lib/src/references/resource_library_scope_guard.dart:194–209 | element.duplicate recopie les métadonnées explicitement ; ajouter le contexte. |
| apps/avelune_studio/lib/presentation/features/resources/resource_catalog.dart:42–78,273–281,344–399 | État, remise à zéro, révélation et prédicat commun de filtrage. |
| resource_library_bindings.dart:52–84 | Formulaire Ranger relié à resource.classify. |
| resource_library_layout.dart:109–132 | Les ateliers Bordures, Environnements et Modèles 3D contournent la grille commune. |
| packages/map_authoring/lib/src/workspace/project_query_service.dart:685–699,2191–2200 | Les requêtes d'overlay n'énumèrent pas les ressources sans métadonnées ; absent est distinct de null. |
| packages/map_authoring/lib/src/ports/artifact_store.dart:159–178,269–290 | Le staging local courant retient les octets en RAM ; plafond256Mio par artefact. |
| packages/map_authoring/lib/src/transactions/change_set.dart:199–210 | Copies des images avant/après. Une archive sur disque ne suffit pas si les changements retiennent tous les binaires. |
| packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart:782–887 | Le snapshot charge et conserve sources logiques et blobs. Le chemin de réouverture doit évoluer aussi. |
| packages/map_authoring/lib/src/security/authorization_policy.dart:20–25 | Limites génériques :1Mio/requête,500 ressources touchées,60 opérations/minute. Ne pas les relever globalement. |
| packages/map_authoring/lib/src/tooling/jsonl_worker.dart:47–62 et tools/pokemap_mcp/src/authoring_client.ts:97–131 | Requête1Mio et deadlines courtes. Une opération longue doit libérer la boucle de commande et être suivie par job. |
| packages/map_authoring/lib/src/transactions/journaled_transaction.dart:159,275–283 | Garantie recoverable ; réécriture du journal entier à chaque promotion, problématique à grand volume. |
| packages/map_distribution/lib/src/random_access_package_source.dart et random_access_zip_structure_reader.dart | Lecture ZIP par accès aléatoire existante ; réutiliser le parseur dans le même package. |
| packages/map_distribution/lib/src/deterministic_zip_encoder.dart | Writer actuel en mémoire. Créer un writer vers sink pour les gros packs. |
| packages/map_distribution/lib/src/presentation_preset_pack_codec.dart | Précédent utile, mais ses quotas et son profil présentation ne sont pas le format de bibliothèque. |
| packages/map_distribution/lib/src/glb_model3d_inspector.dart:97–100,136–146 | GLB autonome avec buffers/textures embarqués. Aucune résolution d'URI externe à inventer pour le pack v1. |
| packages/map_authoring/lib/src/contracts/job_contracts.dart | DTO et port de jobs déjà présents ; les réutiliser avec un exécuteur spécialisé. |

L'infrastructure nécessaire au gros volume est dans le chemin critique. Une boucle de N imports unitaires, une requête base64 géante ou un relèvement global des quotas ne constituent pas la réalisation de ce plan.

## 2. Décisions de contrat

### 2.1 Contexte des ressources

Nouveau contrat dans resource_library_catalog.dart :

~~~dart
enum ResourcePlacementContext { interior, exterior, both }
~~~

ResourceLibraryEntry reçoit un champ optionnel ResourcePlacementContext nommé placementContext.

| Donnée | Sens |
|---|---|
| Donnée persistée absente ou null | Non renseigné |
| Paramètre de mutation absent | Conserver la valeur précédente |
| Paramètre de mutation null | Effacer la valeur et revenir à Non renseigné |
| interior | Intérieur |
| exterior | Extérieur |
| both | Intérieur et extérieur, choix explicite |

- Paramètre omis dans classify : conserver l'ancienne valeur.
- Valeur inconnue, chaîne vide, objet, liste, booléen ou nombre : refuser sans écriture.
- Une entrée contenant seulement placementContext doit rester dans le catalogue.
- Retirer l'entrée lorsque famille, portée carte, rôle et contexte sont tous neutres.
- Modifier constructeur, JSON strict, égalité, hash et roundtrip.
- Passer explicitement ResourceLibraryCatalog à formatVersion2. Rejeter v1 lorsqu'il est explicitement présent ; ne pas ajouter de migration ou de double lecteur.
- L'absence complète de catalogue continue de représenter un catalogue vide.
- Préserver les comportements déjà portés par MapMetadata.isIndoor et MapRole.
- Le contexte ne modifie ni availableForMap, ni compatibleWith, ni collisions, ni instances existantes, ni fermeture de dépendances.
- Un atlas mixte et les décors extraits ont des classifications indépendantes.
- « Sans famille » et « Contexte non renseigné » sont deux états indépendants.

### 2.2 Nom et enveloppe du fichier

- Nom produit : Avelune Game Assets.
- Extension proposée et utilisée par les tests du plan : .aveluneassets.
- MIME du contrat : application/vnd.avelune.asset-pack+zip.
- Identifiant de format : avelune.asset-pack.
- formatVersion :1, indépendamment de ResourceLibraryCatalog v2 et des versions projet2D/3D.
- Conteneur ZIP STORE uniquement : PNG et GLB sont déjà des formats compacts ; rester sur le profil borné et déterministe existant.
- Rejeter DEFLATE, ZIP64, chiffrement, liens symboliques, chemins ambigus et doublons selon le profil v1, avec un message explicite.
- Ne pas réutiliser l'extension .avelunegame, son game-manifest ou son installateur Player.

Arborescence normative :

~~~text
manifest.json
catalog.json
blobs/<raw-sha256>.<extension>
licenses/<raw-sha256>.txt
previews/<raw-sha256>.png
~~~

Chaque fichier est inventorié. Aucun fichier supplémentaire caché, chemin absolu, référence réseau, chemin de machine ou fichier exécutable.

### 2.3 Manifeste de pack

Les modèles de contrat partagés sont créés dans map_core. Le codec d'archive et les empreintes brutes sont dans map_distribution.

| Champ | Type et règle v1 |
|---|---|
| format | Chaîne exacte avelune.asset-pack |
| formatVersion | Entier exact1 |
| pack.id | Identité stable d'éditeur/collection, caractères ASCII a-z0-9._-,1–96 caractères |
| pack.version | SemVer sans métadonnée de build ; version publiée immuable |
| pack.name | Libellé utilisateur non vide,256 caractères maximum |
| pack.description | Texte,4096 caractères maximum |
| pack.universeId | Identifiant libre validé, par exemple pokemon.hgss ; aucune déduction depuis la dimension |
| pack.authors | Liste non vide de noms,128 caractères par nom |
| pack.provenance | Source et attribution déclarées ; ce champ n'est pas une certification automatique |
| compatibility.resourceLibraryCatalogVersion | Entier exact2 pour ce format |
| compatibility.requiredCapabilities | Liste triée de capacités réellement utilisées |
| compatibility.tileWidth / tileHeight | Taille native de cellule ; strictement positive et validée contre les contrats natifs |
| content.catalog | Chemin exact catalog.json, taille et rawSha256 |
| content.files | Inventaire trié chemin/taille/mediaType/rawSha256 de blobs, licences et aperçus |
| content.treeSha256 | Empreinte du contenu canonique hors manifest.json, avec domaine de hash documenté |

Le catalogue contient les définitions natives portables, leur identité locale de pack, leur classification et leurs références typées. Aucun ProjectManifest complet n'est embarqué.

Nouveaux types proposés :

~~~dart
enum ResourcePackKind {
  element,
  model3d,
  smartTilePreset,
  tileset,
  borderBlueprint,
  environmentPreset,
  character
}

final class ResourcePackRef {
  const ResourcePackRef({required this.kind, required this.id});
  final ResourcePackKind kind;
  final String id;
}

enum ResourcePackConflictPolicy { preserveProject, importCopy }

enum ResourcePackOperation { stage, inspect, prepare, import, export }
~~~

Les implémentations ajoutent les codecs stricts et l'égalité. Une référence utilise toujours kind+id ; ne jamais identifier une ressource par son nom visible.

Le contrat portable utilise resourceKind comme nom JSON du discriminant ; ses valeurs sont les noms exacts de ResourcePackKind. Les DTO Dart peuvent conserver le champ kind. Le sous-catalogue impose ces clés racines : tilesets, elements, models3d, characters, environmentPresets, smartTileCatalog, borderCatalog, resourceLibraryCatalog, elementCategories, tilesetFolders, characterStudioCatalog, files, provenance, extras. Une liste absente représente une liste vide uniquement lorsque le codec natif le permet ; aucune clé inconnue n'est ignorée.

Chaque entrée files est un ResourcePackFileBinding : id local au pack, logicalPath relatif virtuel, archivePath sous blobs/, rawSha256, byteLength, mediaType, provenanceId et licenseIds. Les IDs natifs sourceAssetId/assetId des définitions pointent vers ces bindings. Aucun ContentArtifactRef ni AssetRecord d'une ancienne session n'est sérialisé dans ce binding. À l'import, le moteur calcule ses propres AssetRecord et chemins cibles.

Le profil PNG v1 est statique, y compris pour les textures PNG intégrées aux GLB : après contrôle des bornes d'en-tête, chaque candidat est réellement décodé séparément ; les animations sont portées par les frames natives, pas par un APNG. L'inspecteur GLB reçoit ce profil explicitement, sans changer le profil existant des jeux. Les rectangles d'éléments/palette utilisent la grille canonique de leur atlas régulier ; les rectangles des animations de personnages suivent leurs unités natives et leur source effective. Sans source dédiée, une coordonnée de frame de personnage est multipliée par la taille effective du personnage et celle des cellules, comme dans le runtime actuel ; ce n'est pas une coordonnée de cellule d'atlas. Un tileset imageCollection autonome reste portable avec ses pages, tiles et animations natives. Une frame sans identifiant de tile sparse ne peut pas lui inventer une correspondance x→tileId : la combinaison non résoluble est refusée avec diagnostic, sans conversion implicite ni suppression de champs.

La section provenance contient des enregistrements id/author/sourceUrl optionnelle/licenseIds ; chaque licence renvoie à un document inventorié sous licenses/. Une URL de provenance est du texte d'attribution et n'est jamais téléchargée pendant inspection/import. Les versions de codecs natifs Smart Tiles/Border sont fixées explicitement par compatibility et vérifiées contre les constantes du lecteur.

Pour v1, chaque licenseId est le chemin d'archive exact licenses/<raw-sha256>.txt. Il se résout directement dans content.files, sans second registre de licences. Le document doit exister, être inventorié, avoir le MIME text/plain, la taille et le hash annoncés et contenir du texte UTF-8 valide. Tester licenseId inconnu, document non inventorié et UTF-8 invalide. La validité technique d'une déclaration ne certifie pas son étendue juridique.

Définition exacte de treeSha256 v1 : SHA-256 brut de UTF-8("avelune.asset-pack.tree.v1" + LF + CanonicalJson(rows) + LF), où LF est l'octet de saut de ligne10 et rows est la liste triée par chemin UTF-8 des objets path/byteLength/mediaType/rawSha256 de catalog.json et des fichiers inventoriés. manifest.json est exclu pour éviter une référence circulaire. CanonicalJson trie les clés d'objet et préserve l'ordre de la liste. Les dates de build et les handles n'entrent pas dans cette identité.

Pour chaque définition :

- id portable ASCII1–96 caractères ; l'exporteur alloue déterministement les IDs à partir des identités typées source et vérifie les collisions ;
- définition native validée par son codec actuel ;
- références de définitions réécrites en IDs locaux du pack ;
- classification familyId/role/placementContext, sans mapId ;
- liste des références typées sortantes et des fichiers réellement requis ;
- licence/attribution attachée ; une ressource sans déclaration de provenance reste non qualifiée pour la publication d'une collection ;
- aperçus optionnels, distincts des sources nécessaires ;
- types inconnus ou capacités non supportées : refus avant installation, aucune suppression silencieuse de champs.

Pour les propriétés natives de tilesets issues d'un import externe : résoudre les asset_reference par le binding files ; refuser les object_reference hors de la fermeture et les structured dont la sémantique de référence n'est pas définie. Un champ arbitraire n'est pas rendu portable en copiant son JSON.

### 2.4 Ressources et supports

| Ressource racine | Dépendances à parcourir et réécrire |
|---|---|
| element | tilesetId parent, tilesetId de chaque frame, groupes de tileset, catégorie et parents, source PNG/pages, collision et animations natives |
| model3d | AssetRecord source, GLB autonome, chemin canonique reconstruit avec le nouvel ID, pivot/échelle/inspection/collision |
| smartTilePreset | Matériaux autorisés/défaut, groupes de connexion, règles/candidats/pièces, atlas, animations, sources tileset/model3d et catégories |
| borderBlueprint | Définition publiée, primitives element/model3d et leurs dépendances, Smart Tiles des sols publiés et de chaque groundSurface via sourceSmartTilePresetId, matériaux via groundSurface.materialId ; reconstruction des identités de publication/snapshots après remappage |
| environmentPreset | Palette element/model3d et dépendances, catégorie, paramètres et collisions du preset |
| character | Tileset, animations, sources PNG d'animations, portraits, portraitStates et customAnimationDefinitions utilisées |
| tileset | AssetRecord et fichiers PNG/pages, rectangles/groupes, dossier de classement et tilesets des frames des paletteEntries ; tilesetId vide désigne le propriétaire |

Supports transportés une seule fois : familles personnalisées et parents, catégories de décors et parents, catégories de terrains, dossiers de tilesets, groupes internes, matériaux/atlas/animations/groupes de connexion Smart Tiles, états de portrait et définitions d'animation de personnage.

Les motifs Smart Tile autonomes ne sont pas atteints par une fermeture depuis un preset. Ajouter au catalogue un bloc extras.smartTilePatternIds et une sélection explicite « Inclure les motifs sélectionnés ». Ils ne deviennent pas un huitième kind de ResourceLibraryCatalog. Le remappeur couvre leurs références et le test de roundtrip les vérifie.

Règles d'export :

- ressources natives validées ; Smart Tiles publiés, bordures disposant d'une publication valide ;
- aucun brouillon privé de travail, reçu d'historique, carte, instance, dialogue, événement ou progression de jeu ;
- les supports nécessaires à l'édition de la ressource publiée sont inclus, sans exporter un brouillon utilisateur sans rapport ;
- une référence non portable non couverte par la matrice bloque la racine concernée avec diagnostic ;
- mapId privé est retiré dans la copie portable et affiché comme promotion à portée projet dans l'aperçu ; le projet source reste inchangé ;
- groupId lié à l'arbre des cartes et recommendedLayerId ne sont pas copiés comme identités valides dans un autre projet : aperçu des informations d'organisation retirées, acquittement explicite dans la sélection export ;
- isWorldTileset est une désignation unique du projet, pas une propriété activable par une bibliothèque : l'export le met à false dans la copie portable, le contrat refuse true et l'import préserve le choix monde du projet cible. Plusieurs tilesets alternatifs ordinaires peuvent donc coexister dans le pack ;
- toute donnée de rendu/collision/comportement prise en charge doit être conservée ; aucune normalisation silencieuse pour faire passer un export ;
- fermeture sur les références sortantes, distincte du graphe de consommateurs existant ;
- détection des références absentes et des cycles invalides avant écriture ;
- le contexte intérieur/extérieur ne coupe jamais une dépendance requise.

Le contrôle de portabilité des propriétés de tilesets couvre source.properties, tileDefinitions[].properties et collisionObjects[].properties. Le codec portable vérifie aussi les clés imbriquées avant les codecs natifs permissifs ; aucune clé inconnue n'est ignorée sous prétexte que le fromJson natif l'accepte. La neutralisation de recommendedLayerId couvre les paletteEntries.

### 2.5 Dimensions et échelles

- Le pack peut déclarer des ressources2D,3D ou mixtes ; les capacités sont déterminées par les définitions.
- L'import dans un projet reste soumis à la compatibilité native de chaque ressource et de sa fermeture.
- La présence d'une image2D de texture ou d'un personnage dans un pack3D est autorisée.
- Un décor natif2D incompatible avec un projet3D n'est pas converti implicitement en billboard.
- Les tailles de cellule incompatibles font refuser la sélection concernée ; aucun redimensionnement automatique de sprites, collisions ou modèles.
- Aucun changement automatique de caméra, de dimension projet, de météo ou d'éclairage lors de l'installation.
- Les capabilities requises sont calculées, puis comparées à celles du lecteur ; pas de simple confiance dans la liste déclarée.

## 3. Installation, identités et réimport

### 3.1 Sens d'« installer »

Inspecter une archive immuable → choisir les racines → calculer la fermeture → préparer un plan lié à la révision → appliquer une transaction récupérable → relire la bibliothèque.

L'installation n'ajoute aucune dépendance runtime au fichier du pack. Les images/GLB rejoignent AssetCatalog et le store natif ; les définitions rejoignent les catalogues natifs ; un reçu d'origine associe les identités du pack aux identités locales.

### 3.2 Catalogue d'origine

Créer ResourcePackInstallationCatalog, formatVersion1, stocké dans le manifeste projet par un champ optionnel resourcePackInstallations. Il contient :

- installationId stable ;
- packId, packVersion, universeId, archiveRawSha256 et catalogueRawSha256 ;
- racines sélectionnées et fermeture installée ;
- correspondance ResourcePackRef → identité native du projet ;
- correspondances des supports et AssetRecord ;
- empreintes de définition installées après remappage ;
- date d'installation informative, exclue des identités de déduplication ;
- statut qualifié de provenance distinct du succès technique.

Omettre ce champ lorsqu'il est vide. Le générateur Freezed/JSON du manifeste est régénéré uniquement dans map_core.

Le projet peut copier/exporter les ressources sans ce reçu ; le reçu sert à l'origine et à la déduplication, pas à leur disponibilité.

### 3.3 Politique v1 de conflits

| Situation | Comportement exact |
|---|---|
| Première installation | Allouer un espace d'IDs déterministe à partir packId/version/hash puis créer les ressources sans écraser |
| Même packId+version et même hash, même sélection | Résultat alreadyInstalled, aucune écriture ni historique supplémentaire |
| Même archive, nouvelle sélection partielle | Ajouter uniquement les racines et dépendances manquantes ; réutiliser les mappings déjà certifiés |
| Même packId+version, hash différent | Refus pack.identity_conflict ; demander une nouvelle version du pack |
| Nouvelle version du même pack | Installation côte à côte avec nouveaux IDs ; aucune mise à jour en place |
| Nom visible identique | Autorisé ; identité et origine lèvent l'ambiguïté |
| ID local déjà occupé par autre contenu | preserveProject garde le conflit non résolu et refuse l'application ; importCopy explicitement choisi alloue un mapping isolé et réécrit la fermeture |
| Ressource importée puis modifiée localement | Le réimport ne l'écrase pas ; indiquer « Modification locale conservée » |
| Dépendance déjà installée et modifiée, nouvelle racine à importer | Refuser la réutilisation silencieuse ; importCopy crée une fermeture isolée depuis le pack |
| Fichier identique déjà connu du store | Réutiliser les octets certifiés ; vérifier digest et longueur, sans fusionner automatiquement les définitions |

Un résultat alreadyInstalled sans changement n'est pas transformé en plan applicable vide : le transfert retourne ce statut, les mappings existants et aucun nouveau reçu d'historique. Studio affiche le résultat sans bouton d'application inutile. Le replay du même operationId appliqué continue de retourner le reçu d'origine.

L'aperçu expose les nombres créés/réutilisés/copiés/non importables et les conflits résolus/non résolus. Aucun mode « remplacer » dans la v1.

Les dépendances et références sont remappées par champs typés. Interdire les remplacements textuels globaux dans du JSON.

Allocation déterministe v1 : packNamespace = les16 premiers hex du SHA-256 brut de CanonicalJson({packId, version, archiveRawSha256, copyOrdinal}). copyOrdinal vaut0 pour l'installation normale ; il est alloué sous la révision du plan pour une copie explicite. nativeResourceId = rp_ + packNamespace + _ + les24 premiers hex du SHA-256 brut de resourceKind + ":" + packLocalId. Vérifier les collisions réelles même avec ces hashes. Ces IDs restent compatibles avec les modèles3D, dont le format est plus strict que le simple identifiant du catalogue. Le mapping complet, y compris les supports et les groupes de connexion, est gelé et conservé dans le reçu d'installation.

Une ressource supprimée localement conserve son origine dans la trace d'installation. Le réimport de la même sélection ne la recrée pas. Une nouvelle racine nécessitant cette ressource rencontre un conflit de dépendance conservée/supprimée ; seule une copie de fermeture explicitement choisie peut la réintroduire sous une nouvelle identité.

Les mappings de la trace sont historiques : ils ne constituent pas des clés étrangères obligeant toutes les cibles à rester présentes. Le chemin alreadyInstalled consulte cette histoire sans reconstituer les ressources supprimées ni transformer leur absence en projet invalide.

### 3.4 Domaines de hash

- rawSha256 : hash brut des octets du fichier du pack.
- archiveRawSha256 : hash brut de l'archive intégrale.
- artifact.digest : empreinte authoring cadrée avec logicalName artifact-content.
- resourceRevision : empreinte authoring cadrée avec le storageKey natif.
- treeSha256 : hash de l'inventaire canonique selon la définition de format.

Ne jamais affecter rawSha256 à artifact.digest. Réutiliser NarrativeProjectFingerprintBuilder pour produire les mêmes empreintes cadrées par lecture en blocs ; tester l'égalité bit à bit avec les fonctions inline actuelles.

## 4. Gros volumes : bornes et architecture nécessaires

### 4.1 Politique ResourcePackSecurityPolicy v1

Ces chiffres sont des plafonds proposés et testables, pas des performances mesurées :

| Limite | Valeur |
|---|---|
| Archive | 512Mio |
| Somme des fichiers utiles | 500Mio ; l'archive STORE doit aussi rester sous512Mio |
| Entrées ZIP au total | 20000 |
| Fichiers logiques natifs publiés, sorties générées incluses | 20000 |
| Ressources logiques racines+dépendances | 10000 |
| Supports et motifs supplémentaires | 10000, soumis aussi au quota de JSON |
| manifest.json | 4Mio |
| catalog.json | 32Mio |
| Fichier individuel | 256Mio et limites de contenu natives si plus basses |
| Aperçus | 128Kio chacun,2048 fichiers maximum, inclus dans le volume total |
| Chunk I/O | 1Mio maximum |
| Page publique | 200 lignes ET256Kio encodés, premier plafond atteint |
| Patch de sélection explicite | 200 identités maximum par appel |
| Opération active | Une opération longue de pack par projet |
| Cache temporaire de session | 2Gio, admission refusée si les fichiers épinglés atteignent le plafond |
| Durée de vie sans référence | 24h ; jamais supprimer un stage retenu par plan/job/history/recovery |

Conserver les limites natives PNG/GLB, JSON profondeur/nœuds et hiérarchies. Le contrôle de taille d'image porte sur les pixels décodés ; éviter de décoder tous les aperçus ou tous les atlas au préalable.

L'admission calcule les octets temporaires, les copies logiques, le store, les stages transactionnels et l'historique. Si la mesure d'espace libre est disponible et insuffisante : refuser avant commit. Sinon afficher l'estimation sans inventer d'espace disponible ; une erreur d'espace réel doit rester récupérable.

### 4.2 Staging sur disque et snapshot

- Copier le fichier choisi vers un stage privé appartenant à la session ; contrôler taille, identité avant/après et hash pendant la copie.
- Les parseurs lisent ce snapshot stable par RandomAccessPackageSource.
- Les poignées ne contiennent aucun chemin et ne sont valables que dans leur portée/session.
- L'import peut libérer le stage original après application et vérification du reçu.
- Le cache de stages est hors des fichiers natifs publiés du projet.
- ProjectSnapshot conserve les métadonnées, tailles, empreintes et références vérifiées des gros binaires ; il ne retient plus tous leurs octets.
- Garder inline les documents JSON nécessaires au plan ; charger un binaire uniquement lorsqu'une opération a réellement besoin de son contenu.
- Préserver les vérifications de fichier changé, de lien sortant et d'empreinte : lazy ne signifie pas confiance sans contrôle.
- La réouverture normale du projet doit respecter ce mode borné ; un mode « import rapide » qui retombe en copie intégrale au premier refresh n'est pas accepté.

### 4.3 Payloads transactionnels

Créer AuthoringPayload avec deux formes actives : inline pour les petits documents, stored pour un fichier immuable détenu par le store privé.

~~~dart
sealed class AuthoringPayload {
  const AuthoringPayload();
  int get byteLength;
}

final class InlineAuthoringPayload extends AuthoringPayload {
  InlineAuthoringPayload(this.bytes);
  final List<int> bytes;
  @override
  int get byteLength => bytes.length;
}

final class StoredAuthoringPayload extends AuthoringPayload {
  const StoredAuthoringPayload({
    required this.handle,
    required this.byteLength,
    required this.rawSha256,
    required this.resourceRevision,
  });
  final String handle;
  @override
  final int byteLength;
  final String rawSha256;
  final String resourceRevision;
}
~~~

Les constructeurs réels vérifient l'immuabilité, les identités et les domaines d'empreinte. Les extraits définissent le contrat de types ; les invariants sont couverts par les tests du lotP05.

- AuthoringResourceChange porte beforePayload et afterPayload ; null signifie uniquement absence/suppression.
- Conserver le constructeur inline actuel comme construction d'une forme inline, pas comme un second moteur.
- Un accès inline à un stored payload échoue explicitement ; il ne retourne jamais null.
- Les consommateurs génériques utilisent présence/empreinte/stream, sans dépendre de beforeBytes/afterBytes.
- Les producteurs de petits changements restent inline ; ne pas réécrire toutes les actions métier sans nécessité.
- TransactionFileGateway stage, vérifie et promeut les payloads par flux ; aucune matérialisation de la fermeture binaire complète.
- History, undo, redo, revert et recovery retiennent/référencent les payloads sur disque.
- Préserver l'identité des reçus, l'idempotence, les préconditions CAS et les garanties de l'historique existant.

### 4.4 Journal bulk

Le mode normal conserve ses garanties et checkpoints actuels. Le mode bulk fiable est sélectionné en interne pour le pack :

1. intention immuable complète et ordonnée ;
2. checkpoints aux transitions preparing/staged/prepared/promoting/committed ;
3. petit sidecar de progression, non utilisé comme vérité de commit ;
4. après crash, comparer chaque fichier réel à ses empreintes before/after ;
5. sauter une promotion déjà appliquée ; refuser une troisième empreinte ;
6. aucune réécriture du tableau complet après chacun des milliers de fichiers.

La taille totale écrite pour les checkpoints de contrôle doit croître linéairement avec le nombre d'entrées. Les tests vérifient des compteurs d'I/O, pas un temps fragile.

Garantie publique : multiFileGuarantee=recoverable. Ne pas promettre une visibilité simultanée de tous les fichiers au niveau du système de fichiers.

### 4.5 Autorisation et payload public

- Garder1Mio/requête,500 ressources et60 opérations/minute pour les actions ordinaires.
- Définir une politique bulk interne limitée à resource_pack.import et aux undo/redo/revert d'une entrée d'historique certifiée comme issue de cette opération.
- Compter les sorties natives après remappage, y compris fichiers générés de bordures et licences : n≤20000 fichiers logiques, au plusn nouveaux blobs CAS, et au plus2 métadonnées (project.json et assets/.pokemap-assets.json). Plafond spécifique dérivé :2n+2, au maximum40002 ressources physiques touchées. Ces limites de sortie sont distinctes du quota d'entrées ZIP et sont calculées avant le plan.
- Le client ne transmet ni limite ni exemption. La politique doit refuser l'usurpation par actionId, extension JSON ou faux reçu d'historique.
- Les permissions, racines autorisées, révisions et confirmations applicables restent celles du moteur canonique.
- Conserver le diff interne complet : CAS, journal et historique en dépendent.
- Exposer une projection compacte avec planId, compteurs, empreinte du diff et références paginées. Ne pas tronquer le diff interne pour réduire les réponses.
- La projection compacte s'applique à l'API de transfert, JSONL et MCP, pas seulement au widget.

## 5. API canonique, jobs et transports

Réutiliser AuthoringJobRequest/Snapshot/Event/Cancellation et AuthoringJobPort. Ajouter un exécuteur spécialisé ResourcePackJobService ; aucune plateforme de jobs pour les autres domaines.

Kinds proposés : resource_pack.stage, resource_pack.inspect, resource_pack.prepare, resource_pack.import, resource_pack.export, resource_pack.undo, resource_pack.redo, resource_pack.revert et resource_pack.recover.

| Opération de transfert | Entrée bornée | Sortie |
|---|---|---|
| stage | sourcePath uniquement à la frontière locale autorisée | jobId ; à terme archiveHandle |
| inspect | archiveHandle | jobId ; à terme inspectionHandle et compteurs |
| entries | inspectionHandle, filtre, cursor | Page de définitions résumées |
| selection.create | inspectionHandle | selectionHandle et révision de sélection |
| selection.patch | selectionHandle, révision, ≤200 refs à ajouter/retirer | Nouvelle révision et compteurs |
| selection.select_filtered | selectionHandle, révision, filtre fixé | Sélection calculée côté serveur, aucun tableau géant sur le transport |
| prepare | selectionHandle, révision de sélection, expectedRevision, conflictPolicy | jobId ; à terme preparedImportHandle et preview paginée |
| plan | action canonique resource_pack.import + preparedImportHandle | planId, résumé, diffRef et préconditions |
| start_apply | planId, operationId, token si requis | jobId ; à terme reçu canonique |
| start_history | verb undo/redo/revert, identité historique vérifiée, révision, operationId | jobId ; à terme reçu canonique ; refus d'une fausse origine bulk |
| start_recovery | identité de transaction canonique et projet | jobId ; à terme état récupéré et reçu durable |
| export | selectionHandle source, expectedRevision, métadonnées du pack | jobId ; à terme artifactHandle, hash et compteurs |
| get / events | jobId, afterSequence, cursor | État court et événements paginés |
| read_payload | payloadRef autorisé, offset, longueur≤128Kio | Chunk borné, longueur totale, hash ; jamais de chemin filesystem |
| cancel | jobId | Annulation confirmée ou phase de finalisation non annulable |
| release | archive/inspection/selection/prepared handle | Libération de référence, jamais suppression d'un stage épinglé |

start_apply appelle la même API canonique d'application et la même politique de sécurité ; il ne réimplémente pas une transaction dans le worker.

Les undo/redo/revert et récupérations de ce bulk utilisent eux aussi le chemin job. Ils ne doivent pas repasser par une commande synchrone de10secondes qui continuerait à écrire après timeout. Le service résout l'origine depuis l'historique/journal canonique et appelle les mêmes exécuteurs ; aucun drapeau client ne transforme une opération arbitraire en bulk. La réouverture d'un projet avec transaction bulk en attente déclenche/attend la récupération canonique avant de le rendre éditable, avec suivi de phase plutôt qu'un chargement bloqué sans statut.

- Ajouter ResourcePackTransferApiPort et son implémentation locale dans map_authoring.
- Ajouter un canal JSONL resource_pack avec verb strict ; start retourne après enregistrement, avant le travail.
- Les opérations CPU synchrones se font dans un isolate ; les I/O longues rendent la main entre chunks. Les polls ne doivent pas attendre derrière une lecture intégrale.
- Exposer un outil MCP de transfert pokemap_resource_pack, avec verbs stricts, en complément de pokemap_plan pour l'action enregistrée.
- Déclarer les jobs, inspections et previews comme ressources découvrables/queryables. Les URI retournées sont opaques et issues du serveur.
- Resource kinds de transfert proposés : resourcePackJob, resourcePackInspection, resourcePackEntry, resourcePackSelection et resourcePackPreview. Chaque requête vérifie propriétaire de session/projet, handle et révision ; ne pas exposer une liste globale de stages d'autres projets.
- Ajouter les capacités, schémas et preuves de parité dans les registres canoniques et la documentation existante.
- Garder le staging générique courant pour les petits artefacts ; le staging spécialisé pack utilise le nouveau chemin disque et ne relève pas son plafond256Mio.
- Les API de statut paginent leurs événements ; aucune réponse ne contient tous les PNG, le catalogue complet ou le diff complet.
- Une fermeture/reconnexion ne doit jamais déclencher une seconde installation : réconciliation par operationId et reçu durable.

### États et annulation

| Phase | Projet natif modifié ? | Annulation |
|---|---|---|
| staging / inspection / sélection | Non | Immédiate ou coopérative, nettoyage des stages non retenus |
| préparation / vérification / staging transactionnel | Non, hors espace interne de transaction | Possible avant réservation durable |
| prepared / promoting | Des fichiers peuvent être promus | « Finalisation en cours » ; ne pas tuer le traitement pour simuler une annulation |
| committed / refresh | Oui | Présenter le reçu ; une erreur de refresh ne signifie pas échec de l'import |
| erreur avec journal incomplet | À réconcilier | Reprise/récupération canonique ; pas de message « projet inchangé » sans preuve |

Ne pas ajouter pause/reprise utilisateur aux phases qui ne sont pas réellement reprenables. Le contrat de jobs expose une reprise seulement lorsque le service a une intention/stage certifiés.

AuthoringJobCancellation reste réservé aux annulations acceptées dans les états cancelling/cancelled. Une demande après réservation retourne l'erreur stable resource_pack.cancel_not_allowed avec jobId, phase et cancelAllowed=false ; elle ne change pas un job running en cancelled. La décision d'annulation et le franchissement de la réservation sont sérialisés : le moteur ne peut pas confirmer une annulation puis engager la publication.

## 6. Parcours Studio

### Import

1. Depuis Ressources, choisir « Importer un pack… » ; bouton disponible dans la bibliothèque globale et le menu compact Actions.
2. Picker natif .aveluneassets. Annuler ferme sans erreur.
3. Stage et inspection avec phase/compteurs réels.
4. Résumé nom/version/auteur/univers/capacités, sources et taille ; validation avant modification.
5. Sélection virtualisée des racines, recherche/familles/contextes, motifs explicites ; filtrer ne désélectionne pas les lignes masquées.
6. Dépendances incluses automatiquement, indiquées avec la racine qui les réclame.
7. Préparation des conflits, politique preserveProject par défaut ; importCopy explicite si nécessaire.
8. Résumé avant « Importer la sélection » : racines, dépendances, nouvelles définitions, octets, déjà installées et copies.
9. Application et progression. Busy partagé avec les sauvegardes/imports de ressources ; ne pas mélanger les révisions de la session.
10. Résultat distinguant ajoutées/déjà installées/modifications locales conservées.
11. « Voir les ressources importées » révèle les identités natives ajoutées ; ne pas imposer durablement un filtre.
12. Si commit réussi puis refresh échoué, afficher « Import terminé — relire la bibliothèque » et réconcilier le reçu.

### Export

1. « Exporter un pack… » depuis Ressources, avec sélection indépendante du pinceau de carte.
2. Choisir racines et motifs ; inclure la fermeture, montrer les ressources non portables et les normalisations d'organisation.
3. Saisir nom/version/auteur/universeId/provenance et sélectionner les licences.
4. Vérifier publication native, dimensions, dépendances et fichier manquant.
5. Construire sur disque en lecture cohérente de la révision source.
6. Réinspecter l'archive produite et comparer l'inventaire à la sélection.
7. Picker de destination ; confirmer le remplacement d'un fichier existant.
8. Copier vers un fichier temporaire frère, flush, puis rename. En cas d'échec, préserver l'ancien fichier.
9. Retourner chemin, archiveRawSha256, racines et dépendances. Aucun changement du projet source.

Primitives imposées : StudioSelect, StudioFilterTag, StudioBadge, StudioPanel, StudioButton, grilles/listes virtualisées existantes. Pas de nouvelles couleurs ad hoc ou de navigation principale.

Valeurs initiales : Contexte=Tous dans la bibliothèque, les palettes et le parcours de transfert ; aucune présélection depuis MapRole/isIndoor. La sélection export parcourt toutes les ressources natives du projet, indépendamment du filtre de compatibilité de la carte active ; une bibliothèque mixte peut donc être exportée sans masquer ses sources. La compatibilité de la destination s'applique à l'import.

Si une racine sélectionnée possède un brouillon divergent : afficher « Le pack utilise la version publiée ; vos modifications en cours ne sont pas incluses », lister les ressources concernées et proposer retour à l'atelier ou annulation. Ne pas enregistrer/publier automatiquement le brouillon.

## 7. Carte des fichiers et responsabilités

Les chemins ci-dessous sont relatifs au dépôt. Les fichiers nouveaux ne sont pas à créer avant leur lot.

| Fichier nouveau | Responsabilité |
|---|---|
| packages/map_core/lib/src/models/resource_pack.dart | Références typées, manifeste/catalogue portables, classification et supports |
| packages/map_core/lib/src/models/resource_pack_installation_catalog.dart | Origine et mappings persistés dans le projet |
| packages/map_core/lib/src/operations/resource_pack_dependency_graph.dart | Fermeture, cycles et ordre déterministe, sans I/O |
| packages/map_distribution/lib/src/resource_pack_security_policy.dart | Plafonds et codes de refus du format |
| packages/map_distribution/lib/src/resource_pack_manifest_codec.dart | JSON strict et canonique du manifeste/catalogue |
| packages/map_distribution/lib/src/resource_pack_inspector.dart | Inspection random-access, inventaire et contenus vérifiés |
| packages/map_distribution/lib/src/resource_pack_builder.dart | Production déterministe vers sink et réinspection |
| packages/map_authoring/lib/src/ports/file_backed_payload_store.dart | Handles privés, épinglage, streams et durée de vie |
| packages/map_authoring/lib/src/transactions/authoring_payload.dart | Variantes inline/stored et présence explicite |
| packages/map_authoring/lib/src/domains/assets/resource_pack_projection.dart | Extraction native portable, supports et remappage inverse |
| packages/map_authoring/lib/src/domains/assets/resource_pack_import_preparer.dart | Résolution de sélection, conflits, mappings et change set |
| packages/map_authoring/lib/src/domains/assets/resource_pack_actions.dart | Descriptor/mutation canonique resource_pack.import |
| packages/map_authoring/lib/src/api/resource_pack_transfer_api.dart | Port et DTO de sélection/préparation/transfert paginé |
| packages/map_authoring/lib/src/application/resource_pack_job_service.dart | Jobs spécialisés, progression et réconciliation |
| packages/map_authoring/lib/src/infrastructure/local_resource_pack_store.dart | Stage disque et adaptateurs source/sink privés |
| apps/avelune_studio/lib/features/resources/domain/resource_pack_port.dart | Port Studio consommant les DTO canoniques |
| apps/avelune_studio/lib/features/resources/application/resource_pack_transfer_controller.dart | État de sélection et parcours import/export |
| apps/avelune_studio/lib/features/resources/data/local_resource_pack_adapter.dart | Appels canoniques, session, reçus et réconciliation |
| apps/avelune_studio/lib/platform/files/native_resource_pack_picker.dart | Pickers import/export injectables |
| apps/avelune_studio/lib/presentation/features/resources/resource_pack_transfer_dialog.dart | Étapes du parcours et messages |
| apps/avelune_studio/lib/presentation/features/resources/resource_pack_selection.dart | Présentation virtualisée de la sélection et des dépendances |
| tools/pokemap_mcp/src/tools/resource_packs.ts | Adaptation stricte du canal canonique de transfert |

Les tables de lots listent les fichiers existants à modifier. Préserver les barrels publics map_core.dart/map_core_domain.dart, map_distribution.dart, map_authoring_api.dart/map_authoring_local.dart et, si nécessaire, le barrel large utilisé par les consommateurs actuels.

Ne pas créer un fichier par petit helper. Les responsabilités ci-dessus peuvent être regroupées si elles restent lisibles, mais aucune couche ne dépend des contrôleurs/widgets Studio.

## 8. Ordre des lots et gates

| Lot | Livrable | Dépendances | Gate |
|---|---|---|---|
| P01 | Contexte natif et API | Audit courant | Persistance, clear, batch, duplication |
| P02 | Classement/filtres Studio complets | P01 | Tous les types/vues/palettes |
| P03 | Contrat de pack et graphe portable | P01 | Sept kinds et supports validés |
| P04 | Stage disque et inspection | P03 | Archives invalides refusées sans écriture |
| P05 | Payloads/snapshot/historique bornés | P03 | Aucun chargement intégral de collection binaire |
| P06 | Journal bulk, autorisation et projection compacte | P05 | Crash/recovery/undo et quotas |
| P07 | Extraction/remappage/export | P03,P04,P05 | Export déterministe, source inchangée |
| P08 | Préparation/import additif | P03–P07 | Références intactes, réimport idempotent |
| P09 | Jobs et transports | P04–P08 | API/JSONL/MCP et annulation honnête |
| P10 | Installation dans Studio | P02,P08,P09 | Vrai parcours fichier → bibliothèque |
| P11 | Export dans Studio | P07,P09,P10 | ProjetA → pack → projetB |
| P12 | Qualification 2D/3D et gros volumes | P01–P11 | Fonctionnel, reprise et mesures locales |
| P13 | Production des cinq bibliothèques | P12 | Qualification séparée de chaque collection |
| P14 | Revue finale et livraison | P01–P12 pour le système ; P13 pour chaque collection livrée | TO REVIEW avec preuves, décision DONE humaine |

P01/P02 sont livrables séparément. P03/P04 peuvent avancer pendant P02. Les modifications de transactions de P05/P06 restent séquentielles, relues avant l'import produit. Ne pas déclarer « import massif livré » avant P12.

## 9. Tâches exécutables par lot

Chaque case correspond à une action vérifiable. Un résultat attendu décrit un futur test, jamais une preuve déjà obtenue. Les commandes partent du package indiqué. Aucun checkpoint de ce plan n'autorise une opération Git d'écriture.

### P01 — Contexte commun, codec et classification

**Modifier :**

- packages/map_core/lib/src/models/resource_library_catalog.dart
- packages/map_authoring/lib/src/domains/assets/resource_library_actions.dart
- packages/map_authoring/lib/src/references/resource_library_scope_guard.dart
- packages/map_authoring/lib/src/domains/assets/tileset_actions.dart, uniquement si le descriptor doit porter une version/schema propre aux deux actions modifiées
- packages/map_authoring/lib/src/workspace/project_query_service.dart, projection du nouveau champ par le codec
- packages/map_authoring/lib/src/registry/resource_kind_registry.dart
- pokemap_authoring_api_mcp_action_catalog.md

**Étendre :**

- packages/map_core/test/resource_library_catalog_test.dart
- packages/map_authoring/test/domains/assets/resource_library_actions_test.dart
- packages/map_authoring/test/tooling/jsonl_resource_library_flow_test.dart
- packages/map_authoring/test/domains/distribution/resource_library_export_test.dart
- tools/pokemap_mcp/test/resource_library_stdio.test.ts

- [x] Ajouter le test modèle suivant avant le champ, puis vérifier son échec à la compilation.

~~~dart
void main() {
  test('context-only entry roundtrips independently from scope', () {
    final entry = ResourceLibraryEntry(
      resourceKind: 'element',
      resourceId: 'chair',
      placementContext: ResourcePlacementContext.interior,
    );
    final catalog = ResourceLibraryCatalog(entries: [entry]);
    expect(ResourceLibraryCatalog.fromJson(catalog.toJson()), catalog);
    expect(catalog.availableForMap('element', 'chair', 'outside'), isTrue);
  });
}
~~~

- [x] Ajouter le champ, le codec strict et la version2 ; adapter les fixtures de versions négatives pour qu'elles continuent à atteindre la validation qu'elles visent.
- [x] Ajouter les cas interior/exterior/both/null/absent/valeur invalide aux deux actions et au schéma partagé ; inclure null dans l'enum JSON autorisée.
- [x] Modifier la conservation des entrées neutres et l'héritage de duplication ; vérifier qu'un patch de famille/rôle ne perd pas le contexte.
- [x] Tester deux kinds portant le même id brut, un batch dont la dernière entrée est invalide, une révision périmée, undo et réouverture.
- [x] Tester que le contexte différent de celui de la carte ne change ni la disponibilité ni la projection d'export.
- [x] Documenter le format v2 et les lecteurs affectés ; ne pas incrémenter toutes les actions visuelles au moyen d'un helper global.
- [x] Exécuter :

~~~bash
cd packages/map_core
dart test test/resource_library_catalog_test.dart
dart analyze
cd ../map_authoring
dart test test/domains/assets/resource_library_actions_test.dart test/tooling/jsonl_resource_library_flow_test.dart test/domains/distribution/resource_library_export_test.dart
dart analyze
cd ../../tools/pokemap_mcp
npm run check
npm run build
node --import tsx --test test/resource_library_stdio.test.ts
~~~

**Gate :** tous ces cas réussissent ; un descriptor live expose le champ, son enum et la sémantique de clear. Une simple persistance JSON ne ferme pas ce lot.

### P02 — Studio, filtres et toutes les surfaces

**Modifier sous apps/avelune_studio/lib/presentation/features/resources :**

- resource_catalog.dart : état, copy/copyFrom/reset/reveal, lecture et prédicat ;
- resource_library_bindings.dart : sélecteur dans Ranger et paramètres canoniques ;
- resource_filter_button.dart : brouillon/Apply/Cancel/Reset, compteur et tag amovible ;
- resource_catalog_view.dart et resource_detail_panel.dart : libellé du contexte ;
- resource_family_tree.dart : compteurs cohérents avec le filtre actif ;
- resource_library_layout.dart : passage du filtre aux trois ateliers spécialisés ;
- model_resource_library.dart, environment_library.dart, resource_border_draft_bar.dart : filtrage avant sélection et comptage ;
- resource_source_list.dart et environment_decor_picker.dart : réutilisation du prédicat, sans seconde implémentation de la règle.

**Modifier sous presentation/features/map_workspace :**

- map_workspace_view_state.dart : filtres de palette et disponibilité neutre du pinceau ;
- map_workspace_palette_dock_filters.dart : contrôle commun s'il n'est pas déjà transmis ;
- map_border_tool_panel.dart et map_environment_tool_panel.dart : contexte explicite dans les sélecteurs secondaires.

**Étendre les tests Studio :**

- test/presentation/resource_family_catalog_test.dart
- test/presentation/resource_family_widgets_test.dart
- test/resource_io/resource_library_host_test.dart
- test/presentation/map_workspace_palette_dock_filters_test.dart
- test/presentation/map_workspace_resource_families_test.dart

**Créer :** test/presentation/resource_context_specialized_libraries_test.dart.

- [x] Écrire la matrice de filtrage ci-dessous dans les tests de catalogue.

| Contexte de ressource | Tous | Intérieur | Extérieur | Non renseigné |
|---|---|---|---|---|
| absent | Oui | Non | Non | Oui |
| interior | Oui | Oui | Non | Non |
| exterior | Oui | Non | Oui | Non |
| both | Oui | Oui | Oui | Non |

- [x] Vérifier l'intersection avec recherche, famille descendante, composants, portée et dimension.
- [x] Ajouter le sélecteur d'édition et le filtre en réutilisant les primitives Studio ; tester le défaut Tous et l'absence d'inférence depuis la carte.
- [x] Tester chaque transition Apply/Cancel/Reset/suppression du tag/reveal ; un filtre annulé ne modifie pas l'état courant.
- [x] Ajouter un test positif pour chacune des trois bibliothèques spécialisées et les deux sélecteurs secondaires.
- [x] Vérifier qu'un filtre cache la carte de ressource sans retirer le pinceau déjà choisi et sans toucher aux instances.
- [x] Tester petit écran, grands textes et navigation clavier.
- [x] Exécuter :

~~~bash
cd apps/avelune_studio
flutter test --no-pub test/presentation/resource_family_catalog_test.dart test/presentation/resource_family_widgets_test.dart test/resource_io/resource_library_host_test.dart test/presentation/map_workspace_palette_dock_filters_test.dart test/presentation/map_workspace_resource_families_test.dart test/presentation/resource_context_specialized_libraries_test.dart
flutter analyze --no-pub
~~~

**Gate :** modification de contexte puis sauvegarde/réouverture visible pour les sept kinds, filtre cohérent sur toutes les surfaces et aucune contrainte nouvelle de placement.

### P03 — Modèles portables et fermeture typée

**Créer :**

- packages/map_core/lib/src/models/resource_pack.dart
- packages/map_core/lib/src/models/resource_pack_catalog.dart
- packages/map_core/lib/src/models/resource_pack_installation_catalog.dart
- packages/map_core/lib/src/operations/resource_pack_dependency_graph.dart
- packages/map_core/lib/src/operations/resource_pack_native_json.dart
- packages/map_core/lib/src/operations/resource_pack_publication.dart
- packages/map_core/test/resource_pack_contract_test.dart
- packages/map_core/test/resource_pack_installation_catalog_test.dart
- packages/map_core/test/resource_pack_dependency_graph_test.dart
- packages/map_core/test/resource_pack_publication_test.dart

**Modifier :** project_manifest.dart, ses sorties générées et les barrels core.

- [x] Implémenter les DTO stricts de la section2, sans dépendance archive, File ou Flutter dans core.
- [x] Fixer dans compatibility les versions natives exactes utilisées : Smart Tile7 et Border10 observées pendant l'audit, ResourceLibrary2 ; relire les constantes avant implémentation.
- [x] Définir précisément les sections du sous-catalogue : tilesets/elements/models3d/characters/environmentPresets, smartTileCatalog, borderCatalog, resourceLibraryCatalog, elementCategories/tilesetFolders/characterStudioCatalog et extras de motifs.
- [x] Rejeter toute section maps/groups/presentation/dialogues/events ou réglages de projet.
- [x] Construire un graphe de références sortantes avec ressource, support et fichier ; distinguer groupe local à un propriétaire et ID global.
- [x] Tester fermeture stable, dépendance partagée une fois, dépendance manquante par kind, parents de catégories, cycles interdits et énumération des motifs explicitement sélectionnés.
- [x] Tester un material.connectionGroupId identique dans deux packs : aucun raccord inter-pack après remappage.
- [x] Pour une bordure publiée, produire une projection portable de l'état publié et les supports nécessaires ; à l'import, reconstruire le draft natif éditable depuis cet état. Ne pas exporter le brouillon utilisateur divergent. Vérifier que les sources éditables donnent exactement les snapshots publiés ; sinon refuser cette racine dans la v1 avec diagnostic border.source_publication_mismatch.
- [x] Pour Smart Tiles, reconstruire au besoin le brouillon d'édition depuis le preset publié via le chemin canonique ; vérifier qu'il peut être édité/réenregistré. Aucun brouillon source privé n'est importé par simple copie de catalogue.
- [x] Persister ResourcePackInstallationCatalog dans le manifeste et tester absence/roundtrip/identité d'installation.
- [x] Régénérer et tester uniquement core :

~~~bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/resource_pack_contract_test.dart test/resource_pack_installation_catalog_test.dart test/resource_pack_dependency_graph_test.dart
dart analyze
~~~

**Gate :** chaque référence est expliquée par un visiteur typé et par un test ; aucune dépendance à un projet source implicite.

### P04 — Stage possédé, inspection et quotas

**Créer :**

- packages/map_distribution/lib/src/resource_pack_security_policy.dart
- packages/map_distribution/lib/src/resource_pack_manifest_codec.dart
- packages/map_distribution/lib/src/resource_pack_inspector.dart
- packages/map_distribution/lib/src/static_png_validation.dart
- packages/map_distribution/test/static_png_validation_test.dart
- packages/map_authoring/lib/src/ports/file_backed_payload_store.dart
- packages/map_authoring/lib/src/infrastructure/local_resource_pack_store.dart
- packages/map_distribution/test/resource_pack_inspector_test.dart
- packages/map_distribution/test/resource_pack_manifest_codec_test.dart
- packages/map_authoring/test/ports/file_backed_payload_store_test.dart

**Modifier :** random_access_zip_structure_reader.dart pour un validateur spécifique si nécessaire, glb_model3d_inspector.dart pour le profil explicite de textures statiques du pack, sans changer les profils existants des jeux ; barrels concernés.

- [x] Tester le stage d'une source sélectionnée, son lease, sa libération et son expiration ; une source modifiée pendant la copie est refusée.
- [x] Tester les racines autorisées et les liens sortants ; la sélection native peut autoriser ce fichier exact, sans ouvrir le dossier utilisateur entier.
- [x] Copier et hasher par chunks ; conserver le snapshot dans un cache privé avec budget total.
- [x] Inspecter structure et bornes avant lecture du catalogue ou décodage de médias.
- [x] Contrôler les versions/capacités, JSON strict, fichiers manquants et supplémentaires, SHA bruts, tailles, MIME et chemins.
- [x] Refuser glTF externe, URL de texture, archive compressée, ZIP64, symlink, doublon normalisé/casefold, traversée, section native interdite et référence structurée de sémantique inconnue.
- [x] Recalculer l'inspection GLB ; ne pas croire celle annoncée dans un JSON.
- [x] Tester les références de licence et le décodage UTF-8 des documents de provenance ; aucun téléchargement automatique.
- [x] Tester chaque quota à sa borne et à borne+1 avec sources virtuelles ; ne pas committer une archive de512Mio.
- [x] Exécuter :

~~~bash
cd packages/map_distribution
dart test test/resource_pack_manifest_codec_test.dart test/resource_pack_inspector_test.dart test/presentation_preset_pack_codec_test.dart
dart analyze
cd ../map_authoring
dart test test/ports/file_backed_payload_store_test.dart test/ports/artifact_staging_lifetime_test.dart test/tooling/jsonl_artifact_staging_test.dart
dart analyze
~~~

**Gate :** inspecter n'écrit aucun fichier natif du projet ; les fichiers temporaires appartiennent à une session et sont libérés sans toucher aux stages retenus.

### P05 — Payloads, historique et snapshot à mémoire bornée

**Créer :** transactions/authoring_payload.dart et les tests :

- packages/map_authoring/test/transactions/file_backed_payload_test.dart
- packages/map_authoring/test/workspace/lazy_asset_snapshot_test.dart
- packages/map_authoring/test/history/file_backed_history_test.dart

**Modifier dans map_authoring :**

- transactions/change_set.dart, batch_executor.dart ;
- transactions/plan_store.dart : expiration/discard et libération des leases possédés ;
- ports/transaction_file_gateway.dart et transactions/local_transaction_file_gateway.dart ;
- transactions/journaled_transaction.dart, recovery_service.dart ;
- history/history_store.dart, content_blob_store.dart, undo_service.dart, revision_revert_service.dart ;
- security/secure_mutation_executor.dart ;
- api/local_map_authoring_mutation_api.dart : binding des snapshots, refresh après commit, adoption et libération des leases même après échec de relecture ;
- workspace/project_snapshot.dart, project_snapshot_loader.dart, project_snapshot_cache.dart, project_snapshot_map_projector.dart ;
- ports/project_file_reader.dart et workspace/workspace_handle_store.dart : lecture par flux et descripteurs vérifiés transmis par le port, sans ouverture directe de chemins depuis le loader ;
- references/resource_library_scope_guard.dart, uniquement ses accès génériques aux changements ;
- support/authoring_fingerprint.dart, si un helper stream commun est nécessaire.
- domains/assets/resource_source_guards.dart, element_definition_management.dart et model3d_actions.dart, ainsi que domains/maps/smart_tile_catalog_actions.dart : consommateurs binaires chargés ponctuellement par le port autorisé ; préserver les modifications étrangères de ces fichiers.
- domains/assets/asset_actions.dart, tiled_tileset_import_projection.dart, presentation_media_import_actions.dart et presentation_preset_actions.dart ; domains/maps/tiled_map_import_actions.dart ; domains/gameplay/pokemon_media_import_actions.dart et character_studio/character_studio_deletion_safety.dart ; domains/narrative/presentation_publication_snapshot.dart : préserver les références binaires dans les projections, distinguer présence et disponibilité inline, lire seulement le média nécessaire.

**Audit préalable d'exécution :** le recorder doit rendre les blobs d'historique durables avant le nettoyage des stages de transaction. Les leases du cache P04, même nommés history ou recovery, ne sont pas reconstructibles après fermeture du service : l'historique garde son CAS indépendant sous `.pokemap/authoring/blobs`, alimenté et vérifié par flux. Les domaines d'empreinte restent distincts : SHA brut du fichier, digest d'artefact cadré `artifact-content`, révision cadrée par `storageKey`, blob d'historique cadré `authoring-history-blob`. Une référence de snapshot partagée ne capture jamais le premier handle de workspace ; elle est résolue avec l'accès autorisé courant ou un cache privé immuable. La seconde observation forte des sources reste nécessaire, y compris pour les alias CAS désormais lazy. L'adoption du snapshot après commit doit préserver le reçu déjà durable et nettoyer les références possédées si le refresh échoue. Le test `retained_dependency_window_test.dart` ne constitue pas une garantie de verrouillage des écrivains externes.

**Décisions de contrat P05 :** les payloads inline et stored sont deux variantes actives, sans lecteur de format ancien. `null` signifie absence ; un getter inline appelé sur un stored lève une erreur explicite. La fabrique stored vérifie taille, hash brut et révision cadrée par clé avant de construire une capacité associée non sérialisable ; les propriétaires du plan gèrent les leases séparément. Les snapshots partagés conservent des descriptors de sources natives et capturent sur disque les seuls préétats touchés. Undo copie les cibles historiques par flux vers le stage du plan, sans introduire de pins dans le CAS historique. Expiration, discard et détachement attendent leur nettoyage.

Après reçu durable, une relecture indisponible produit `AuthoringMutationResult.snapshotRevision: null` et un diagnostic explicite sans chemin `snapshot.refresh_unavailable`, avec instruction de relire sans rejouer la mutation. Aucune révision touched, périmée ou de plan ne remplace une observation inconnue. Plan/query gardent leurs révisions obligatoires. Le pont `map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` et ses consommateurs de révision d'application doivent transmettre cette distinction ; une projection réussie conserve sa révision réelle non nullable. Adapter uniquement les retours d'application et les contrôles de réconciliation concernés dans les services Smart Tiles, imports Tiled, connexions et adoption de snapshot de l'éditeur. Une comparaison `projection?.snapshotRevision == expectedSnapshotRevision` ne doit jamais autoriser le cas null/null. Le writer converter vérifie son propre snapshot frais et compare avec la révision d'application seulement lorsqu'elle existe ; préserver ses hunks étrangers. Les échecs avant commit, du recorder ou d'audit sécurisé ne sont pas absorbés par le catch de relecture.

- [ ] Écrire un test montrant qu'un payload stored présent est reconnu comme présent, y compris dans le calcul destructif.
- [ ] Ajouter les deux variantes et les leases ; les handles ne sont jamais résolus depuis un chemin fourni par le client. Les références du snapshot partagé survivent au rebind de nouveaux handles, sans dépendre d'une session expirée. Les empreintes resourceRevision restent cadrées par chaque storageKey ; un blob CAS et son alias logique partagent des octets, pas une révision de ressource.
- [ ] Implémenter stage/verify/promotion/hash par chunks ; même empreinte que la fonction inline pour0,1,1Mio et plusieurs chunks. Remplacer aussi les relectures intégrales dans readResourceRevision et lors de la vérification du temporaire avant promote ; un stage stream suivi d'un contrôle CAS intégral ne satisfait pas la borne mémoire.
- [ ] Garder les petits JSON inline ; adapter les consommateurs génériques à présence/empreinte/flux.
- [ ] Adapter le recorder et le blob store d'historique, y compris contains ; aucun chargement intégral caché via get.
- [ ] Adapter undo/redo/revert et recovery : reconstruction d'une liste de références, pas de tous les octets.
- [ ] Adapter le snapshot courant, ses projections et son cache pour les médias managés ; mêmes fingerprints cold/warm et mêmes refus de corruption. Le binding _requireRootMatchesSnapshot vérifie également par flux, sans exiger snapshot.resourceBytes des médias stockés. Un refresh après commit conserve le reçu durable et libère les références possédées sans annoncer un faux échec de publication. Régressions : duplication décor, validation atlas, remplacement/suppression modèle, nouvelle session et publication Presentation après chargement lazy.
- [ ] Vérifier que l'ouverture après import ne remplit pas resourceByteLength de toute la bibliothèque binaire.
- [ ] Tester lease expiré/corrompu, fichier externe modifié, stage supprimé, fichier logique et historique indépendants ; ne pas utiliser de hardlink vers un média modifiable.
- [ ] Contrôler tous les consommateurs de beforeBytes/afterBytes et resourceBytes par recherche ; les producteurs inline n'ont pas à changer si leurs contrats restent valides. Couvrir requireResourceSourceBytes, duplication de décor, _atlasImageState et les projections de suppression/remplacement model3d qui clonent les sources. Un accès stored ne doit jamais retourner null en prétendant que le média n'existe pas.
- [ ] Exécuter :

~~~bash
cd packages/map_authoring
dart test test/transactions/file_backed_payload_test.dart test/workspace/lazy_asset_snapshot_test.dart test/history/file_backed_history_test.dart test/transactions/crash_boundary_test.dart test/transactions/recovery_idempotence_test.dart test/transactions/retained_dependency_window_test.dart test/history/undo_redo_contract_test.dart test/history/history_retention_test.dart
dart analyze
~~~

**Gate :** mêmes révisions et garanties pour inline/stored ; cold open, apply et undo d'une collection volumineuse ne retiennent pas tous ses binaires en mémoire. Cette évolution de l'infrastructure est relue avantP06.

### P06 — Journal bulk, sécurité et réponses compactes

**Modifier :**

- packages/map_authoring/lib/src/transactions/transaction_journal.dart
- packages/map_authoring/lib/src/transactions/journaled_transaction.dart
- packages/map_authoring/lib/src/transactions/recovery_service.dart
- packages/map_authoring/lib/src/security/authorization_policy.dart
- packages/map_authoring/lib/src/security/secure_mutation_executor.dart
- packages/map_authoring/lib/src/api/authoring_mutation_contracts.dart
- packages/map_authoring/lib/src/transactions/authoring_plan.dart
- packages/map_authoring/lib/src/history/undo_service.dart
- packages/map_authoring/lib/src/history/authoring_history.dart et revision_revert_service.dart : origine bulk durable canonique et résolution des entrées d'historique strictes.

**Créer :**

- packages/map_authoring/test/transactions/bulk_transaction_checkpoint_test.dart
- packages/map_authoring/test/security/resource_pack_bulk_authorization_test.dart
- packages/map_authoring/test/api/resource_pack_compact_result_test.dart

- [ ] Ajouter un mode de checkpoint interne phaseOnly ; le client ne choisit pas ce mode dans les paramètres.
- [ ] Conserver l'intention complète et le reçu complet ; progression séparée et bornée.
- [ ] Injecter un crash avant/après promotion d'un fichier mais avant checkpoint ; recovery reconnaît before/after et ne duplique pas les changements.
- [ ] Tester les compteurs de journal pour100/1000/10000 changements sur apply, resume et compensate ; aucune boucle de réécriture complète par fichier, y compris _checkpointEntry lors de recovery.
- [ ] Ajouter la politique bulk d'action/version ; vérifier n≤20000 sorties logiques, blobs≤n, métadonnées≤2 et touched≤2n+2≤40002 ; le quota ZIP reste indépendant.
- [ ] Tester l'absence d'exemption pour toute action ordinaire, faux champ client, faux actionId et fausse origine d'historique.
- [ ] Appliquer le même budget uniquement aux undo/redo/revert d'un import certifié ; historique ordinaire toujours limité normalement. Tester import>500changements → undo → redo → reconstruction du service → recovery.
- [ ] Projeter plan/résultat/reçu vers des résumés et références paginées ; garder la vérité interne intégrale. AuthoringMutationHistoryResult.toJson et une page d'une seule entrée bulk sont soumis au même plafond. Les codecs AuthoringReceipt/journal et le hash des tokens de confirmation continuent à vérifier le diff intégral, jamais une projection compacte.
- [ ] Tester que chaque réponse de page reste≤256Kio et que la reconstruction des pages et des payloadRefs retrouve exactement le diff interne, sans répétition/perte. Une entrée dont before/after est un catalogue32Mio est projetée en descriptor payloadRef/rawSha256/resourceRevision/byteLength, jamais inline. Le contenu reste téléchargeable par chunks autorisés ; aucun curseur vide infini quand une seule ligne dépasse le quota.
- [ ] Exécuter :

~~~bash
cd packages/map_authoring
dart test test/transactions/bulk_transaction_checkpoint_test.dart test/security/resource_pack_bulk_authorization_test.dart test/api/resource_pack_compact_result_test.dart test/security/authorization_policy_test.dart test/transactions/idempotency_contract_test.dart test/history/undo_redo_contract_test.dart
dart analyze
~~~

**Gate :** import et annulation historique volumineux restent autorisés dans leur portée vérifiée ; aucune action étrangère ne gagne un budget supérieur.

**Audit préparatoire P06 :** les réécritures quadratiques sont présentes dans journaled_transaction et dans _checkpointEntry de recovery, même lorsqu'une révision est déjà after/before. Les deux chemins doivent utiliser le profil phaseOnly sans reconstruire toutes les entrées à chaque fichier. La provenance bulk est un contrat interne dédié, lié au projet, plan/opération, action/version, inventaire final et hash intégral ; elle n'est jamais déduite de request.extensions, de receipt.actionId ou d'un reçu client. P08 émet la capacité seulement après préparation canonique gelée ; P06 définit et teste ce contrat interne. Après reconstruction, journal strict et historique canonique hash-chain font foi, puis le certificat est revalidé contre leurs données. La menace couverte est l'usurpation par client API ; aucun HMAC, keystore ni protection contre la réécriture directe des fichiers privés par un attaquant filesystem n'est ajouté. Les payloadRefs/projections bornées relèvent du port canonique P06, leurs verbes/jobs de transport de P09.

### P07 — Export canonique déterministe

**Créer :**

- packages/map_authoring/lib/src/domains/assets/resource_pack_projection.dart
- packages/map_authoring/lib/src/domains/maps/canonical_border_ground_composer.dart
- packages/map_distribution/lib/src/resource_pack_builder.dart
- packages/map_authoring/test/domains/assets/resource_pack_export_test.dart
- packages/map_distribution/test/resource_pack_builder_test.dart

**Modifier si nécessaire pour réutilisation canonique :** ResourcePackReferenceVisitor dans resource_pack_dependency_graph.dart, sans modifier rétroactivement le lot P03 ; border_smart_tile_ground_snapshot_service.dart dans map_editor délègue au composeur headless partagé, avec sa suite existante de composition/animation. Aucun import de map_editor dans authoring.

- [ ] Écrire une fixture2D avec deux décors partageant un atlas et une fixture3D avec GLB embarqué, terrain, bordure et environnement.
- [ ] Ajouter les personnages avec portraits/animations personnalisées et le cas motif indépendant.
- [ ] Extraire une sélection et sa fermeture sortante ; rendre visibles les supports automatiques.
- [ ] Fermer d'abord les seules racines natives sélectionnées, puis construire le catalogue portable strict ; un Border privé/non publié non sélectionné ne doit pas bloquer une racine exportable.
- [ ] Normaliser explicitement la copie portable des champs d'organisation non portables, sans modifier la source.
- [ ] Réécrire les identités typées, catégories, familles, groupes de connexion et supports ; ne pas préfixer aveuglément les IDs de snapshots content-addressed.
- [ ] Prouver les pixels Border depuis les vraies sources avant puis après remappage ; conserver le hash RGBA et recalculer assetFingerprint lorsque ID/chemin changent. Si les candidats pondérés remappés ne reproduisent plus la publication, refuser explicitement, sans nouveau format RNG ni copie du snapshot comme preuve de lui-même.
- [ ] Construire un ZIP vers sink avec offsets/CRC/tailles connus ; tri UTF-8, timestamps et attributs fixes. Le writer peut lire deux fois un fichier pour déterminer ses métadonnées, sans en retenir tous les octets.
- [ ] Réinspecter l'archive finale ; deux exports de la même révision et mêmes métadonnées donnent exactement les mêmes octets.
- [ ] Modifier une source pendant l'export : résultat refusé, aucun pack publié comme valide.
- [ ] Exécuter :

~~~bash
cd packages/map_distribution
dart test test/resource_pack_builder_test.dart test/resource_pack_inspector_test.dart test/game_package_builder_test.dart
cd ../map_authoring
dart test test/domains/assets/resource_pack_export_test.dart test/domains/distribution/resource_library_export_test.dart
dart analyze
~~~

**Gate :** source projet inchangée, archive autonome et roundtrip sémantique des sept kinds/supports.

**Audit préparatoire P07 :** le ZIP existant et GamePackageBuilder matérialisent toute l'archive ; réutiliser leur profil déterministe STORE/UTF-8/attributs fixes mais écrire vers sink avec backpressure et deux lectures vérifiées, sans dépendance de distribution vers AuthoringPayload. Le composeur de sols Border est actuellement réservé à l'éditeur : extraire résolution des vingt rôles, timeline et transformations vers authoring avec callback de lecture PNG autorisée, conserver l'IO racine/chemin dans l'adaptateur éditeur. Utiliser ProjectTilesetVisualResolver pour les marges/gouttières ; une variante non reproductible doit être refusée clairement. Un SmartTileModel3dSource servant à produire le snapshot de sol2D est refusé en v1 faute de renderer3D headless ; cela ne retire pas le support des modèles GLB du pack. Les médias identiques partagent leur blob ZIP tout en conservant leurs bindings/chemins natifs propres.

### P08 — Préparation et installation additive

**Créer :**

- packages/map_authoring/lib/src/domains/assets/resource_pack_import_preparer.dart
- packages/map_authoring/lib/src/domains/assets/resource_pack_actions.dart
- packages/map_authoring/test/domains/assets/resource_pack_actions_test.dart
- packages/map_authoring/test/domains/assets/resource_pack_transaction_test.dart
- packages/map_authoring/test/domains/assets/resource_pack_reimport_test.dart

**Modifier :** application/map_mutation_dispatcher.dart, registre d'actions, API locale de composition, codecs du reçu d'installation et gardes pertinentes.

- [ ] Construire un preparedImportHandle lié à archiveHash, sélection/révision, projet/révision, mappings, contraintes et inventaire exact.
- [ ] Allouer tous les IDs et chemins avant le plan. Pour model3d : reconstruire assets/models3d/<nouvel-id>.glb et respecter le regex natif des IDs.
- [ ] Remapper toutes les références et vérifier la fermeture après projection dans le manifeste cible.
- [ ] Préserver la désignation isWorldTileset de la cible ; aucune bibliothèque importée ne choisit le tileset monde du projet.
- [ ] Produire un changeset unique : définitions, classification, AssetCatalog, blobs/aliases, documents de licence et reçu d'installation.
- [ ] Enregistrer resource_pack.import avec paramètre preparedImportHandle ; requête courte et projection compacte.
- [ ] Protéger sources locales modifiées, identités occupées et dépendances déjà installées mais éditées.
- [ ] Tester chaque ligne de la table3.3, y compris suppression locale suivie d'un réimport qui ne recrée pas silencieusement le travail supprimé.
- [ ] Tester qu'un conflit preserveProject reste non applicable, puis que le choix explicite importCopy produit une autre fermeture sans modifier la cible existante.
- [ ] Tester dry-run sans écriture native, plan périmé, repeated operationId, reconstruction du service puis réimport, undo/redo et fermeture/réouverture.
- [ ] Tester crash/disque plein/fichier ciblé modifié pendant promotion : reçu durable ou recoveryRequired, jamais faux succès.
- [ ] Vérifier que les cartes, scènes, dialogues, paramètres projet et données de progression restent identiques.
- [ ] Exécuter :

~~~bash
cd packages/map_authoring
dart test test/domains/assets/resource_pack_actions_test.dart test/domains/assets/resource_pack_transaction_test.dart test/domains/assets/resource_pack_reimport_test.dart test/domains/assets/content_addressing_test.dart test/domains/assets/asset_security_test.dart
dart analyze
~~~

**Gate :** installation native autonome, ID/references/collisions préservés, aucune mise à jour destructive cachée.

### P09 — Jobs, JSONL, CLI et MCP

**Créer :**

- packages/map_authoring/lib/src/api/resource_pack_transfer_api.dart
- packages/map_authoring/lib/src/application/resource_pack_job_service.dart
- tools/pokemap_mcp/src/tools/resource_packs.ts
- packages/map_authoring/test/application/resource_pack_job_service_test.dart
- packages/map_authoring/test/tooling/jsonl_resource_pack_flow_test.dart
- tools/pokemap_mcp/test/resource_pack_stdio.test.ts

**Modifier :**

- contracts/job_contracts.dart uniquement pour une extension réellement nécessaire et versionnée ;
- tooling/jsonl_worker.dart et bin/pokemap_authoring.dart pour la composition/canal ;
- api/authoring_read_contracts.dart, registry/resource_kind_registry.dart et registre de capacités/schémas ;
- tools/pokemap_mcp/src/server.ts et les interfaces AuthoringGateway nécessaires ;
- full_authoring_parity.dart, son registre de preuves et pokemap_authoring_api_mcp_action_catalog.md.

- [ ] Enregistrer le job avant toute I/O lourde et retourner son identité.
- [ ] Réutiliser les états existants ; exposer phase/compteurs/cancelAllowed dans les événements.
- [ ] Exécuter l'inspection/hash/ZIP synchrone hors de la boucle séquentielle ; tester un poll reçu avant la fin d'un travail contrôlé.
- [ ] Implémenter handles et révisions de sélection ; appliquer un filtre côté serveur pour les grandes sélections.
- [ ] Appliquer la même API de préparation et d'application depuis Studio/direct/JSONL/MCP.
- [ ] Tester flux complet par stdin/stdout, pagination, répétition, erreur tardive, déconnexion/reconnexion et annulation avant/après réservation. Couvrir undo/redo/revert/recover bulk avec un poll reçu pendant le travail et un reçu réconcilié après reconstruction.
- [ ] Tester la course cancel/réservation ; un refus tardif retourne resource_pack.cancel_not_allowed, pas un AuthoringJobCancellation invalide. Une annulation acceptée ne peut pas être suivie d'une promotion.
- [ ] Vérifier discoverability des actions, schémas, ressources et budgets via pokemap_describe.
- [ ] Tester resources/read en plus de pokemap_query pour les inspections et previews.
- [ ] Rebuild/reload du serveur de test, puis exécuter :

~~~bash
cd packages/map_authoring
dart test test/application/resource_pack_job_service_test.dart test/tooling/jsonl_resource_pack_flow_test.dart test/parity/full_authoring_parity_test.dart test/registry/action_registry_test.dart test/tooling/registry_documentation_test.dart
dart run tool/pmcp085_conformance.dart
dart analyze
cd ../../tools/pokemap_mcp
npm run check
npm run build
node --import tsx --test test/resource_pack_stdio.test.ts test/conformance_security.test.ts test/authoring_client.test.ts test/resource_library_stdio.test.ts
~~~

**Gate :** mêmes effets et mêmes refus sur les transports ; aucun gros binaire, grand manifeste ou grand diff inline. Un serveur testé n'est pas automatiquement le serveur attaché à toutes les sessions : inspecter la connexion utilisée pour la preuve.

### P10 — Installation Studio

**Créer les six fichiers Studio de la carte7**, plus :

- test/application/resource_pack_transfer_controller_test.dart
- test/presentation/resource_pack_transfer_dialog_test.dart
- test/resource_io/resource_pack_import_host_test.dart
- test/resource_io/resource_pack_cancellation_host_test.dart

**Modifier :**

- resource_library_screen.dart et resource_library_header.dart ;
- resource_workspace_pane.dart, resource_workspace_actions.dart et resource_navigation.dart ;
- features/resources/data/local_resource_adapter.dart et resource_navigation_management.dart ;
- app/di/resource_providers.dart et app/studio_bootstrap.dart ;
- presentation/shell/studio_workspace_host.dart ;
- map_workspace_screen.dart et workspace_secondary_content.dart.
- workspace_session_loader.dart et workspace_lifecycle_binding.dart : ownership/dispose du contrôleur ; réutiliser les guards de workspace_close_actions.dart/workspace_export_binding.dart et ResourceNavigation, sans créer un second système de fermeture.

- [ ] Injecter les pickers, le port et le contrôleur possédé par la session ; aucun decodeur ZIP dans les widgets.
- [ ] Tester annulation picker, inspect invalide et préservation du projet.
- [ ] Présenter la sélection virtualisée, les filtres de contexte et les dépendances automatiques.
- [ ] Tester « sélectionner tous les résultats » sans sérialiser10000 IDs depuis le widget.
- [ ] Préserver les lignes sélectionnées mais masquées ; compter sélection totale et résultats visibles séparément.
- [ ] Ajouter conflits et résumé exact ; aucun remplacement de ressource proposé dans la v1.
- [ ] Appliquer via l'API canonique et passer le reçu dans le mécanisme existant de reconciliation.
- [ ] Bloquer le changement/fermeture de projet pendant finalisation ; une réponse d'une ancienne session ne peut pas s'appliquer à la nouvelle. Tester fermeture avant application avec annulation confirmée, finalisation non interrompue, changement de session refusé et fermeture refusée tant qu'un reçu appliqué attend la réconciliation.
- [ ] Tester erreur de refresh après commit : message de succès d'import avec action de relecture, aucun deuxième apply.
- [ ] Tester import/reopen, usage de chaque type, petite fenêtre, zoomtexte et clavier.
- [ ] Exécuter :

~~~bash
cd apps/avelune_studio
flutter test --no-pub test/application/resource_pack_transfer_controller_test.dart test/presentation/resource_pack_transfer_dialog_test.dart test/resource_io/resource_pack_import_host_test.dart test/resource_io/resource_pack_cancellation_host_test.dart test/presentation/resource_library_intent_test.dart test/resource_io/resource_library_host_test.dart
flutter analyze --no-pub
~~~

**Gate :** vrai fichier pack → sélection → import → ressources natives réouvertes ; aucun tableau mémoire de toutes les vignettes ou de tous les octets.

### P11 — Export Studio et aller-retour

**Créer :** apps/avelune_studio/test/resource_io/resource_pack_export_host_test.dart.

- [ ] Ajouter le parcours export au même contrôleur et à la même route, avec état explicitement distinct de l'import.
- [ ] Présenter source sélectionnée, fermeture, éléments privés devenant communs et informations d'organisation neutralisées. Tester sélection mixte2D/3D indépendante de la carte active.
- [ ] Afficher la liste des brouillons divergents et le message de version publiée ; tester que le brouillon reste identique et que seule la publication annoncée est exportée.
- [ ] Valider métadonnées/version/provenance et documents de licence avant build.
- [ ] Exporter vers stage, réinspecter, puis copier vers destination via picker natif.
- [ ] Tester annulation et erreur en conservant l'ancien fichier de destination.
- [ ] Tester projetA → pack → projetB : mêmes visuels/collisions/animations/règles après remappage, sourceA inchangée.
- [ ] Tester nouvelle édition d'une bordure et d'un terrain importés, puis sauvegarde/réouverture. Une ouverture → sauvegarde → republication sans modification conserve exactement les visuels/collisions de la publication exportée ; tester le refus de sources éditables ayant dérivé des snapshots.
- [ ] Exécuter :

~~~bash
cd apps/avelune_studio
flutter test --no-pub test/resource_io/resource_pack_export_host_test.dart test/resource_io/resource_pack_import_host_test.dart test/resource_io/resource_pack_cancellation_host_test.dart
flutter analyze --no-pub
flutter build macos --debug --no-pub
~~~

**Gate :** fichier distribué par l'exporteur officiel, réimportable dans une autre bibliothèque sans projet source.

### P12 — Certification fonctionnelle, volume et Player

**Créer :**

- tools/pokemap_product_certification/test/resource_pack_volume_test.dart
- tools/pokemap_product_certification/tool/resource_pack_volume.dart
- apps/avelune_studio/test/resource_io/resource_pack_native_roundtrip_test.dart
- packages/map_runtime/test/resource_pack_installed_resources_test.dart

- [ ] Générer les fixtures synthétiques en répertoire temporaire :10/1000/10000 ressources,20000 entrées, volume proche de512Mio ; aucun gros binaire ajouté au Git.
- [ ] Tester références partagées, noms identiques, univers distincts, connectionGroupIds identiques, atlas mixte, personnages personnalisés et sept kinds.
- [ ] Exécuter les contrôles de borne par source virtuelle en test rapide ; exécuter les volumes réels uniquement localement.
- [ ] Mesurer séparément inspection, préparation, publication, réouverture, undo et export, avec octets lus/écrits et RSS observé.
- [ ] Vérifier que les buffers binaires sont bornés par la fenêtre d'I/O et les candidats de validation, pas par la taille totale ; documenter le coût distinct du catalogue JSON.
- [ ] Vérifier le nombre d'écritures de journal et le temps de réponse des polls sous travail contrôlé.
- [ ] Injecter arrêt/reconstruction à chaque frontière de journal et milieu de série ; vérifier replay/undo sans ressources orphelines.
- [ ] Faire un vrai parcours Studio sur un petit pack2D et un petit pack3D : ouvrir/importer/placer/peindre/tracer/répartir/enregistrer/fermer/rouvrir.
- [ ] Dans le Player réel : déplacement et contact sur les collisions importées, animation visible, raccords de terrain/bordure corrects ; capturer les résultats, pas seulement les entrées clavier.
- [ ] Supprimer l'archive source après installation dans une fixture : le projet et son export de jeu restent utilisables.
- [ ] Vérifier que l'export .avelunegame conserve les fichiers nécessaires et ne dépend pas de la trace d'installation pour fonctionner.
- [ ] Exécuter les tests ciblés, puis les suites des packages modifiés. Les suites lentes/volumes ne deviennent pas des dépendances CI obligatoires.

Commandes de la nouvelle certification :

~~~bash
cd tools/pokemap_product_certification
dart test test/resource_pack_volume_test.dart
dart run tool/resource_pack_volume.dart --resources 10000 --archive-bytes 536870912 --mode local
cd ../../packages/map_runtime
flutter test --no-pub test/resource_pack_installed_resources_test.dart
cd ../../apps/avelune_studio
flutter test --no-pub test/resource_io/resource_pack_native_roundtrip_test.dart
~~~

Le harness définit son résultat JSON : commit, statut worktree, politique de pack, hash d'archive, nombre de racines/dépendances/fichiers, timings par phase, maxBytesInFlight observé, RSS observé, checkpoints/recovery et descendants de processus restants. Le bord536870912 doit être testé comme plafond, pas supposé réalisable si les autres quotas sont atteints avant.

**Gate :** reçus techniques, revue visible Studio et preuve Player sont séparés et tous présents. Aucun chiffre de RAM/FPS/durée garanti avant mesure.

### P13 — Construire puis qualifier les cinq collections

**Différé par décision explicite de Yoahn pendant l'exécution, le 16 octobre 2026 : « pour le moment, on ne va pas créer de galeries d'assets ».** L'exécution actuelle porte sur le système de classement et de transfert, lots P01–P12 puis revue P14. Les tâches de préparation de contenu ci-dessous restent une proposition future, sans collecte, conversion ni constitution des collections pendant ce chantier.

La création de contenu reste hors des tests du mécanisme. Le système peut être validé avec des fixtures originales sans prétendre que les cinq packs Pokémon sont complets.

- [ ] Produire un inventaire par collection : sources locales réellement disponibles, formats, dimensions et provenance.
- [ ] Pour les collections DS, identifier les vrais modèles/GLB et textures ; la conversion éventuelle forme un travail distinct avec un résultat validé.
- [ ] Préparer les ressources logiques : découpage, nom, famille, contexte, échelle, ancrage, collision, animation et règles de raccordement.
- [ ] Inclure les variantes de version dans les libellés/métadonnées, sans fusionner des ressources distinctes par leur nom.
- [ ] Fixer pour chaque collection une liste attendue et un statut de chaque ressource : identifiée/préparée/qualifiée/importable.
- [ ] Vérifier les licences et attributions déclarées pour la destination prévue ; le moteur ne certifie pas automatiquement leur portée.
- [ ] Exporter avec le même outil que le créateur, sans fabrication manuelle d'un ZIP divergent.
- [ ] Réimporter chaque pack dans un projet vierge adapté à sa dimension.
- [ ] Construire une scène de contrôle extérieure et une intérieure ; vérifier échelles, raccords, collisions et animation dans le Player.
- [ ] Publier dans le ticket un reçu par collection : version/hash, compte attendu/obtenu, types, contextes, limites et revue visible.

**Gate :** une collection n'est annoncée « complète » que relativement à son inventaire approuvé. Les cinq lignes ne deviennent pas complètes ensemble parce que l'importeur fonctionne.

### P14 — Revue et livraison

- [ ] Refaire l'état Git, les fichiers modifiés et les écarts au plan ; préserver les modifications étrangères.
- [ ] Relire le modèle et les frontières core/distribution/authoring/Studio/MCP.
- [ ] Vérifier les critères de la matrice10, les tests réellement exécutés et les N/A motivés.
- [ ] Recharger le MCP du checkout et vérifier les contrats en direct ; ne pas confondre build et serveur réellement utilisé.
- [ ] Faire une critique indépendante : pertes de données, remapping, source externe, versions, annulation, mensonge de progression, quotas et historique.
- [ ] Mettre le lot implémenté et vérifié à TO REVIEW, avec commit/branche si une autorisation Git a été donnée séparément.
- [ ] Laisser DONE à la décision explicite de Yoahn.
- [ ] Conserver séparément le statut du système et celui de chaque bibliothèque de contenu.

## 10. Matrice de validation obligatoire

| Cas | Preuve attendue |
|---|---|
| Classement intérieur seul | Persiste sans famille ni portée spéciale |
| Clear/null/omission | Clear efface, omission préserve, valeur invalide refuse avant écriture |
| both | Visible dans les deux filtres |
| Non renseigné | Ressource retrouvable, aucune inférence automatique |
| Contexte vs famille/carte/dimension | Axes indépendants ; aucune perte de pinceau ou d'instance |
| Sept kinds | Roundtrip et usage pour chaque kind |
| Atlas mixte | Deux décors de contextes différents, même fichier partagé |
| Support personnage | Portraits et définitions personnalisées remappés |
| Motif autonome | Inclus seulement par sélection explicite, références conservées |
| Border/Smart Tile | Publication valide, snapshots vérifiés, édition/republication possible après import |
| GLB | Texture embarquée, inspection recalculée, pivot/échelle/collision/animation conservés |
| Références inconnues | Refus de racine, aucun champ arbitraire supposé portable |
| Déduplication | Octets identiques réutilisés, définitions distinctes conservées |
| Deux univers/packs | IDs et groupes de connexion isolés |
| Réimport | No-op et modifications/suppressions locales conservées |
| Nouvelle version | Copie côte à côte, aucune mise à jour en place |
| Identité/version réécrite | Refus hash différent |
| Plan périmé | Aucun changement partiel |
| Archive remplacée après inspection | Stage possédé ou refus d'empreinte |
| Deadline | Poll possible pendant traitement ; aucune opération mutante cachée après faux timeout |
| Annulation | Avant publication : absence d'effet ; après réservation : finalisation/recovery |
| Échec de refresh | Commit connu, reçu réconciliable, pas de second import |
| Crash/disque plein | Journal récupérable et état final certifié |
| Undo massif | Même origine certifiée et mêmes ressources restaurées |
| Redo/revert/recovery massif | Budget d'origine conservé et exécution job, sans timeout synchrone caché |
| Pages | Diff interne exact, pages complètes, réponses bornées |
| Gros volume | Cold open/apply/undo/export et journal linéaire qualifiés localement |
| Autonomie | Archive source absente et projet toujours jouable |
| Native Studio/Player | Résultats visibles distincts des tests widget et structurels |

## 11. Discipline d'exécution et coût

- Aucun test long ou runner macOS ajouté à la CI par ce plan.
- CI ordinaire : codecs, petites fixtures, matrices, quotas virtuels, crash injection déterministe et parité ciblée.
- Certification réelle de volume et parcours natifs : locaux, opt-in.
- Les exécutions Flutter sont suivies par PID/descendants pendant le run ; vérifier date/commande/propriété avant toute terminaison d'un leftover. Aucun kill par nom.
- Les serveurs MCP ouverts pour les preuves sont fermés avec leurs workers. Ne pas arrêter les sessions concurrentes.
- Exécuter les commandes Flutter séquentiellement si elles partagent les verrous du SDK.
- Ne pas écrire des tests d'une nouvelle règle de gameplay : le contexte n'est pas une règle de gameplay.
- Les tests négatifs du numéro de format doivent être mis à jour pour continuer à tester les champs invalides, pas seulement un rejet de version.
- Les fixtures de contenu utilisent des assets originaux minimaux ; aucune collecte en ligne ou copie de ROM implicite.
- Les commentaires de code suivent la demande directe de Yoahn : pas de commentaires ajoutés sans demande explicite ; noms et types portent les invariants.

## 12. Revue du plan et limites connues

### Décisions de synthèse après les passes indépendantes

| Passe | Verdict et décision retenue |
|---|---|
| Architecture / portabilité | Catalogue commun pour le contexte ; fermeture sortante typée ; GLB autonome ; SHA brut distinct du fingerprint authoring ; supports et motifs explicites |
| Gros volumes / transactions | Stage disque insuffisant seul : payloads, historique et snapshots évoluent ensemble ; journal phaseOnly ; budgets bulk vérifiés et réponses paginées |
| Studio | Deux parcours depuis Ressources ; dépendances automatiques et sélection conservée sous filtre ; résultat après commit distinct d'un échec de refresh |
| Implémentation | Non exécutée ; les fichiers et APIs proposés restent à réaliser lot par lot |
| Tests / Build | Pas de build produit nécessaire pour écrire ce document ; validations du document et contrats ci-dessous, suites produit planifiées par lot |
| Critique finale | Favorable après corrections et relecture ciblée : portabilité, transaction/volume et parcours Studio couverts ; aucun finding bloquant restant sur le plan |

### Arbitrages délibérés

- Un seul format2D/3D, avec compatibilité native des sélections, plutôt qu'un format par univers.
- Contrats partagés de pack dans map_core et I/O d'archive dans map_distribution, conformément aux frontières du dépôt ; AssetCatalog reste dans map_authoring.
- Archive512Mio et payload500Mio pour un profil STORE cohérent ; l'ancien staging média256Mio n'est pas relevé.
- Réimport additif/copie, pas de remplacement en place.
- Catalogue de contexte v2 explicite, sans migration pré-1.0.
- Mémoire bornée pour les binaires, sans promettre une RAM constante pour10000 définitions et un catalogue JSON32Mio.
- Pas de performance cible inventée ; les mesures réelles sont une gate de certification.

### Risques et réponses

| Risque | Réponse du plan |
|---|---|
| P05/P06 touchent une infrastructure partagée | Lots séparés, tests de régression transaction/history et revue avant import |
| Références natives sous-estimées | Visiteurs par kind, supports explicites, rejet des propriétés inconnues |
| Publication et édition d'une bordure diffèrent | Projection publiée + reconstruction native d'un draft éditable, test d'édition/republication |
| Catalogue projet très volumineux | Quotas JSON, pages, snapshot binaire lazy, qualification cold open |
| Espace disque plus élevé que poids du pack | Préflight tenant compte staging/CAS/aliases/history ; recovery sur erreur |
| Lecteur Player ancien | Version du catalogue assumée, build/qualification des lecteurs du lot de livraison |
| Stage nettoyé trop tôt | Leases de plan/job/history/recovery et tests de durée de vie |
| Fichier logique altérant l'historique | Copies possédées et hashes ; aucun hardlink modifiable |
| Importeur green mais packs incomplets | Gates séparées système/collections et inventaire approuvé par pack |

### État documentaire de cette livraison

Les preuves de l'analyse précédente —62 tests ciblés réussis et analyses/build MCP — datent de la phase d'audit ; elles ne sont pas des tests d'implémentation du présent plan et n'ont pas été relancées pour cette modification documentaire.

Vérifications de rédaction exécutées :

- inventaire des14 lots dans l'ordre et des cases d'exécution ;
- contrôle Python des liens locaux, espaces de fin de ligne et clôture des blocs de code : réussi ;
- extraction des4 blocs Dart et passage de dart format --output=none sur fichiers temporaires :4 parsings réussis, exit0 ; ce contrôle ne compile pas les futurs contrats ;
- première passe du parseur : un exemple de test devait être enveloppé dans main ; corrigé dans le document, puis les4 blocs sont passés ;
- bash tools/scripts/check_markdown_hygiene.sh : exit1, seul diagnostic «1 new Markdown files exceed the default limit of0». Il s'agit de l'unique plan demandé explicitement ; aucun contournement du plafond ou changement de script. Aucun autre défaut de placement/taille n'a été signalé ;
- recherche des marqueurs de rédaction incomplets et revue croisée des contrats : corrections intégrées, pas de décision structurante laissée sous un marqueur de remplissage.

Les passes architecture/portabilité et gros volumes ont relu les corrections sur le fichier courant et rendu un verdict favorable. Les précisions Studio ont été intégrées : filtre initial Tous, export indépendant de la carte active, ownership/close existants et message sur les brouillons divergents.

Seul fichier ajouté : documentation/reports/avelune_studio/plans/2026-10-16_asset_context_and_asset_packs_implementation_plan.md. Aucun fichier produit, test, fixture ou réglage CI modifié. Aucun test produit ni build lancé pendant la rédaction ; aucun résultat de performance d'import annoncé. Branche/SHA observés au début et à la remise : main,00c3112c0754ee54553584d38f7e44598c3077c3, checkout déjà modifié avant la mission. Les changements étrangers ne sont ni inclus dans ce plan comme travaux réalisés, ni nettoyés. Aucune commande Git d'écriture exécutée.

Seul ce document doit être ajouté au dépôt pendant cette mission. Le ticket Notion reçoit le lien, le périmètre, le statut de proposition et les limites. Aucun fichier produit, test ou réglage CI ne doit être changé pour donner l'impression d'avoir commencé l'exécution.


## 13. Exécution autorisée et suivi

Le 16 octobre 2026, Yoahn demande l'exécution de tous les lots et un commit ciblé après chaque lot vérifié. Cette instruction autorise les commits de ce chantier ; elle ne demande ni push, ni rebase, ni nettoyage du checkout partagé. Les mentions de non-implémentation des sections précédentes décrivent la remise initiale du plan.

L'état initial d'exécution est main, 00c3112c0754ee54553584d38f7e44598c3077c3, index vide et 241 entrées modifiées/non suivies, dont ce plan déjà livré. Les fichiers P01 étaient propres, sauf le catalogue Markdown d'actions déjà modifié par un chantier Smart Tiles ; seuls les ajouts de contexte de ce fichier seront inclus au commit. Les changements étrangers restent en place.

| Lot | État d'exécution | Preuve / limite |
|---|---|---|
| P01 | TO REVIEW | Commit c490df127 ; 9 tests core, 54 authoring et 1 MCP réussis ; revues favorables ; limites globales détaillées ci-dessous |
| P02 | TO REVIEW | Commit 420f2b9e3 ; 52 tests Studio, analyse et parcours natif réussis ; 7 tests spécialisés relancés après correction |
| P03 | TO REVIEW | Commit625b94f4f, quinze fichiers ;47 tests ciblés,408 tests avec SmartTile/1skip en copie isolée, deux revues favorables ; prérequis natifs committés séparément |
| P04 | TO REVIEW | Deux revues favorables ;351 tests distribution/35 authoring partagés,350 distribution/36 authoring dans la copie isolée sansP05 ; analyses/builds vérifiés, staging séparé préparé |
| P05 | DOING | Audit et baseline consignés ; implémentation séquentielle engagée après les deux avis favorables P04 |
| P06 | TODO | Journal bulk et budgets restreints |
| P07 | TODO | Export portable |
| P08 | TODO | Installation additive |
| P09 | TODO | Jobs et transports |
| P10 | TODO | Import Studio |
| P11 | TODO | Export Studio et aller-retour |
| P12 | TODO | Certification locale et preuves natives |
| P13 | Différé par Yoahn | Constitution des collections exclue de l'exécution actuelle ; système P01–P12 et revue P14 conservés |
| P14 | TODO | Revue finale du système ; collections P13 différées |

### Preuves d'exécution du lot P01

Fichiers produit : resource_library_catalog.dart (enum/champ, codecs/égalité/hash stricts et version2), resource_library_actions.dart (schéma partagé, clear/omission, conservation des entrées de contexte), resource_library_scope_guard.dart (héritage lors de duplication), resource_kind_registry.dart (extensions découvrables ciblées). La query et l'export utilisent déjà le codec commun ; aucun second champ manuel ni lecteur v1 ajouté. Les deux actions gardent leur version1 : ajout de paramètre optionnel.

Tests modifiés : resource_library_catalog_test.dart ; resource_library_actions_test.dart ; jsonl_resource_library_flow_test.dart ; resource_library_export_test.dart ; tools/pokemap_mcp/test/resource_library_stdio.test.ts. Le golden describe_and_error.jsonl reçoit uniquement les deux extensions de contexte ; le catalogue Markdown d'actions reçoit uniquement le contrat de contexte et la rupture de format.

Commandes et résultats :

- map_core : dart test test/resource_library_catalog_test.dart --reporter expanded → 9 réussis, exit0. dart analyze → exit0, 129 infos préexistantes ; analyse des deux fichiers touchés → No issues found.
- map_authoring : dart test test/domains/assets/resource_library_actions_test.dart test/tooling/jsonl_resource_library_flow_test.dart test/domains/distribution/resource_library_export_test.dart → 54 réussis, exit0. dart analyze → No issues found.
- tools/pokemap_mcp : npm run check et npm run build → exit0. node --import tsx --test test/resource_library_stdio.test.ts → 1 réussi, 0 échec ; describe sur le serveur construit : 418 mutations, 60 resourceKinds, enum/clear/omission vérifiés.
- Contrôles supplémentaires root : dart test test/parity/full_authoring_parity_test.dart test/tooling/registry_documentation_test.dart test/registry/action_registry_test.dart --reporter expanded → 32 réussis, 1 échec : cinematicMediaAsset absent du registry. Ce kind n'est ni ajouté ni retiré par P01.
- dart run tool/pmcp085_conformance.dart → exit1 : catalogComplete=true, blockedOrMissingCount=0, itemTransportCertificationComplete=false. Cette dette de reçus Items ne constitue pas une preuve de parité complète.
- npm run verify:checkout-catalog → catalogue live lu correctement, puis exit1 explicitement causé par workingTreeClean=false ; ce script exige un checkout entièrement propre.
- Le test golden global JSONL conserve un drift existant de sourceVariants eventV2 et de map.extensions ; ne pas remplacer les parties étrangères du golden pour masquer ce drift. Les deux descripteurs P01 correspondent au describe réel.
- Studio avant P02 : flutter analyze --no-pub → No issues found! (16.4s), exit0.
- git diff --check ciblé → exit0. Le contrôle Markdown avant commit retourne exit1 pour l'unique plan explicitement demandé et encore non suivi, sans autre défaut ni nouveau document.

L'audit indépendant confirme la conformité P01 et a relancé les 9+54 tests ciblés avec succès. La critique qualité indépendante conclut favorablement, sans défaut bloquant trouvé, après lecture des sources/tests et vérification ciblée du diff. Aucun comportement Studio de filtre n'est annoncé livré par P01 ; il appartient à P02. Aucun résultat global entièrement vert n'est revendiqué au vu des limites ci-dessus.

### Inventaire préalable P13 — sources et limites

Inventaire ciblé en lecture seule ; aucun import, extraction ou modification de projet.

| Collection | Source actuelle observée | État |
|---|---|---|
| RSE 2D | /Users/karim/Downloads/The-PMon-World-Project-main, préfixe RSE_ : 123 PNG, 36 SHA256 distincts | Atlas source, pas encore ressources découpées/qualifiées |
| FRLG 2D | Même corpus, préfixe FRLG_ : 101 PNG, 21 SHA256 distincts | Atlas source, pas encore ressources découpées/qualifiées |
| DPPt 3D | Aucun modèle identifié dans les corpus ciblés ; sprites génération4 disponibles | Source 3D à localiser ; question posée à Yoahn |
| HGSS 3D | apps/hgss_render_lab/assets : 2 OBJ et textures ; conversion johto-essential-interiors-20261008 sous Desktop/pokeMap Project/Remastered Kanto Johto : 76 NSBMD, 11 NSBTX | Modèles réels mais préparation/conversion et inventaire de collection restants |
| BW 3D | Aucun corpus distinct identifié ; stock NB2 confirmé séparément | Source BW à localiser ; aucune substitution BW2 implicite |

Le projet /Users/karim/Desktop/pokeMap Project/pokemon_nb2 déclare « Pokémon Noir et Blanc 2 — entraînement », 9227 modèles logiques et 9227 GLB directs. Le premier GLB contrôlé possède le header glTF2 et la taille déclarée26124 égale aux octets réels. Les quatre comptages RSE/FRLG et NB2 ont été reproduits par root. Les copies sous .pokemap et les rendus de travail ne sont pas additionnés. Le corpus de704 ZIP sous Downloads/pokemon-black2-white2-models-sans-pokemon et ses sources Nitro désignent explicitement BW2. Ce constat ne qualifie ni leurs collisions, ni leurs contextes, ni leur redistribution.

À la suite de cette question de sources, Yoahn a explicitement reporté la création des galeries d'assets. Cet inventaire reste une observation préalable en lecture seule ; il ne crée pas de dépendance au contenu pour livrer le système. Aucun travail de préparation de collection ne continue dans l'exécution actuelle.

### Preuves d'exécution du lot P02

Périmètre : classement et filtres Studio, sans contrainte de placement. L'audit initial a confirmé les trois ateliers spécialisés et les deux sélecteurs secondaires à raccorder. Les filtres restent indépendants de MapRole et MapMetadata.isIndoor. L'état de pinceau existant est déjà neutre : map_workspace_view_state.dart et map_workspace_palette_dock_filters.dart ne nécessitent pas de modification produit ; les tests prouvent cette propriété.

Inventaire des 18 fichiers produit, tous sous apps/avelune_studio/lib/presentation/features :

| Fichier | Zone modifiée et effet |
|---|---|
| resources/resource_catalog.dart | ResourceCatalogContext, copy/copyFrom/reset/reveal et prédicat commun ; both appartient aux deux filtres, null au filtre Non renseigné |
| resources/resource_library_bindings.dart | classifyResource, sélecteur Contexte d'usage, état dirty et paramètre nullable de resource.classify |
| resources/resource_filter_button.dart | Brouillon du filtre, compteur, Apply/Cancel/Reset et tag amovible |
| resources/resource_catalog_view.dart | Libellé de contexte des cartes/lignes |
| resources/resource_detail_panel.dart | Badge et métadonnée de contexte |
| resources/resource_family_tree.dart | Comptage à partir de la copie des filtres actifs, seule la famille est neutralisée |
| resources/resource_library_layout.dart | Filtrage avant construction des ateliers, outils conservés quand la sélection est vide |
| resources/resource_library_screen.dart | Builders recevant les ressources filtrées pour modèles et environnements |
| resources/model_resource_library.dart | Lignes filtrées, sélection cohérente, libellé direct depuis ResourceItem sans recherche quadratique |
| resources/environment_library.dart | Utilisation des EnvironmentPreset déjà filtrés |
| resources/resource_border_draft_bar.dart | Comptage et lignes issus des bordures filtrées |
| resources/resource_source_list.dart | Transmission des filtres actifs à l'arbre de familles |
| resources/environment_decor_picker.dart | Réutilisation des filtres communs du choix de décor |
| resources/resource_workspace_pane.dart | Transmission des résultats aux deux builders spécialisés |
| map_workspace/map_border_tool_panel.dart | Contrôle de contexte dans le choix secondaire, pinceau conservé |
| map_workspace/map_environment_tool_panel.dart | Contrôle commun de contexte et arbre cohérent |
| map_workspace/map_workspace_palette_dock.dart | Transmission des filtres complets de la palette et de characterQuery |
| map_workspace/map_workspace_panels.dart | Transmission des filtres à l'arbre de familles de la palette |

Tests modifiés sous apps/avelune_studio/test : presentation/resource_family_catalog_test.dart (matrice et intersections), presentation/resource_family_widgets_test.dart (transitions, compteurs, petit écran, texte agrandi et vrais événements clavier), presentation/map_workspace_palette_dock_filters_test.dart (filtre de palette), presentation/map_workspace_resource_families_test.dart (indépendance carte/contexte et pinceau), resource_io/resource_library_host_test.dart (28 cycles formulaire canonique puis réouverture sur disque, sept kinds × trois valeurs et effacement). Nouveau fichier : presentation/resource_context_specialized_libraries_test.dart, sept tests positifs/négatifs des ateliers, liste source et deux sélecteurs secondaires.

Commandes et résultats :

- Depuis apps/avelune_studio, python3 /tmp/avelune-assets-owned-run.py -- flutter test --no-pub test/presentation/resource_family_catalog_test.dart test/presentation/resource_family_widgets_test.dart test/resource_io/resource_library_host_test.dart test/presentation/map_workspace_palette_dock_filters_test.dart test/presentation/map_workspace_resource_families_test.dart test/presentation/resource_context_specialized_libraries_test.dart → 01:01 +52: All tests passed!, exit0. PID runner202, sept descendants observés, aucun reliquat possédé ni douteux.
- Après correction du balayage de liste3D : python3 /tmp/avelune-assets-owned-run.py -- flutter test --no-pub test/presentation/resource_context_specialized_libraries_test.dart → 00:03 +7: All tests passed!, exit0. PID runner19263, 21 descendants observés, aucun reliquat possédé ni douteux.
- flutter analyze --no-pub → No issues found! (ran in10.1s), exit0 après le dernier changement produit.
- Build natif : flutter run -t dev/marionette_main.dart -d macos --debug --no-pub, avec MARIONETTE_PROJECT_PATH pointant vers le projet de test possédé et MARIONETTE_CAPTURE_ROOT vers une racine déjà autorisée par le harness existant → Built build/macos/Build/Products/Debug/Avelune Studio.app, backend Metal Impeller actif. Aucun enregistrement lancé dans cette racine de captures ; le harness et ses modifications étrangères ne sont pas modifiés.
- Parcours natif dans une fenêtre1000×720 : Ranger un arbre en both et une caisse en interior, sauvegarder, vérifier les cinq ressources puis Intérieur2, Extérieur1, Non renseigné3 et retrait du tag5. Les captures et l'arbre visible confirment les libellés. hot_restart réexécute main, rouvre le même chemin canonique et conserve les deux classements. Les deux JSON de cartes et le PNG gardent leur SHA256 initial.
- Reçu local de cette passe : /Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/asset-context-qa-ybhzojg9/native-context-receipt.json. Ce projet original est jetable ; aucun contenu Pokémon de collection n'a été constitué.
- Les deux processus flutter run ont été quittés, puis leurs PIDs et descendants enregistrés ont été revérifiés : aucun processus possédé restant. Marionette est déconnecté.

Revue conformité : favorable après correction des compteurs d'arbres et du test de grand texte/clavier. Revue qualité : favorable après suppression du singleWhere par ligne dans la liste3D ; aucun finding restant dans les 24 fichiers P02 relus. Les relecteurs ont vérifié le diff sans revendiquer une nouvelle exécution Flutter. La passe Tests de l'implémenteur fournit les52 tests ; la passe Build/Validation root ajoute le build et le parcours natifs.

Critique et limites : la fixture native contient cinq ressources originales et prouve le parcours visuel pour les décors ; les sept kinds sont couverts par les28 cycles du host et ses formulaires réels, dont un vrai GLB. Aucun aperçu GPU3D réel n'a été certifié par cette fixture. Les défauts globaux P01 déjà signalés ne sont pas masqués et aucune certification d'import massif P12 n'est revendiquée. P02 est proposé TO REVIEW ; les lots P03–P12 et P14 restent à livrer. La revue s'appuie sur le diff Git des24 fichiers, sans recopier leurs sources.

### Preuves d'exécution du lot P03 — livraison autonome encore partielle

P03 est committé sur main :625b94f4ff512979e934c2a7bc5e658418f67521, quinze fichiers et aucun hunk étranger. Les prérequis sont committés séparément : Border2fe848cc7285b092fee301ef881bed3b3941e298 ; SmartTile53b16bfb819781dcb1d1d561eea46960c5574c08 (dix fichiers/hunks expressément autorisés). Le correctif généré MapConnectionDirection de sept lignes a été intégré entre-temps dans9605357ad68f1c35f2e4878bef8dfe7ed5f36405 par un autre chantier : hash comparé identique au correctif qualifié, aucun commit redondant. Les étapes ci-dessous conservent les preuves des dépendances initialement masquées par le checkout partagé. Aucun push/rebase.

Inventaire propre P03, sous packages/map_core :

| Fichier | Zone et rôle |
|---|---|
| lib/src/models/resource_pack.dart | Sept kinds, identités, manifeste, compatibilité, bindings, inventaire et provenance par définition |
| lib/src/models/resource_pack_installation_catalog.dart | Traces, mappings typés, propriétaires de supports, alias de fichiers cohérents et motifs seuls |
| lib/src/models/resource_pack_catalog.dart | Sous-catalogue sans sections projet, cohérence des bindings et portée globale portable |
| lib/src/operations/resource_pack_native_json.dart | Clés et types scalaires avant codecs permissifs, refus de troncature numérique |
| lib/src/operations/resource_pack_dependency_graph.dart | Visiteur typé, parcours itératif partagé par closure/validateAll, références et diagnostics |
| lib/src/operations/resource_pack_publication.dart | Publication Border sans brouillon privé, reconstruction éditable, preuve des pixels, reconstruction Smart Tile et groupes de connexion |
| lib/src/models/project_manifest.dart |20 lignes : import, codec optionnel et champ resourcePackInstallations |
| lib/src/models/project_manifest.freezed.dart | Sortie du champ,23 ajouts/20 suppressions après nettoyage ciblé de douze lignes blanches générées |
| lib/src/models/project_manifest.g.dart |6 lignes de lecture/écriture conditionnelle |
| lib/map_core_domain.dart | Seulement les cinq exports P03 en bas ; l'export escape_return_point reste étranger, les deux exports Border sont dans 2fe848cc7 |
| test/resource_pack_contract_test.dart |13 tests de DTOs stricts |
| test/resource_pack_installation_catalog_test.dart |10 tests de persistance et d'identité historique |
| test/resource_pack_dependency_graph_test.dart |21 tests de références, portée, types, négatifs, longue chaîne et rejet du tileset monde portable |
| test/resource_pack_publication_test.dart |3 tests de projection et édition native |

Quinzième fichier, dans map_authoring : test/workspace/project_creation_facade_test.dart. La détection des directives Dart interprétait `part == '.'` comme une directive `part`, puis tentait d'ouvrir le message d'erreur comme fichier. Le matcher exclut les comparaisons et conserve le refus des imports directs, raw, conditionnels et commentés ; matrice ajoutée dans le test existant. RED puis GREEN : /tmp/p03_creation_facade_red.log et /tmp/p03_creation_facade_green.log, un test réussi. Les deux revues sont favorables après maintien de la couverture raw/commentaires.

L'audit initial a confronté les codecs/générés courants, ProjectValidator, les publications Border et compileSmartTileAuthoringDraft. Les versions sont RL2/ST7/B10. Les object_reference restent des entiers natifs : une propriété de tuile/collision résout dans sa tuile ; source.properties, sans contexte de tuile, exige une cible unique dans le tileset. structured est refusé faute de sémantique. Le graphe vérifie les frames inter-tilesets, groupes owner-scoped, parents, Smart Tiles/motifs, personnages, environnements et sols/snapshots Border. Les supports non atteints par une sélection restent contrôlables avec validateAll.

Corrections issues des passes : source.assetId et relativePath doivent désigner le même binding utile ; les fractions destinées à un entier natif sont refusées avant .toInt(), sans altérer les flottants légitimes ; EnvironmentPreset a sa preuve dédiée ; les objets de collision sont uniques par tuile, sans faux rejet des doublons entre tuiles ; des maps/sets locaux évitent les scans quadratiques de fichiers, provenance, classification, pages et snapshots.

Commandes depuis packages/map_core et résultats :

- dart run build_runner build --delete-conflicting-outputs → exit0, Built with build_runner/aot in8s; wrote112outputs. Le générateur signale le flag ignoré et un SDK plus récent que l'analyseur ; aucune dépendance changée. Trente et une sorties générées sont modifiées dans l'état partagé observé, dont deux Manifest propres à P03 et cinq déjà modifiées au premier relevé. Les vingt-quatre autres ne sont ni restaurées ni absorbées, car génération et éditions concurrentes se sont croisées.
- dart test test/resource_pack_contract_test.dart test/resource_pack_installation_catalog_test.dart test/resource_pack_dependency_graph_test.dart test/resource_pack_publication_test.dart --reporter expanded → dernière passe après garde isWorldTileset : +47: All tests passed!, exit0. Log /tmp/p04_core_followup.log. La passe précédente collision comportait46 tests dans /tmp/p03_core_focused.log.
- dart analyze sur les sept sources manuelles et les quatre tests P03 → No issues found!, exit0 après la dernière correction.
- dart test test/project_model3d_test.dart test/project_tileset_source_test.dart test/environment_preset_json_codec_test.dart test/project_manifest_character_compatibility_test.dart test/project_manifest_environment_presets_test.dart test/smart_tiles/project_manifest_smart_tile_catalog_test.dart test/border/border_manifest_integration_test.dart test/smart_tiles/smart_tile_authoring_draft_compiler_test.dart --reporter expanded →00:00 +74: All tests passed!, exit0. Log /tmp/p03_native_regression.log.
- dart compile kernel --packages=.dart_tool/package_config.json /tmp/p03_core_build.dart -o /tmp/p03_core_build.dill puis dart /tmp/p03_core_build.dill → exit0, sortie0:0. L'entrée importe le barrel public ; les46 tests finaux recompilent aussi ces exports après le dernier correctif.
- dart test --reporter expanded → exit1,02:26 +5031 ~1 -16: Some tests failed. Dix fichiers suspects relancés seuls → exit1,00:00 +56 -16. Logs /tmp/p03_map_core_full_test.log, /tmp/p03_core_failures_isolated.log et /tmp/p03_core_failures.txt.
- Les dix fichiers sont scene_runtime_dry_run_preview_test.dart, authoring_capability_inventory_test.dart, narrative_command_contract_parity_test.dart, narrative_spatial_event_source_catalog_test.dart, beta_playability_composition_test.dart, narrative_map_events_read_model_test.dart, cinematic_media_contract_fixture_test.dart, spatial_gameplay_capabilities_test.dart, project_transform_format_v8_test.dart et scene_map_instance_contract_test.dart (sept échecs). Aucun correctif hors périmètre appliqué ; une baseline de ces seize assertions n'a pas été rejouée.
- dart analyze complet → exit0,129 informations, sans warning ni erreur ; l'analyse ciblée finale reste sans issue.
- Revue conformité indépendante : quatre tests de garde-fous relancés, +4: All tests passed!, exit0. Revue qualité indépendante : la nouvelle non-régression collision relancée, +1: All tests passed!, exit0. Les deux verdicts sont favorables après corrections.
- Les processus possédés des tests/build sont terminés. git diff --check sur le généré après nettoyage des douze ajouts blancs → exit0. Le contrôle Markdown des passes → exit0, aucun nouveau Markdown.

Contrôle du patch isolé : copie de HEAD420f2b9e3c63b92345c07de6d408c3861897b17c, puis overlay des treize fichiers propres et des cinq exports P03, avec dépendances résolues offline dans ce répertoire temporaire seulement. Les tests de contrat obtiennent11 réussites et2 échecs sur la version native Border10 absente du HEAD. Le test du graphe ne compile pas faute de BorderGroundPoint/Footprint/Surface et des propriétés groundSurfaces/groundFootprints. Reçus : /tmp/avelune-p03-clean-probe.json, /tmp/avelune-p03-clean-probe-test.log et /tmp/avelune-p03-clean-probe-public.log. Le propriétaire de la reconstruction NB2 confirme que ces API sont ses prérequis encore non committés ; sa preuve GPU reste distincte et ouverte.

Contrôle distinct du même HEAD pur, sans overlay P03 : dart test test/project_model3d_test.dart → exit1 à la compilation, _$MapConnectionDirectionEnumMap absent de map_gameplay_zone_payloads.g.dart:203/214. Ce défaut précis est donc présent avant P03 ; cela ne prouve pas l'antériorité des seize assertions de la suite partagée. Log /tmp/avelune-p03-head-baseline-test.log. Aucun changement de ce généré étranger n'a été intégré au patch P03.

Après 2fe848cc7, une seconde copie isolée de ce HEAD reçoit uniquement les treize fichiers core P03 et ses cinq exports. Résultat :11 réussites et5 échecs, dont deux incompatibilités de codec et trois fichiers bloqués par le généré MapConnectionDirection. Le diagnostic détaillé établit que ProjectSmartTileCatalog.currentFormatVersion vaut4 au HEAD et7 sur le checkout partagé : le premier message générique de codec ne désignait donc pas uniquement Border. Le propriétaire confirme sept fichiers minimaux SmartTile5–7 (modèle, deux générés, validation et trois tests), distincts de son lot Border. Une qualification temporaire de cet ensemble est préparée avant toute nouvelle décision Git. Reçus /tmp/avelune-p03-qualified-probe.json et /tmp/avelune-p03-qualified-tests.log ; aucun de ces prérequis non autorisés n'est indexé.

Auto-critique : les tests et revues démontrent le contrat sur les sources natives actuelles, pas encore un commit autonome ni un produit d'import. P07 doit produire les vraies frames RGBA depuis les sources canoniques pour le contrôle Border ; P09 doit exposer les sémantiques de transfert, P10/P11 l'UI, P12 les preuves de volume et Player. Aucun File/Flutter/archive n'est ajouté dans core. Après autorisation humaine complémentaire, les prérequis SmartTile sont committés par leur propriétaire et les quinze fichiers propres P03 par notre tâche. L'index est vide après625b94f4f. Les deux lignes Bicycle étrangères du généré Manifest et les espaces de génération restent hors du commit ; seuls les hunks propres aux installations de packs sont indexés.


### Qualification native complémentaire avant commit P03

Le premier périmètre SmartTile de sept fichiers compile et ses62 tests avec P03 passent, mais la revue indépendante retrouve quatre échecs dans trois suites natives existantes : elles attendent encore la sortie v4 et considèrent v5 comme une version future. Six assertions sont donc ajustées dans la copie isolée : deux dans project_smart_tile_catalog_test.dart, deux dans smart_tile_authoring_draft_test.dart et deux seulement dans smart_tile_pattern_test.dart. Les changements de gestes et le formatage étranger de ce dernier ne font pas partie du prérequis. Patch minimal /tmp/p03-smarttile-existing-version-tests.patch ; aucune modification de ces fichiers par notre tâche dans le checkout partagé.

Qualification complète dans la copie HEAD2fe + P03 + dix fichiers/hunks SmartTile + sept lignes enum : dart test test/smart_tiles test/resource_pack_contract_test.dart test/resource_pack_installation_catalog_test.dart test/resource_pack_dependency_graph_test.dart test/resource_pack_publication_test.dart --reporter expanded →00:04 +408 ~1: All tests passed!, exit0. Log /tmp/p03-qualified-smarttile-regression-complete.log. Le premier essai large manquait deux fixtures tools/performance de l'archive limitée à core ; après extraction de leurs versions committées, il ne reste aucun échec. Une première génération filtrée avait aussi supprimé des sorties hors filtre dans cette copie temporaire ; elles ont été restaurées depuis HEAD, puis les seuls overlays propres réappliqués avant qualification. Aucun de ces ajustements d'outillage ne modifie le checkout partagé.

Analyse ciblée des sources/tests P03 et SmartTile ainsi que du généré enum : No issues found!, exit0 ; /tmp/p03-qualified-native-prerequisites-analyze.log. Compilation kernel du barrel public : exit0 ; /tmp/p03-qualified-native-prerequisites-kernel.log. La revue indépendante valide que le correctif enum est exactement le HEAD plus ses sept lignes générées, SHA256 eee8e53eb91eea2fac226e4ec7b3192c52109878fb50a289aa8658a86840d0f3. Elle confirme l'absence de dépendance supplémentaire aux opérations de motifs, au resolver ou à readiness.

La qualification porte sur DTO/codec/validation ; le resolver au HEAD ne consomme pas encore ces propriétés. Aucun rendu ou parcours Player SmartTile7 n'est revendiqué. Yoahn autorise explicitement les prérequis complets : dix fichiers/hunks natifs puis les commits P03/P04. Cet accord remplace le premier chiffrage incomplet à sept fichiers. SmartTile est committé en53b16bfb8 et Border reste indépendant ; le correctif enum identique est déjà fourni par9605357ad, sans nouveau commit à créer.

### Preuves d'exécution du lot P04 — implémentation vérifiée

Audit initial : réutilisation du lecteur ZIP random access, de l'inspecteur GLB, des domaines de hash P03 et des limites existantes de présentation. Le cache de stage appartient au service/session autorisé ; il ne sert pas de stockage historique durable. Le projet n'est jamais modifié par l'inspection. Les contrats publics de ports sont exportés depuis map_authoring, sans couplage aux internes de l'éditeur.

Inventaire P04, quinze fichiers gelés dans /tmp/p04_cancel_failure_frozen_files.json :

| Fichier | Zone et raison |
|---|---|
| packages/map_distribution/lib/src/resource_pack_security_policy.dart |144 lignes ; plafonds signés v1 et sous-limites de qualification, aucune hausse par configuration |
| packages/map_distribution/lib/src/resource_pack_manifest_codec.dart |123 lignes ; JSON strict, taille/profondeur/nœuds, manifeste canonique et empreinte d'arbre |
| packages/map_distribution/lib/src/resource_pack_inspector.dart |837 lignes ; structure/inventaire, graphe fermé, capacités, native validation, provenances, médias et pixels publiés |
| packages/map_distribution/lib/src/static_png_validation.dart |245 lignes ; profil PNG statique, chunks/CRC, IHDR unique, dimensions et inflation bornée exacte avant décodage |
| packages/map_distribution/lib/src/random_access_zip_structure_reader.dart |Extension ciblée du validateur de noms, plafonds d'entrées et lecture par chunks ; comportement par défaut conservé pour les autres profils |
| packages/map_distribution/lib/src/glb_model3d_inspector.dart |Profil requireStaticTextures optionnel, false par défaut ; précontrôle PNG commun uniquement pour le profil pack activé |
| packages/map_distribution/lib/map_distribution.dart |Trois exports publics des contrats du pack |
| packages/map_distribution/test/resource_pack_manifest_codec_test.dart |327 lignes ; canonicalisation, versions, bornes, types et champs inconnus |
| packages/map_distribution/test/resource_pack_inspector_test.dart |1456 lignes ; archives invalides, SHA/CRC, fermeture native, PNG/GLB, références et quotas |
| packages/map_distribution/test/static_png_validation_test.dart |214 lignes ;37 cas couleurs/profondeurs/Adam7, flux zlib, fenêtre LZ77 et corruption |
| packages/map_authoring/lib/src/ports/file_backed_payload_store.dart |68 lignes ; scope, handle, lease et source autorisée sans chemin public |
| packages/map_authoring/lib/src/infrastructure/local_resource_pack_store.dart |705 lignes ; stage chunké, double observation, budgets concurrentiels, leases/readers/workers, expiration et fermeture possédée |
| packages/map_authoring/lib/map_authoring_api.dart |Export du port canonique |
| packages/map_authoring/lib/map_authoring_local.dart |Export de l'implémentation locale |
| packages/map_authoring/test/ports/file_backed_payload_store_test.dart |774 lignes ; source/session, intégrité, quotas, racines/liens, lecteurs, workers et fermeture sur disque |

Décisions et correctifs issus des revues :

- Les ancêtres du cache et leur résolution canonique sont vérifiés ; un lien vers le projet est refusé. La sélection native autorise seulement le fichier exact, pas ses voisins.
- Les frames sont validées dans leurs unités natives ; la grille de secours des personnages suit les dimensions réellement appliquées par le runtime. Une imageCollection autonome est acceptée, une combinaison raster rect-only nécessitant une sémantique absente est refusée explicitement.
- Une en-tête PNG seule ne suffit pas. Le profil statique refuse APNG, puis valide/décode le média réel. Les textures PNG des GLB passent le même contrôle, tandis que le profil des jeux conserve son comportement par défaut.
- Une inflation dépassant les scanlines annoncées est refusée avant le décodeur image : sortie zlib bornée, fenêtre32Kio et contrôle Adler/fin exacte, y compris les sept passes Adam7. Aucun tampon complet de pixels gonflés n'est conservé par ce précontrôle.
- close ferme l'admission, annule les copies, attend lecteurs et workers, puis efface uniquement le répertoire privé de l'instance. La réentrance A→B→A est refusée avant changement d'état avec une clé Zone propre à chaque store. Un finally interne libère la réservation même si StreamIterator.cancel échoue, sans masquer cette erreur.
- Les preuves de provenance sont déclarées seulement si elles couvrent toutes les racines ; aucune qualification de contenu n'est inventée. Les index évitent les scans imbriqués du catalogue et des bindings.

Commandes et preuves finales :

- Depuis packages/map_distribution, dart test --reporter expanded →00:18 +351: All tests passed!, exit0 ; /tmp/p04_quality_distribution_full.log. Les changements ultérieurs sont limités aux deux fichiers de stockage authoring, les treize autres SHA sont identiques.
- dart analyze lib/src/resource_pack_security_policy.dart lib/src/resource_pack_manifest_codec.dart lib/src/resource_pack_inspector.dart lib/src/random_access_zip_structure_reader.dart lib/src/glb_model3d_inspector.dart lib/src/static_png_validation.dart test/resource_pack_manifest_codec_test.dart test/resource_pack_inspector_test.dart test/static_png_validation_test.dart → No issues found!, exit0 ; /tmp/p04_quality_distribution_analyze.log.
- dart analyze complet distribution → exit0, une information unnecessary_library_name dans le barrel inchangé sur cette ligne ; /tmp/p04_quality_distribution_analyze_full.log.
- Depuis packages/map_authoring, dart test test/ports/file_backed_payload_store_test.dart test/ports/artifact_staging_lifetime_test.dart test/tooling/jsonl_artifact_staging_test.dart →00:01 +35: All tests passed!, exit0 ; /tmp/p04_cancel_failure_authoring_final.log.
- dart analyze complet authoring après correction nestedZone → No issues found!, exit0 ; /tmp/p04_nested_close_authoring_analyze.log. Après le dernier delta finally, dart analyze lib/src/infrastructure/local_resource_pack_store.dart test/ports/file_backed_payload_store_test.dart → No issues found!, exit0 ; /tmp/p04_cancel_failure_authoring_analyze.log.
- dart compile exe bin/pokemap_authoring.dart -o /tmp/p04_authoring_validation → Generated: /tmp/p04_authoring_validation, exit0 ; /tmp/p04_cancel_failure_authoring_aot.log. Compilation kernel du barrel distribution via /tmp/p04_distribution_compile.dart → exit0 ; /tmp/p04_quality_distribution_kernel.log.
- Revue conformité : huit scénarios de fermeture relancés, tous verts ; reproduction indépendante nestedZone refusée avec resource_pack.close_reentrant. Avis favorable. Le dernier delta de nettoyage est également relu par la qualité et couvert par les mêmes huit cas.
- Revue qualité finale : helper PNG37pass, annulation défaillante1pass, fermeture8pass ; /tmp/p04_final_quality_png_test.log, /tmp/p04_final_quality_store_test.log, /tmp/p04_final_quality_shutdown_test.log. Reproduction initiale : budget4/disque4 après close/reopen, bombe PNG rejetée. Avis favorable sans finding restant.
- RED conservés avant les correctifs : faux PNG, frames hors atlas, grille de secours, fermeture laissant des fichiers, inflation excédentaire, nestedZone puis fuite de réservation. Les derniers logs /tmp/p04_nested_close_red.log et /tmp/p04_cancel_failure_red.log démontrent les deux symptômes puis leurs GREEN.

Tous les runs possédés sont tracés et leurs descendants terminés ; aucune terminaison d'un processus étranger. Aucun changement de dépendance, CI ou projet utilisateur. Le dernier état global observé compte305 puis306 entrées dirty concurrentes ; index vide et HEAD2fe848cc7. Les quinze sources finales sont sauvegardées avant P05 sous le chemin référencé par /tmp/avelune-p05-before.json ; les hunks étrangers ne sont pas candidats au commit P04. Le garde Markdown est vert, aucun nouveau document créé.

Parité MCP : P04 fournit des ports et une inspection pure sans nouvelle commande produit. Les actions de transfert, leur catalogue découvrable et leurs preuves direct/JSONL/MCP restent explicitement P09 ; aucun support sémantique n'est déduit d'une sauvegarde JSON générique.

Auto-critique et limites : central directory et un média candidat restent matérialisables dans les plafonds annoncés ; aucune mesure RSS n'est revendiquée. Un callback utilisateur actif peut retarder close ; un arrêt dur peut laisser le dossier privé temporaire, sans collecte aveugle des instances voisines. Le décodeur image tiers rejette un minuscule Adam7 dont le précontrôle est valide ; le pack est refusé strictement, sans patch de dépendance. Le CAS durable et l'ouverture lazy sont P05, les jobs/annulations P09, l'import produit P08–P11 et la certification volume/Player P12. Le code P04 est proposé TO REVIEW. Son commit séparé est préparé après625b94f4f, depuis les quinze fichiers figés et non depuis le checkout P05 en cours.

### Baseline et démarrage P05

Avant toute édition P05,62 tests ciblés transactions/recovery/history/snapshot passent en5s dans /tmp/avelune-p05-baseline.log. La suite authoring complète donne04:02 +1855 -40: Some tests failed., exit1 ; /tmp/avelune-p05-authoring-full-baseline.log et seize fichiers listés dans /tmp/avelune-p05-baseline-failure-files.txt. Ils sont prouvés antérieurs à P05, pas tous à P01 ; aucun vert global ni correction étrangère implicite. Le faux positif facade création lié à P03 est corrigé avec sa propre preuve RED/GREEN.

Audit P05 et décisions de la section9 sont transmis à l'unique implémenteur après avis favorables P04. Un snapshot des2597 sources/tests/configurations de map_authoring, map_editor et converter est pris avant cette refonte : /tmp/avelune-p05-before.json. Il permet d'isoler les futurs deltas P05 des modifications étrangères déjà présentes. Aucun nouveau Markdown ni changement Git de branche n'est nécessaire.


### Qualification de livraison P03/P04 et arbitrage exécuté

Yoahn a confirmé les deux demandes Git, dont la précision complète à dix fichiers/hunks SmartTile. Le propriétaire livre53b16bfb819781dcb1d1d561eea46960c5574c08 :361 tests SmartTile passent,1 ignoré, analyse ciblée sans issue dans sa copie isolée. Le correctif enum indépendant est déjà dans9605357ad, strictement identique au SHA du généré qualifié. Aucun doublon de commit.

Avant625b94f4f, dart test des quatre suites P03 est relancé sur le checkout :00:00 +47: All tests passed!, exit0 ; /tmp/p03-precommit-core-final.log. Façade création :1test passé et analyse ciblée No issues found!, /tmp/p03-creation-facade-final.log et /tmp/p03-creation-facade-final-analyze.log. Douze fichiers sont indexés entiers ; les deux générés Manifest et le barrel sont indexés depuis leurs seuls hunks propres. Contrôle de l'inventaire exact15fichiers et diff-check avant/après commit ; reçu /tmp/p03-commit-receipt.json, index vide. Aucun fichier P05 ni hunk Bicycle étranger.

Qualification P04 autonome dans une copie HEAD9605357ad + prérequis SmartTile autorisés + seuls fichiers P03/P04, sans aucun overlay P05 : /tmp/avelune-p04-qualified-probe.json. Résolution offline seulement dans cette copie. Depuis map_distribution, dart test --reporter expanded →00:15 +350: All tests passed!, exit0 ; /tmp/p04-qualified-distribution-final.log. L'écart avec les351 tests partagés est exactement le test étranger ajouté à game_package_spatial_test.dart sur les chemins animés natifs, absent de ce patch isolé et hors commit P04.

Depuis map_authoring, dart test test/ports/file_backed_payload_store_test.dart test/ports/artifact_staging_lifetime_test.dart test/tooling/jsonl_artifact_staging_test.dart test/workspace/project_creation_facade_test.dart --reporter expanded →00:03 +36: All tests passed!, exit0 ; /tmp/p04-qualified-authoring-final.log. Les36 comprennent les35 du groupe P04 et le test facade P03. Analyses ciblées des deux packages : No issues found!, exit0 ; /tmp/p04-qualified-distribution-analyze.log et /tmp/p04-qualified-authoring-analyze.log. dart compile exe bin/pokemap_authoring.dart -o /tmp/p04-qualified-authoring → Generated: /tmp/p04-qualified-authoring, exit0 ; /tmp/p04-qualified-authoring-aot.log. Processus possédés terminés, aucun reliquat.

P04 est indexé depuis sa copie figée antérieure à P05. Les éventuels exports P05 ajoutés aux barrels partagés ne sont pas absorbés. Le plan consolidé est joint au commit P04 pour consigner les preuves actuelles des deux lots et les audits préparatoires ; les sources P05 restent en cours, non indexées. L'état global reste partagé et sale, sans revendication de vert global authoring ou de certification massive.
