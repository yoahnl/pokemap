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

- [x] Écrire un test montrant qu'un payload stored présent est reconnu comme présent, y compris dans le calcul destructif.
- [x] Ajouter les deux variantes et les leases ; les handles ne sont jamais résolus depuis un chemin fourni par le client. Les références du snapshot partagé survivent au rebind de nouveaux handles, sans dépendre d'une session expirée. Les empreintes resourceRevision restent cadrées par chaque storageKey ; un blob CAS et son alias logique partagent des octets, pas une révision de ressource.
- [x] Implémenter stage/verify/promotion/hash par chunks ; même empreinte que la fonction inline pour0,1,1Mio et plusieurs chunks. Remplacer aussi les relectures intégrales dans readResourceRevision et lors de la vérification du temporaire avant promote ; un stage stream suivi d'un contrôle CAS intégral ne satisfait pas la borne mémoire.
- [x] Garder les petits JSON inline ; adapter les consommateurs génériques à présence/empreinte/flux.
- [x] Adapter le recorder et le blob store d'historique, y compris contains ; aucun chargement intégral caché via get.
- [x] Adapter undo/redo/revert et recovery : reconstruction d'une liste de références, pas de tous les octets.
- [x] Adapter le snapshot courant, ses projections et son cache pour les médias managés ; mêmes fingerprints cold/warm et mêmes refus de corruption. Le binding _requireRootMatchesSnapshot vérifie également par flux, sans exiger snapshot.resourceBytes des médias stockés. Un refresh après commit conserve le reçu durable et libère les références possédées sans annoncer un faux échec de publication. Régressions : duplication décor, validation atlas, remplacement/suppression modèle, nouvelle session et publication Presentation après chargement lazy.
- [x] Vérifier que l'ouverture après import ne remplit pas resourceByteLength de toute la bibliothèque binaire.
- [x] Tester lease expiré/corrompu, fichier externe modifié, stage supprimé, fichier logique et historique indépendants ; ne pas utiliser de hardlink vers un média modifiable.
- [x] Contrôler tous les consommateurs de beforeBytes/afterBytes et resourceBytes par recherche ; les producteurs inline n'ont pas à changer si leurs contrats restent valides. Couvrir requireResourceSourceBytes, duplication de décor, _atlasImageState et les projections de suppression/remplacement model3d qui clonent les sources. Un accès stored ne doit jamais retourner null en prétendant que le média n'existe pas.
- [x] Exécuter :

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

- [x] Ajouter un mode de checkpoint interne phaseOnly ; le client ne choisit pas ce mode dans les paramètres.
- [x] Conserver l'intention complète et le reçu complet ; progression séparée et bornée.
- [x] Injecter un crash avant/après promotion d'un fichier mais avant checkpoint ; recovery reconnaît before/after et ne duplique pas les changements.
- [x] Tester les compteurs de journal pour100/1000/10000 changements sur apply, resume et compensate ; aucune boucle de réécriture complète par fichier, y compris _checkpointEntry lors de recovery.
- [x] Ajouter la politique bulk d'action/version ; vérifier n≤20000 sorties logiques, blobs≤n, métadonnées≤2 et touched≤2n+2≤40002 ; le quota ZIP reste indépendant.
- [x] Tester l'absence d'exemption pour toute action ordinaire, faux champ client, faux actionId et fausse origine d'historique.
- [x] Appliquer le même budget uniquement aux undo/redo/revert d'un import certifié ; historique ordinaire toujours limité normalement. Tester import>500changements → undo → redo → reconstruction du service → recovery.
- [x] Projeter plan/résultat/reçu vers des résumés et références paginées ; garder la vérité interne intégrale. AuthoringMutationHistoryResult.toJson et une page d'une seule entrée bulk sont soumis au même plafond. Les codecs AuthoringReceipt/journal et le hash des tokens de confirmation continuent à vérifier le diff intégral, jamais une projection compacte.
- [x] Tester que chaque réponse de page reste≤256Kio et que la reconstruction des pages et des payloadRefs retrouve exactement le diff interne, sans répétition/perte. Une entrée dont before/after est un catalogue32Mio est projetée en descriptor payloadRef/rawSha256/resourceRevision/byteLength, jamais inline. Le contenu reste téléchargeable par chunks autorisés ; aucun curseur vide infini quand une seule ligne dépasse le quota.
- [x] Exécuter :

~~~bash
cd packages/map_authoring
dart test test/transactions/bulk_transaction_checkpoint_test.dart test/security/resource_pack_bulk_authorization_test.dart test/api/resource_pack_compact_result_test.dart test/security/authorization_policy_test.dart test/transactions/idempotency_contract_test.dart test/history/undo_redo_contract_test.dart
dart analyze
~~~

**Gate :** import et annulation historique volumineux restent autorisés dans leur portée vérifiée ; aucune action étrangère ne gagne un budget supérieur.

**Audit préparatoire P06 :** les réécritures quadratiques sont présentes dans journaled_transaction et dans _checkpointEntry de recovery, même lorsqu'une révision est déjà after/before. Les deux chemins doivent utiliser le profil phaseOnly sans reconstruire toutes les entrées à chaque fichier. La provenance bulk est un contrat interne dédié, lié au projet, plan/opération, action/version, inventaire final et hash intégral ; elle n'est jamais déduite de request.extensions, de receipt.actionId ou d'un reçu client. P08 émet la capacité seulement après préparation canonique gelée ; P06 définit et teste ce contrat interne. Après reconstruction, journal strict et historique canonique hash-chain font foi, puis le certificat est revalidé contre leurs données. La menace couverte est l'usurpation par client API ; aucun HMAC, keystore ni protection contre la réécriture directe des fichiers privés par un attaquant filesystem n'est ajouté. Les payloadRefs/projections bornées relèvent du port canonique P06, leurs verbes/jobs de transport de P09.

**Arbitrages pendant P06 :** la projection est préparée de façon asynchrone avant la sérialisation synchrone des DTO. Elle appartient à la session et au projet, sans dépendre des leases du plan déjà libéré. Un échec de projection après reçu durable conserve le statut appliqué, les identités et le résumé borné avec un diagnostic distinct de `snapshot.refresh_unavailable` ; il ne transforme pas le commit en exception ambiguë. Le journal et l'historique passent explicitement au schéma privé2, sans lecteur de compatibilité pré-1.0. L'autre chantier terrain a été informé de cette transition et de la limite des workers figés.

Le contrat P04 `withSource` vérifie tout le stage à chaque ouverture : lire256 blocs d'un payload32Mio aurait relu8Gio. P06 conserve ce contrat et représente ses gros payloads de projection par des segments possédés de128Kio au plus, dans le même store P04. Le descripteur public garde le SHA brut, la révision et la taille du JSON intégral ; sa table de segments reste privée et opaque. Une lecture publique touche au plus deux segments, avec leurs vérifications existantes ; rollback et fermeture libèrent toutes leurs leases. Le test de reconstruction32Mio conserve son délai standard et mesure les octets lus au lieu de masquer le coût par un timeout relevé. Cette décision n'est pas encore une preuve d'implémentation ni une qualification de volume P12.

### P07 — Export canonique déterministe

**Créer :**

- packages/map_authoring/lib/src/domains/assets/resource_pack_projection.dart
- packages/map_authoring/lib/src/domains/maps/canonical_border_ground_composer.dart
- packages/map_distribution/lib/src/resource_pack_builder.dart
- packages/map_authoring/test/domains/assets/resource_pack_export_test.dart
- packages/map_distribution/test/resource_pack_builder_test.dart

**Modifier si nécessaire pour réutilisation canonique :** ResourcePackReferenceVisitor dans resource_pack_dependency_graph.dart, sans modifier rétroactivement le lot P03 ; border_smart_tile_ground_snapshot_service.dart dans map_editor délègue au composeur headless partagé, avec sa suite existante de composition/animation. Aucun import de map_editor dans authoring.

- [x] Écrire une fixture2D avec deux décors partageant un atlas et une fixture3D avec GLB embarqué, terrain, bordure et environnement.
- [x] Ajouter les personnages avec portraits/animations personnalisées et le cas motif indépendant.
- [x] Extraire une sélection et sa fermeture sortante ; rendre visibles les supports automatiques.
- [x] Fermer d'abord les seules racines natives sélectionnées, puis construire le catalogue portable strict ; un Border privé/non publié non sélectionné ne doit pas bloquer une racine exportable.
- [x] Normaliser explicitement la copie portable des champs d'organisation non portables, sans modifier la source.
- [x] Réécrire les identités typées, catégories, familles, groupes de connexion et supports ; ne pas préfixer aveuglément les IDs de snapshots content-addressed.
- [x] Prouver les pixels Border depuis les vraies sources avant puis après remappage ; conserver le hash RGBA et recalculer assetFingerprint lorsque ID/chemin changent. Si les candidats pondérés remappés ne reproduisent plus la publication, refuser explicitement, sans nouveau format RNG ni copie du snapshot comme preuve de lui-même.
- [x] Construire un ZIP vers sink avec offsets/CRC/tailles connus ; tri UTF-8, timestamps et attributs fixes. Le writer peut lire deux fois un fichier pour déterminer ses métadonnées, sans en retenir tous les octets.
- [x] Réinspecter l'archive finale ; deux exports de la même révision et mêmes métadonnées donnent exactement les mêmes octets.
- [x] Modifier une source pendant l'export : résultat refusé, aucun pack publié comme valide.
- [x] Exécuter :

~~~bash
cd packages/map_distribution
dart test test/resource_pack_builder_test.dart test/resource_pack_inspector_test.dart test/game_package_builder_test.dart
cd ../map_authoring
dart test test/domains/assets/resource_pack_export_test.dart test/domains/distribution/resource_library_export_test.dart
dart analyze
~~~

**Gate :** source projet inchangée, archive autonome et roundtrip sémantique des sept kinds/supports.

**Audit préparatoire P07 :** le ZIP existant et GamePackageBuilder matérialisent toute l'archive ; réutiliser leur profil déterministe STORE/UTF-8/attributs fixes mais écrire vers sink avec backpressure et deux lectures vérifiées, sans dépendance de distribution vers AuthoringPayload. Le composeur de sols Border est actuellement réservé à l'éditeur : extraire résolution des vingt rôles, timeline et transformations vers authoring avec callback de lecture PNG autorisée, conserver l'IO racine/chemin dans l'adaptateur éditeur. Utiliser ProjectTilesetVisualResolver pour les marges/gouttières ; une variante non reproductible doit être refusée clairement. Un SmartTileModel3dSource servant à produire le snapshot de sol2D est refusé en v1 faute de renderer3D headless ; cela ne retire pas le support des modèles GLB du pack. Les médias identiques partagent leur blob ZIP tout en conservant leurs bindings/chemins natifs propres.

**Arbitrages pendant P07 :** conserver le contrat de rétention P04 : libérer une lease ne supprime pas immédiatement les octets non retenus ; TTL/collectExpired/close les collectent. Sur refus ou révision périmée, aucun résultat ni lease active ne subsiste, le fichier de construction ZIP privé est supprimé immédiatement, mais le cache peut rester occupé jusqu'à sa collecte et retourner cache_full. Aucun nouveau port discard ni modification P04 n'est justifié. Pour les primitives Border, réutiliser CanonicalBorderSnapshotCompiler et vérifier l'égalité exacte des métriques remappées ; un hash simplement différent de l'ancien ne constitue pas cette preuve. Les neuf tests existants du service éditeur passent après délégation au composeur partagé (`/tmp/p07-editor-ground.log`, runner83174,5descendants, aucun résidu). Cette preuve ciblée ne qualifie pas encore l'export complet ni un parcours natif Studio.

### P08 — Préparation et installation additive

**Créer :**

- packages/map_authoring/lib/src/domains/assets/resource_pack_import_preparer.dart
- packages/map_authoring/lib/src/domains/assets/resource_pack_actions.dart
- packages/map_authoring/test/domains/assets/resource_pack_actions_test.dart
- packages/map_authoring/test/domains/assets/resource_pack_transaction_test.dart
- packages/map_authoring/test/domains/assets/resource_pack_reimport_test.dart

**Modifier :** application/map_mutation_dispatcher.dart, registre d'actions, API locale de composition, codecs du reçu d'installation et gardes pertinentes.

- [x] Construire un preparedImportHandle lié à archiveHash, sélection/révision, projet/révision, mappings, contraintes et inventaire exact.
- [x] Allouer tous les IDs et chemins avant le plan. Pour model3d : reconstruire assets/models3d/<nouvel-id>.glb et respecter le regex natif des IDs.
- [x] Remapper toutes les références et vérifier la fermeture après projection dans le manifeste cible.
- [x] Préserver la désignation isWorldTileset de la cible ; aucune bibliothèque importée ne choisit le tileset monde du projet.
- [x] Produire un changeset unique : définitions, classification, AssetCatalog, blobs/aliases, documents de licence et reçu d'installation.
- [x] Enregistrer resource_pack.import avec paramètre preparedImportHandle ; requête courte et projection compacte.
- [x] Protéger sources locales modifiées, identités occupées et dépendances déjà installées mais éditées.
- [x] Tester chaque ligne de la table3.3, y compris suppression locale suivie d'un réimport qui ne recrée pas silencieusement le travail supprimé.
- [x] Tester qu'un conflit preserveProject reste non applicable, puis que le choix explicite importCopy produit une autre fermeture sans modifier la cible existante.
- [x] Tester dry-run sans écriture native, plan périmé, repeated operationId, reconstruction du service puis réimport, undo/redo et fermeture/réouverture.
- [x] Tester crash/disque plein/fichier ciblé modifié pendant promotion : reçu durable ou recoveryRequired, jamais faux succès.
- [x] Vérifier que les cartes, scènes, dialogues, paramètres projet et données de progression restent identiques.
- [x] Exécuter :

~~~bash
cd packages/map_authoring
dart test test/domains/assets/resource_pack_actions_test.dart test/domains/assets/resource_pack_transaction_test.dart test/domains/assets/resource_pack_reimport_test.dart test/domains/assets/content_addressing_test.dart test/domains/assets/asset_security_test.dart
dart analyze
~~~

**Gate :** installation native autonome, ID/references/collisions préservés, aucune mise à jour destructive cachée.

**Audit préparatoire P08 :** exclure uniquement `resourcePackInstallations` des scans de références vivantes (`deriveAssetUsages`, `requireResourceAssetUnused`, `resourceDefinitionUsageDocuments`) : les mappings restent une trace historique et ne deviennent pas des clés étrangères. Le replay d'une opération déjà appliquée doit pouvoir consulter le reçu canonique durable avant la résolution du plan éphémère, en conservant les vérifications d'acteur, projet, action/version, plan/opération et signature ; aucun nouveau commit sans plan. Pour étendre une sélection, comparer les seules dépendances historiques requises avec leurs définitions attendues depuis l'archive certifiée et les mappings existants ; cela couvre les supports sans ajouter systématiquement un champ d'empreinte au DTO. Le même ensemble déjà installé retourne d'abord `alreadyInstalled`, y compris après suppression locale. Les groupes de connexion restent globaux à l'installation ; seul `tilesetElementGroup` possède un owner tileset. Réutiliser le CAS après certification des octets et de leur digest cadré, distinct du SHA brut. Assembler une seule projection additive au lieu de boucler sur `asset.import_batch`, puis passer les gardes et figer tous les fichiers, licences et Border générés avant le certificat P06. Les handles préparés possèdent et libèrent leurs sources indépendamment des futurs jobs P09. Audit statique uniquement : aucun scénario dynamique P08 ni contrat P05 final n'est encore certifié.

**Raccord P08 revu après P06 committé :** injecter un résolveur interne de preparedImportHandle dans la composition du dispatcher ; le handler produit un seul draft et passe la garde normale de bibliothèque, sans catalogue/inventaire/chemin client. IDs et sélection sont figés avant le plan, indépendamment de `generateId` du planner. Chaque plan obtient de nouveaux wrappers stored et des leases purpose:plan ; partager le même objet AuthoringPayload entre préparateur et plans serait incorrect, car sa release désarme ensuite ses lectures. Extraire les entrées ZIP sélectionnées dans un callback `withSource` possédé, pas une ouverture/re-hash complet de l'archive par entrée. Certifier le plan final seulement quand operationId est connu, avant SecureExecutor.apply ; lors d'un retry vivant, vérifier la capacité déjà liée plutôt que la binder une seconde fois. Conserver la seconde observation des dépendances sous verrou.

Le journal seul ne permet pas le replay après succès normal : la transaction le supprime avec les stages. Le ledger conserve déjà scope, payloadFingerprint, operationId, statut et offsets dans `_cachedIndexes`. Ajouter un lookup secondaire interne acteur/projet/opération sur cet index, sans nouvelle persistance ni scan des gros reçus ; un opId ambigu sous plusieurs scopes est refusé. Matérialiser le seul record, vérifier completed, acteur/projet/plan/op/action-version, comparer son reçu à celui de l'historique canonique hash-chain et conserver autorisation/audit à zéro ressource touchée. Aucun nouveau payload client n'est fourni à ce replay : son fingerprint vient de la source canonique privée ; aucun nouveau champ durable ou contrat client obligatoire n'est justifié. Pending retourne recoveryRequired. Le préflight précède resolveActive ; absence de completed exige toujours un plan actif strict, jamais un plan persisté ou une nouvelle publication implicite. La rétention du ledger est30jours : après expiration, replay indisponible et aucun nouveau commit sans plan. Le certificat d'import garde n effectif exact ; l'historique hérite logicalOutputLimit sans le recalculer sur ses sous-ensembles. Tests spécifiques prévus : succès sans journal puis detach/reconstruction/replay, ambiguïté, rétention, incohérence ledger/historique, ownership multi-plans et refus des faux contextes. Cette passe est statique, sans test/app/build ; jobs et barrière d'annulation restent P09.

**Complément de projection P08 depuis le gel P07 :** ResourcePackReferenceVisitor inventorie les dépendances mais ne remappe pas ; validateResourcePackNativeJson valide les formes sans fournir de remapper. Après commit P07, réutiliser les réécritures typées de `_Projection.reference`, `_frames`, `_properties` et `_smart` par une extraction mécanique ciblée dans authoring, avec callbacks de mappings déjà alloués. L'allocation et la normalisation export restent propres à P07 ; aucun AST/registre universel ni remplacement textuel. De même, partager la préparation source Border (`_borderSources`/`_prepareElement`) et le compilateur canonique plutôt que dupliquer marges/gouttières, métriques et preuve RGBA. Ajouter une non-régression export avant ce raccord. ResourcePackCatalog reste le DTO portable : il interdit les drafts et le scope carte, donc ne valide pas à lui seul le manifeste natif final enrichi.

La projection native attendue, pure et déterministe depuis archive+mappings, précède la fusion additive et sert aussi à comparer les seules dépendances historiques nécessaires lors d'une extension. Préserver IDs numériques de tile/objets et object_reference ; remapper pages imageCollection/pageId et propriétés asset_reference ; reconstruire les drafts après remapping. Conserver snapshot content-addressed et chemins `assets/borders/snapshots/<hash>/frame_XXXX.png`, mais recalculer assetFingerprint dépendant des IDs/chemins sources et recontrôler le RNG pondéré cible. Garder un AssetRecord par chemin logique même lorsque le CAS est partagé. Vérifier les chemins physiques occupés non enregistrés : probeResource/listFiles distinguent missing et inventoryUnavailable, ce dernier n'étant pas une preuve d'absence. Utiliser resourceMatchesArtifact/captureResourcePayload en flux et encodeResourceInformationDocument pour conserver les champs bruts inchangés ; replaceResourceSourceReferences réécrit des propriétaires existants et ne constitue pas le remapper additif. Aucun fingerprint supplémentaire de supports n'est requis : comparer leur projection canonique attendue. Cette lecture indépendante ne prouve encore aucun apply P08.

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

**Audit préparatoire P09 :** réutiliser les DTO `AuthoringJob*` plutôt qu'un framework supplémentaire. Leur validateur dotted-name rejette actuellement les underscores : étendre précisément et tester la convention signée `resource_pack.*`. `start` doit enregistrer/planifier et rendre la main immédiatement ; la CLI attend chaque ligne et son timeout ne vaut pas annulation. Réutiliser l'isolate P04 pour le CPU et prouver un poll pendant un travail suspendu. La course cancel/réservation exige une barrière canonique atomique juste avant `_idempotency.execute`, avec contrôle coopératif au staging ; le hook de test afterReservation ne constitue pas ce port. Après réservation, exposer `cancelAllowed=false` et le refus signé, puis reçu appliqué ou recoveryRequired. Lier les handles à la session, l'identité canonique du projet et leurs révisions ; le verrou mutateur utilise cette identité, pas un handle d'ouverture isolé. Consommer le replay durable P08 et réconcilier la recovery bulk avant de réautoriser l'écriture après réouverture. Borner les événements/inspections/previews à200lignes et256Kio, enveloppe et base64 compris ; payloadRef autorisée par chunks128Kio, sans page vide à curseur immobile. Router les cinq kinds temporaires vers le port de transfert avant tout chargement de snapshot natif ; tester les vraies ressources MCP `resources/read`, pas seulement la présence dans describe/query. L'éditeur reste PARTIAL jusqu'au parcours P10. Audit statique uniquement, aucun transport P09 exécuté.

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

- [x] Injecter les pickers, le port et le contrôleur possédé par la session ; aucun decodeur ZIP dans les widgets.
- [x] Tester annulation picker, inspect invalide et préservation du projet.
- [x] Présenter la sélection virtualisée, les filtres de contexte et les dépendances automatiques.
- [x] Tester « sélectionner tous les résultats » sans sérialiser10000 IDs depuis le widget.
- [x] Préserver les lignes sélectionnées mais masquées ; compter sélection totale et résultats visibles séparément.
- [x] Ajouter conflits et résumé exact ; aucun remplacement de ressource proposé dans la v1.
- [x] Appliquer via l'API canonique et passer le reçu dans le mécanisme existant de reconciliation.
- [x] Bloquer le changement/fermeture de projet pendant finalisation ; une réponse d'une ancienne session ne peut pas s'appliquer à la nouvelle. Tester fermeture avant application avec annulation confirmée, finalisation non interrompue, changement de session refusé et fermeture refusée tant qu'un reçu appliqué attend la réconciliation.
- [x] Tester erreur de refresh après commit : message de succès d'import avec action de relecture, aucun deuxième apply.
- [ ] Tester import/reopen, usage de chaque type, petite fenêtre, zoomtexte et clavier.
- [ ] Exécuter :

~~~bash
cd apps/avelune_studio
flutter test --no-pub test/application/resource_pack_transfer_controller_test.dart test/presentation/resource_pack_transfer_dialog_test.dart test/resource_io/resource_pack_import_host_test.dart test/resource_io/resource_pack_cancellation_host_test.dart test/presentation/resource_library_intent_test.dart test/resource_io/resource_library_host_test.dart
flutter analyze --no-pub
~~~

**Gate :** vrai fichier pack → sélection → import → ressources natives réouvertes ; aucun tableau mémoire de toutes les vignettes ou de tous les octets.

**Audit préparatoire P10 :** brancher les deux actions dans la liste commune `libraryActions` pour partager la bibliothèque globale et le menu compact Actions, avec port et pickers injectés. Réutiliser les libellés Contexte P02 et les primitives Studio existantes ; le contrôleur de transfert possède sa sélection P09 indépendante de `ResourceLibraryState.reconcileSelection`, qui ne conserve que les lignes visibles. Le busy rejoint `withResourceMutation`, `ResourceNavigation.busy`, les gardes de fermeture et le cycle de session ; après réservation, finalisation non annulable. Réutiliser `pendingReceipt` et `retryReconciliation` pour relire sans apply, mais vérifier les fichiers bulk par flux : le parcours courant de réconciliation appelle readBytes sur chaque fichier et n'est pas un modèle à recopier. Le picker d'archive retourne un chemin autorisé vers le store P04, jamais un tableau de tous les octets. Audit de sources uniquement ; aucune validité visuelle ou native P10 n'est revendiquée.

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

**Audit préparatoire P11 :** la sélection export part de la vue native globale (`forMapPicker=false`), indépendante de la carte active et de son filtre de compatibilité. Ne pas réutiliser `_prepareGameExport`, qui propose une sauvegarde préalable : les brouillons divergents déclenchent la notice de version publiée et le choix retour atelier/annulation, sans sauvegarde ni publication automatique. Réutiliser la forme injectable des pickers natifs et la confirmation de remplacement ; le sink pack reste à implémenter avec temporaire frère, flush puis rename et conservation de l'ancien fichier sur erreur. Les DTO/jobs viennent de P09, sans double contrat Studio. Les six risques de l'audit P10/P11 et les points de branchement sont préparatoires ; les preuves UI, petit écran, clavier, Player et volumes restent P10–P12.

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

**Audit préparatoire P12/P14 :** passe indépendante en lecture seule favorable au découpage, sans preuve d'import avantP07–P11. Séparer les campagnes10000ressources,20000entrées ZIP et volume utile voisin de500Mio : les plafonds JSON/manifeste/supports peuvent limiter leur combinaison. `--archive-bytes` désigne une limite ; le reçu sépare valeur demandée, plafond, taille réellement produite et contrainte limitante, sans padding ZIP. Avec payload524288000, manifeste4194304,20000entrées et chemins77octets au plus, même la borne supérieure large `524288000 + 4194304 + 20000 * (76 + 2 * 77) + 22 = 533082326` reste inférieure à536870912. Le test existant à512Mio passe la seule garde taille avant rejet ZIP ; il ne prouve pas une archive valide de cette taille.

Instrumenter la copie et le hash préalables de `LocalResourcePackStore` en plus des lectures de l'inspecteur ; un décorateur `TransactionFileGateway` doit conserver aussi `StreamingTransactionFileGateway`. Distinguer longueur maximale d'une lecture et octets simultanément possédés, candidats PNG/GLB et catalogue JSON. Mesurer le RSS par processus neuf ou échantillonnage externe ; `ProcessInfo.maxRss` n'est pas un pic propre à une phase. Réutiliser les helpers de benchmark et les journeys natifs existants, sans détourner `ProductCertificationReceipt` réservé aux sorties de jeu ni créer un framework de mesure.

La fixture de classementP02 contient des brouillons : elle ne suffit pas pour l'usageP12. Préparer deux petites scènes originales couvrant ensemble les sept kinds, atlas partagé, publication/édition, portrait/animation personnalisés et modèle texturé animé. Pour l'autonomie, supprimer archive et stages, exporter/installer le jeu, supprimer le projet auteur puis lancer la version installée ; prouver séparément que la trace d'installation n'est pas requise. Le builder `.avelunegame` actuel matérialise encore ses payloads et son archive : les garanties de flux de l'export pack ne lui sont pas attribuées. Aucune suite lente, app, campagne de volume ou preuve GPU/Player n'a été exécutée par cet audit.

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
| P04 | TO REVIEW | Commit280e24c64 ; deux revues favorables ;351 tests distribution/35 authoring partagés,350 distribution/36 authoring dans la copie isolée sansP05 ; analyses/builds vérifiés |
| P05 | TO REVIEW | Commit97cb46796 ; deux revues V2 favorables ;140 tests authoring isolés sans hunks étrangers,2 tests API éditeur isolés, MCP réel2/2 ; limites de suite globale consignées |
| P06 | TO REVIEW | Commit5a6e2556f ; V3 conforme et qualité approuvée ;128 tests isolés, analyse/AOT et MCP2/2 ; limites explicites conservées |
| P07 | TO REVIEW | Commit cfad4b922 ; V3 conforme et qualité approuvée ;32tests authoring,57distribution,9editor, analyse/AOT et MCP2/2 ; limites explicites |
| P08 | TO REVIEW | Commit a7653ee9a ; V2r conforme et qualité approuvée ;89authoring,38sécurité,47core,355distribution,20parité, analyse/AOT/MCP ; réserves explicites |
| P09 | TO REVIEW | Jobs/API/JSONL/MCP qualifiés ; SPEC conforme et qualité approuvée ; commit da27b76c50c43a745a003f2e16fe80a7b9e3620e |
| P10 | REVUE FINALE | V2u gelé, preuves natives2D et3D/save/cold reopen acquises ; SPEC puis qualité avant commit séparé |
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

Auto-critique et limites : central directory et un média candidat restent matérialisables dans les plafonds annoncés ; aucune mesure RSS n'est revendiquée. Un callback utilisateur actif peut retarder close ; un arrêt dur peut laisser le dossier privé temporaire, sans collecte aveugle des instances voisines. Le décodeur image tiers rejette un minuscule Adam7 dont le précontrôle est valide ; le pack est refusé strictement, sans patch de dépendance. Le CAS durable et l'ouverture lazy sont P05, les jobs/annulations P09, l'import produit P08–P11 et la certification volume/Player P12. Le code P04 est proposé TO REVIEW. Son commit séparé280e24c64 est créé après625b94f4f, depuis les quinze fichiers figés et le plan consolidé, sans les éditions P05 en cours.

### Baseline et démarrage P05

Avant toute édition P05,62 tests ciblés transactions/recovery/history/snapshot passent en5s dans /tmp/avelune-p05-baseline.log. La suite authoring complète donne04:02 +1855 -40: Some tests failed., exit1 ; /tmp/avelune-p05-authoring-full-baseline.log et seize fichiers listés dans /tmp/avelune-p05-baseline-failure-files.txt. Ils sont prouvés antérieurs à P05, pas tous à P01 ; aucun vert global ni correction étrangère implicite. Le faux positif facade création lié à P03 est corrigé avec sa propre preuve RED/GREEN.

Audit P05 et décisions de la section9 sont transmis à l'unique implémenteur après avis favorables P04. Un snapshot des2597 sources/tests/configurations de map_authoring, map_editor et converter est pris avant cette refonte : /tmp/avelune-p05-before.json. Il permet d'isoler les futurs deltas P05 des modifications étrangères déjà présentes. Aucun nouveau Markdown ni changement Git de branche n'est nécessaire.


### Qualification de livraison P03/P04 et arbitrage exécuté

Yoahn a confirmé les deux demandes Git, dont la précision complète à dix fichiers/hunks SmartTile. Le propriétaire livre53b16bfb819781dcb1d1d561eea46960c5574c08 :361 tests SmartTile passent,1 ignoré, analyse ciblée sans issue dans sa copie isolée. Le correctif enum indépendant est déjà dans9605357ad, strictement identique au SHA du généré qualifié. Aucun doublon de commit.

Avant625b94f4f, dart test des quatre suites P03 est relancé sur le checkout :00:00 +47: All tests passed!, exit0 ; /tmp/p03-precommit-core-final.log. Façade création :1test passé et analyse ciblée No issues found!, /tmp/p03-creation-facade-final.log et /tmp/p03-creation-facade-final-analyze.log. Douze fichiers sont indexés entiers ; les deux générés Manifest et le barrel sont indexés depuis leurs seuls hunks propres. Contrôle de l'inventaire exact15fichiers et diff-check avant/après commit ; reçu /tmp/p03-commit-receipt.json, index vide. Aucun fichier P05 ni hunk Bicycle étranger.

Qualification P04 autonome dans une copie HEAD9605357ad + prérequis SmartTile autorisés + seuls fichiers P03/P04, sans aucun overlay P05 : /tmp/avelune-p04-qualified-probe.json. Résolution offline seulement dans cette copie. Depuis map_distribution, dart test --reporter expanded →00:15 +350: All tests passed!, exit0 ; /tmp/p04-qualified-distribution-final.log. L'écart avec les351 tests partagés est exactement le test étranger ajouté à game_package_spatial_test.dart sur les chemins animés natifs, absent de ce patch isolé et hors commit P04.

Depuis map_authoring, dart test test/ports/file_backed_payload_store_test.dart test/ports/artifact_staging_lifetime_test.dart test/tooling/jsonl_artifact_staging_test.dart test/workspace/project_creation_facade_test.dart --reporter expanded →00:03 +36: All tests passed!, exit0 ; /tmp/p04-qualified-authoring-final.log. Les36 comprennent les35 du groupe P04 et le test facade P03. Analyses ciblées des deux packages : No issues found!, exit0 ; /tmp/p04-qualified-distribution-analyze.log et /tmp/p04-qualified-authoring-analyze.log. dart compile exe bin/pokemap_authoring.dart -o /tmp/p04-qualified-authoring → Generated: /tmp/p04-qualified-authoring, exit0 ; /tmp/p04-qualified-authoring-aot.log. Processus possédés terminés, aucun reliquat.

P04 est indexé depuis sa copie figée antérieure à P05. Les éventuels exports P05 ajoutés aux barrels partagés ne sont pas absorbés. Le plan consolidé est joint au commit P04 pour consigner les preuves actuelles des deux lots et les audits préparatoires ; les sources P05 restent en cours, non indexées. L'état global reste partagé et sale, sans revendication de vert global authoring ou de certification massive.


### Qualification finale P05 — payloads, snapshots et historique bornés

Périmètre : infrastructure et consommateurs de médias ; aucun job produit, import massif, galerie, migration legacy, CI coûteuse ou changement de projet utilisateur. Audit initial : getters before/after et snapshots retenaient les binaires ; le recorder devait rendre ses images durables avant cleanup ; un cache partagé ne pouvait pas posséder un accès de première session. État initial propre au lot : main/2fe848cc7, index vide,306 entrées dirty ; sauvegarde2597sources référencée par /tmp/avelune-p05-before.json. Les commits natifs/P03/P04 sont arrivés pendant le lot, sans mélange des hunks.

Implémentation/TDD : payloads inline/stored actifs, données structurées inline, médias natifs lazy vérifiés, captures immuables des seuls préétats nécessaires, stage/promotion/contrôles de révision/historique par flux. Les domaines rawSha256, artifact-content, storageKey et authoring-history-blob restent distincts. Après reçu durable, refresh/adoption/cleanup indisponible donne snapshotRevision=null et snapshot.refresh_unavailable ; aucun faux échec de publication, aucune révision périmée substituée. Les erreurs d’autorisation, promotion, recorder et audit sécurisé ne sont pas absorbées. Le pont éditeur garde son reçu et invalide les anciennes lectures même si le reload échoue.

Passe conformité initiale : NON CONFORME, deux reproductions RED indépendantes (cache réutilisé avec un autre WorkspaceHandleStore ; suppression de personnage lisant ses portraits/clips stored via getter inline). Corrections V2 : cache sans reader/owner/payload de projection, lecteur autorisé courant rattaché après lookup et adoption ; présence via hasResource. Relecture conformité : CONFORME, cross-store RED→GREEN,5tests natifs passés ;80hashes vérifiés sans drift. Critique qualité indépendante : APPROUVÉ,48tests en18s et80hashes identiques entrée/sortie ; aucun finding supplémentaire. L’implémenteur livre avec limites de suite globale, pas un vert général.

Inventaire du candidat :79fichiers techniques plus ce plan consolidé. L’unique adaptation working-only de pokemon_catalog_jsonl_test.dart est dans un test étranger ajouté non committé, absent de HEAD : elle reste préservée dans ce chantier et n’entre pas dans P05. Les deux nouveaux tests editor parity sont recontextualisés avant le premier test HEAD ; deux hunks de formatage dans un test de motifs étranger sont omis. Les hunks antérieurs de converter, Smart Tile et notifier restent hors index.

| Fichier du candidat | Zones, raison et effet |
|---|---|
| `apps/avelune_studio/lib/features/presentations/data/local_presentation_publication.dart` | Vérifier les changements publiés par readResourceRevision en flux plutôt que afterBytes stored. |
| `apps/avelune_studio/lib/features/resources/data/local_resource_lifecycle_preparation.dart` | Lire explicitement le seul média du preview de remplacement, en vérifiant son absence. |
| `packages/avelune_converter_adapters/lib/src/native_project_writer.dart` | Deux comparaisons de révision d’application gardées et lecture async de la seule image logical vérifiée ; autres hunks converter exclus. |
| `packages/map_authoring/lib/map_authoring_api.dart` | Exporter les contrats payload/diagnostic nécessaires aux consommateurs publics. |
| `packages/map_authoring/lib/map_authoring_local.dart` | Exporter les implémentations/capacités locales nécessaires, sans changer la façade de création pure. |
| `packages/map_authoring/lib/src/api/authoring_mutation_contracts.dart` | AuthoringMutationResult.snapshotRevision nullable et AuthoringSnapshotRefreshDiagnostic, sans révision de substitution. |
| `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart` | Binding fort et frontière après reçu : adoption/relecture/nettoyage peuvent produire un diagnostic avec reçu conservé ; les erreurs d’exécuteur restent des erreurs. |
| `packages/map_authoring/lib/src/application/map_mutation_dispatcher.dart` | Planning asynchrone et propriétaire de captures transmis aux actions concernées. |
| `packages/map_authoring/lib/src/domains/assets/asset_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/character_studio_asset_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/element_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/element_definition_management.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/model3d_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/presentation_media_import_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/presentation_preset_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/resource_source_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/resource_source_guards.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/assets/tiled_tileset_import_projection.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/gameplay/character_studio/character_studio_deletion_safety.dart` | Présence des portraits/clips via hasResource ; suppression et candidats de remplacement compatibles avec médias stored. |
| `packages/map_authoring/lib/src/domains/gameplay/pokemon_media_import_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/maps/smart_tile_catalog_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/maps/tiled_map_import_actions.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/domains/narrative/presentation_publication_snapshot.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_authoring/lib/src/history/content_blob_store.dart` | CAS historique durable : put/get/contains/capture par flux, images possédées indépendantes des fichiers logiques. |
| `packages/map_authoring/lib/src/history/history_store.dart` | Recorder : persister les blobs before/after depuis les stages vérifiés avant leur nettoyage. |
| `packages/map_authoring/lib/src/history/revision_revert_service.dart` | Préparation du revert depuis le CAS historique par flux, nettoyage des captures sur échec. |
| `packages/map_authoring/lib/src/history/undo_service.dart` | Préparation/application undo/redo : références historiques capturées sur disque et propriété du plan. |
| `packages/map_authoring/lib/src/ports/project_file_reader.dart` | Port de lecture par flux/descriptors et implémentation locale autorisée. |
| `packages/map_authoring/lib/src/ports/transaction_file_gateway.dart` | Port de payloads et capacité explicite de streaming ; aucun fallback caché en lecture intégrale. |
| `packages/map_authoring/lib/src/references/resource_library_scope_guard.dart` | Accès génériques aux changements sans confondre absence et payload stored. |
| `packages/map_authoring/lib/src/security/secure_mutation_executor.dart` | Préserver les frontières autorisation/audit/recorder et libérer le payload après le reçu durable. |
| `packages/map_authoring/lib/src/support/authoring_fingerprint.dart` | Empreinte cadrée par storageKey calculée par chunks, identique au chemin inline. |
| `packages/map_authoring/lib/src/transactions/action_planner.dart` | Possession des captures pendant le planning, transfert au plan et libération si sa construction échoue. |
| `packages/map_authoring/lib/src/transactions/authoring_payload.dart` | AuthoringPayload inline/stored, vérification par flux et AuthoringPayloadOwner : présence distincte des octets inline, capacité possédée sans chemin client. |
| `packages/map_authoring/lib/src/transactions/authoring_plan.dart` | Propriété des payloads et libération post-application ; mémorisation des erreurs de nettoyage après reçu durable. |
| `packages/map_authoring/lib/src/transactions/batch_executor.dart` | Projection des changements conservant les payloads, sans convertir la fermeture binaire en listes d’octets. |
| `packages/map_authoring/lib/src/transactions/change_set.dart` | AuthoringResourceChange : images before/after sous forme de payloads ; getters inline explicites et calcul destructif par présence. |
| `packages/map_authoring/lib/src/transactions/journaled_transaction.dart` | Staging/recorder fondés sur les payloads ; rendre l’historique durable avant la suppression des stages. |
| `packages/map_authoring/lib/src/transactions/local_authoring_payload.dart` | captureAuthoringPayload/reframeAuthoringPayload : copies temporaires immuables par flux ; IO isolée des contrats purs. |
| `packages/map_authoring/lib/src/transactions/local_transaction_file_gateway.dart` | stagePayload/readResourceRevision/readStagedPayload/promoteStaged : chunks, vérification forte et refus CAS conservés. |
| `packages/map_authoring/lib/src/transactions/plan_store.dart` | Expiration, discard et détachement asynchrones : attendre la libération du propriétaire de chaque plan. |
| `packages/map_authoring/lib/src/transactions/recovery_service.dart` | Reconstruction et comparaison des images staged par références/flux, sans charger tous les fichiers. |
| `packages/map_authoring/lib/src/workspace/project_open_service.dart` | Brancher les capacités de lecture natives au workspace sans capturer un accès de session périmé. |
| `packages/map_authoring/lib/src/workspace/project_snapshot.dart` | Descriptors stored, présence, lecture/capture explicite et rebind du lecteur courant ; octets structurés inline. |
| `packages/map_authoring/lib/src/workspace/project_snapshot_cache.dart` | Cache partagé sans reader/owner/payload de plan ; validation forte des médias et comptage des seuls buffers résidents. |
| `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart` | Ouverture lazy des médias managés, vérification forte CAS/alias, inventaire identique inline/stored ; lecteur courant après lookup et adoption. |
| `packages/map_authoring/lib/src/workspace/project_snapshot_map_projector.dart` | Projection map/project inline conservant les descriptors des médias ; autres changements relus par le loader strict. |
| `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart` | Accès au flux et à l’identité de ressource par le handle actuellement autorisé. |
| `packages/map_authoring/test/domains/assets/character_studio_asset_actions_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_authoring/test/domains/assets/resource_source_api_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_authoring/test/domains/assets/tiled_tileset_import_transaction_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_authoring/test/domains/gameplay/pokemon_media_import_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_authoring/test/domains/maps/tiled_map_import_transaction_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_authoring/test/history/file_backed_history_test.dart` | CAS historique reconstruit, contains vérifié, corruption refusée ; capture indépendante après prune et libération de la source. |
| `packages/map_authoring/test/history/history_retention_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_authoring/test/tooling/jsonl_mutation_worker_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_authoring/test/transactions/action_planner_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_authoring/test/transactions/file_backed_payload_test.dart` | Variantes/présence et empreintes0/1/1Mio/multichunks, sources invalides et release idempotent ; pannes après reçu et propriété du planning. |
| `packages/map_authoring/test/workspace/lazy_asset_snapshot_test.dart` | Deux sessions/stores distincts avec cache partagé, descriptors seuls, map.save adopté puis plan libéré et média encore lisible ; corruption/undo et révisions identiques. |
| `packages/map_authoring/test/workspace/project_snapshot_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` | Reçu appliqué conservé avant reload local ; diagnostic/révision inconnue transmis et sessions de lecture invalidées même après panne de projection. |
| `packages/map_editor/lib/src/application/use_cases/import_pokemon_menu_sprites_use_case.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/features/editor/application/smart_tile_layer_preset_change_gateway.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/features/editor/application/tiled_map_import_service.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | Adoption/réconciliation après application : ne pas accepter null/null comme projection valide ; relire canoniquement si nécessaire. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier_map_connections.dart` | Comparer la révision d’application uniquement lorsqu’elle est connue, avec lecture canonique fraîche. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier_placed_element_placement.dart` | Même garde de révision connue pour la réconciliation de placement. |
| `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_draft_persistence_coordinator.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_pattern_authoring_service.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_preset_deletion_service.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_reconstruction_service.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_source_asset_import_service.dart` | Consommateur ciblé : préserver présence/empreintes et payloads dans les projections ; lire seulement le média demandé ou réconcilier depuis un snapshot frais. |
| `packages/map_editor/lib/src/infrastructure/authoring_api/editor_project_file_reader.dart` | Adaptateur éditeur du port de flux autorisé. |
| `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart` | Deux pannes de reload local après succès canonique, apply et saveMap : reçu/lastAppliedReceipt conservés, projection/révision nulles, disque effectivement modifié. |
| `packages/map_editor/test/smart_tiles_studio/smart_tile_gesture_burst_test.dart` | Parcours notifier réel avec révision inconnue et projection absente : relire, conserver le reçu et le résultat peint, sans assertion null/null. |
| `packages/map_editor/test/smart_tiles_studio/smart_tile_pattern_authoring_service_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `packages/map_editor/test/smart_tiles_studio/smart_tile_publication_service_test.dart` | Tests du contrat concerné : lecture explicite des médias stored, propriété, refus/corruption, historique ou réconciliation ; conservation des assertions métier. |
| `tools/pokemap_mcp/test/mutation_server.test.ts` | Vrai serveur MCP in-memory : applied/null/diagnostic transmis pour apply/undo/recover, reçu conservé, aucun replay automatique. |

Vérification source gelée V2 :140tests authoring passés en25s,149tests consommateurs passés en35s,11tests Studio preview/Presentation passés en8s,Converter NAT-02 passé en5s. Les trois consommateurs externes avaient d’abord reproduit project.resource_inline_unavailable/getter stored en RED. Éditeur élargi :70passés/2échecs de presets ; reproduction exacte des deux échecs avec2427sources préP05 rehashées sans changement,0passé/2échecs revision.conflict. Aucun correctif métier étranger implicite.

Commandes principales depuis map_authoring : `dart test test/transactions/file_backed_payload_test.dart test/history/file_backed_history_test.dart test/workspace/lazy_asset_snapshot_test.dart test/transactions/crash_boundary_test.dart test/transactions/recovery_idempotence_test.dart test/transactions/retained_dependency_window_test.dart test/history/undo_redo_contract_test.dart test/history/history_retention_test.dart test/workspace/project_snapshot_model_buffers_test.dart test/workspace/project_snapshot_fingerprint_cache_test.dart test/transactions/action_planner_test.dart test/transactions/stale_plan_test.dart test/workspace/project_snapshot_test.dart test/domains/gameplay/character_studio_deletion_transaction_test.dart test/domains/gameplay/pokemon_media_import_test.dart test/domains/maps/tiled_map_import_transaction_test.dart` →140passés ; `dart analyze` →No issues found! ; `dart compile exe bin/pokemap_authoring.dart -o /tmp/avelune-p05-pokemap-authoring-v2` →Generated, exit0. Les listes exactes des commandes consommateurs et éditeur et leurs PID figurent dans les entêtes JSON des logs /tmp/avelune-p05-consumers-final.log et /tmp/avelune-p05-editor-final-v2.log ; manifest de preuves /tmp/avelune-p05-verification-v2.json. Analyses ciblées du writer et des deux sources Studio :No issues found! ; analyse editor/lib partagé :seul directedJump étranger, donc pas de vert global annoncé.

Qualification autonome sans hunks étrangers : copie HEAD280e24c64 + candidat P05 dans /tmp/p05-qualified-probe.json. Après ajout des fixtures runtime-host committées manquantes au premier essai de cette copie, la même commande authoring donne `00:23 +140: All tests passed!`, exit0 ; analyse No issues found! ; AOT Generated:/tmp/p05-qualified-authoring-v2. Les deux tests API éditeur de panne après commit donnent `00:00 +2: All tests passed!`, exit0. La compilation du notifier et l’analyse editor/lib de cette copie restent bloquées par28diagnostics Environnement/SmartTile3D déjà présents à HEAD : une seconde copie strictement HEAD reproduit exactement les mêmes28diagnostics (messages/chemins/codes, positions ignorées), aucun nouveau diagnostic P05. Preuve /tmp/p05-editor-baseline-comparison.json ; aucun hunk étranger absorbé pour les masquer. La compilation par tests et l’AOT sont les validations du lot ; aucune nouvelle build desktop complète ni certification Player revendiquée.

MCP : depuis tools/pokemap_mcp, `npm run check` et `npm run build` →exit0. Le test ajouté `MCP preserves committed receipts when snapshot refresh is unavailable` passe : vrai transport in-memory, gateway contrôlée ; les faults canoniques sont prouvés séparément par les tests Dart/JSONL/éditeur. Les deux fichiers stdio originaux resource_library_stdio.test.ts et model3d_source_replace_stdio.test.ts passent2/2 en8.19s avec le binaire canonique V2 fraîchement compilé (SHA00f9e2ded2c42cedef055130a44e506b4efe4c26826c2d2dacf58f8c7129d9fa), via un shim dart propre au processus de test ; aucune source de test ni deadline produit changée. Live describe :418actions/60kinds, classification/query/mutation/reopen réels. Le premier run JIT sous charge avait1passé/1timeout de démarrage describe avant action ; il reste consigné, pas transformé en succès. Métadonnées /tmp/p05-mcp-aot-probe.json et log /tmp/p05-mcp-live-aot-v2.log. Aucune certification PMCP Items manquante d’un autre chantier n’est déclarée close.

Suite authoring complète finale : `04:07 +1889 -46` avant corrections V2, puis `dart test` V2 →1899passés/37échecs. Comparaison par nom unique avec la baseline1855/40 :36cas identiques,4cas baseline disparus,1nouveau cas `JSONL batch plans exclude existing models and unrelated large presets`. Ce cas échoue à apply et émet aussi une erreur de teardown en suite complète ; il passe seul, puis en3et5copies parallèles, sans modification de délai. Le corps de sa réponse failure n’a pas été conservé par l’assertion et n’a pas été reproduit dans les diagnostics temporaires : cause indéterminée, aucun timeout attribué sans preuve. Logs /tmp/avelune-p05-authoring-full-final-v2.log et /tmp/avelune-p05-full-comparison-v2.json. Le lot n’annonce donc ni vert global ni absence de régression sous toute charge.

Tous les runs possédés sont suivis par PID/descendants et clos sans résidu confirmé ni terminaison d’un processus étranger. Diff-check ciblé et garde Markdown verts, aucun nouveau document. Dernier état avant staging :main/280e24c64, index vide,371entrées dirty concurrentes ; ne pas attribuer ce total à P05. Staging prévu depuis le candidat79fichiers qualifié, jamais depuis tous les fichiers modifiés du checkout. Auto-critique : mémoire bornée étayée par les chemins de flux/descriptors et tests, sans mesure RSS ni promesse de durée ; l’échec modèle sous suite complète reste ouvert comme limite connue. P06 garde le journal bulk/autorisation/projections compactes, P07–P11 le produit de transfert, P12 les preuves volume/native/Player, P13 les galeries différées.


### Commit P05 et démarrage P06

P05 est committé en97cb467960f3d1fd8b6413dc6199df799742bab6, parent280e24c64 :79fichiers techniques et ce plan, inventaire exact et hashes d’index vérifiés avant commit, mêmes80chemins vérifiés après. Reçu /tmp/p05-commit-receipt.json ; index vide et299entrées dirty concurrentes préservées, aucun push/rebase. Le ticket Notion agrégé reste DOING, P05 proposé TO REVIEW avec la réserve du test batch3D et les limites de baseline explicites.

P06 démarre après les deux revues favorables P05 avec un seul implémenteur. Sauvegarde préalable de695sources authoring/MCP/plan et état Git dans /tmp/avelune-p06-before.json, HEAD97cb46796, index vide. L’audit et les décisions phaseOnly/provenance interne/limites de sortie/projections sont transmis ; aucune galerie ni extension du backlog bêta. Les nouvelles surfaces spatiales du chantier voisin restent hors périmètre P06.

### Qualification P06 — Journal bulk, sécurité et réponses compactes

P06 V3 est implémenté et qualifié ; conformité et qualité approuvées après correction des deux dépassements de réponses et du revert limité aux blobs. Le lot est proposé TO REVIEW, en attente du commit ciblé autorisé ; le ticket agrégé reste DOING. L'audit initial a identifié les réécritures complètes dans apply et recovery, y compris pour les ressources déjà after/before ; la baseline ciblée donne54tests passés. État initial sauvegardé : main/97cb46796, index vide,303entrées dirty étrangères ou préexistantes. Aucun changement des sources P04, du gateway étranger de retry ctime, de core/render/NB2, des dépendances ou de la CI.

Inventaire technique complet :19fichiers, dont16sources et3tests. Les zones et leur rôle sont les suivants ; tous les chemins sont relatifs au dépôt.

| Fichier | Zones et résultat |
|---|---|
| packages/map_authoring/lib/map_authoring.dart | Exports des types du port de projection canonique |
| packages/map_authoring/lib/map_authoring_api.dart | Même surface disponible aux consommateurs API |
| packages/map_authoring/lib/src/api/authoring_mutation_contracts.dart | Plan/result/history : projection publique distincte du DTO intégral, mesure réelle et fallbacks bornés |
| packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart | Préparation asynchrone, lectures autorisées, reprojection canonique, propriétaire de session et fermeture |
| packages/map_authoring/lib/src/api/authoring_result_projection.dart | Nouveau port/store : pages, segments JSON possédés, chunks, SHA/révision, nettoyage et replis d'indisponibilité |
| packages/map_authoring/lib/src/history/authoring_history.dart | Schéma privé2 strict, certificat distinct et garde de reprise historique |
| packages/map_authoring/lib/src/history/history_store.dart | Recorder du certificat, résolution canonique et vérification inverse/forward/subset |
| packages/map_authoring/lib/src/history/undo_service.dart | Raccord des undo/redo au certificat d'origine vérifié |
| packages/map_authoring/lib/src/history/revision_revert_service.dart | Certificat du seul sous-ensemble physique réellement restauré |
| packages/map_authoring/lib/src/security/authorization_policy.dart | Budget bulk lié au contexte ; permissions et limites ordinaires conservées |
| packages/map_authoring/lib/src/security/secure_mutation_executor.dart | Vérification du plan réel avant autorisation, transmission de la capacité interne |
| packages/map_authoring/lib/src/security/resource_pack_bulk_capability.dart | Nouveau certificat d'inventaire ordonné, rôles/comptages, binding intégral et décodage strict |
| packages/map_authoring/lib/src/transactions/authoring_plan.dart | Binding interne unique, distinct des paramètres client |
| packages/map_authoring/lib/src/transactions/transaction_journal.dart | Schéma2, profil phaseOnly dérivé et validation du certificat/intention/reçu |
| packages/map_authoring/lib/src/transactions/journaled_transaction.dart | Checkpoints par phase pour bulk, checkpoints ordinaires conservés |
| packages/map_authoring/lib/src/transactions/recovery_service.dart | Suppression des copies/écritures par fichier bulk, observations before/after et garde canonique |
| packages/map_authoring/test/transactions/bulk_transaction_checkpoint_test.dart | Compteurs100/1000/10000, crash avant/après promotion, troisième hash et codecs stricts |
| packages/map_authoring/test/security/resource_pack_bulk_authorization_test.dart | Usurpations, limites, fichiers licences/Border, import501→undo→redo→reconstruction→recovery et revert partiel |
| packages/map_authoring/test/api/resource_pack_compact_result_test.dart | Fidélité JSON, pages/chunks, catalogue32Mio, isolation/lifecycle/faults et champs client géants |

Patch V2 `/tmp/avelune-p06-owned-v2.patch`, SHA256 `6764bfdbb4cb7393bd870d88399e2290f749cdd80f0c8f42c4e589ae64467446` ; manifeste `/tmp/avelune-p06-frozen-v2.json`. Exactement trois fichiers diffèrent de V1 : contracts API, projection et test compact. Les19hashes live et figés correspondent ; le candidat isolé `/tmp/p06-commit-candidate-v2.json` reproduit exactement ces19fichiers sur HEAD97cb, sans hunk étranger. `local_transaction_file_gateway.dart` et `transaction_staging_metadata_test.dart` restent explicitement exclus.

Décisions réalisées : n compte les fichiers logiques natifs publiés, licences et sorties Border incluses, pas les définitions regroupées dans project.json. n≤20000, CAS≤n, deux métadonnées exactes et touched≤2n+2≤40002 ; plafonds catalogue/ZIP distincts. La capacité est interne, liée au contexte et au diff intégral ; aucune exemption issue de JSON client. Les limites1Mio/500/60parminute restent normales ; le comportement unmetered de l'acteur local préexistant reste conservé. Les undo/redo/revert dérivent du store canonique ; après reconstruction, la recovery revalide cette origine. Journal et historique schema2 rejettent explicitement le v1, sans migration pré1.0.

Les compteurs indépendants finaux V3 de la copie isolée confirment le coût de journal par phase :

| Fichiers | Apply : écritures / octets | Resume : écritures / octets | Compensate : écritures / octets |
|---:|---:|---:|---:|
|100|5 /346141|6 /411453|6 /411462|
|1000|5 /3409756|6 /4052871|6 /4052880|
|10000|5 /34243771|6 /40700889|6 /40700898|

Le RED initial interrompait la version précédente après13écritures complètes. Le flux bulk conserve l'intention et le reçu complets ; les fichiers réels, les checks CAS et les phases gouvernent la reprise. La progression n'est pas une preuve de commit. Les segments de projection restent possédés par la session, indépendants du plan libéré : téléchargement aligné du JSON32Mio =32Mio vérifiés, lecture non alignée =au plus2segments, sans modifier `withSource` P04. Les réponses préparées sont reconstructibles ; les DTO bruts sans port annoncent explicitement l'indisponibilité plutôt que des références fictives.

La conformité V1 avait reproduit deux défauts réels :100entrées d'historique avec requestId3k produisaient365013octets ; un requestId300k produisait300787octets même dans le fallback après commit. Six nouveaux tests RED reproduisent ces classes de défaut. V2 remesure l'ensemble, projette les champs volumineux en payloadRef si le store fonctionne et fournit un descripteur unavailable borné sinon. Les deux probes originaux inchangés donnent72230octets pour l'historique,1009pour le reçu préparé,861pour le DTO et596pour le résumé. Le probe avec store fermé donne861octets, applied, receiptId/planId/operationId intacts et aucun payloadRef fictif. Un premier probe du reviewer avait inversé l'ordre de fermeture ; son défaut de harness est corrigé séparément. Aucun changement d'AuthoringRequest, du reçu canonique ou du hash de confirmation.

Vérifications techniques exécutées, toutes avec suivi des PID et descendants possédés :

| Passe | Commande et résultat exact |
|---|---|
| Implémentation V1 | Groupe13suites : `00:36 +118: All tests passed!`, exit0 ; log `/tmp/avelune-p06-focused-final.log` |
| Conformité indépendante V1 | Six suites P06/autorisation/idempotence/undo : `00:41 +71: All tests passed!`, exit0 ; deux findings bornes reproduits hors dépôt |
| Qualification isolée du socle | Mêmes13suites sur HEAD+P06 : `00:55 +118: All tests passed!`, exit0 ; `/tmp/p06-qualified-focused-v1.log` |
| Projection V2 et JSONL isolés | `dart test test/api/resource_pack_compact_result_test.dart test/tooling/jsonl_mutation_worker_test.dart` → `00:09 +20: All tests passed!`, exit0 ; `/tmp/p06-qualified-projection-consumers-v2.log` |
| Gardes ordinaires isolées V2 | `dart test test/security/output_redaction_test.dart test/security/audit_log_test.dart test/transactions/action_planner_test.dart test/transactions/stale_plan_test.dart test/transactions/revision_conflict_test.dart` → `00:01 +28: All tests passed!`, exit0 ; `/tmp/p06-qualified-ordinary-guards-v2.log` |
| Parité sur sources complètes | `dart test test/parity/full_authoring_parity_test.dart` → `00:22 +20: All tests passed!`, exit0 ; `/tmp/p06-qualified-parity-v1-complete-source.log` |
| Conformité indépendante V2 | Compact result : `00:10 +13: All tests passed!`, exit0 ; oracles originaux et store fermé GREEN ; verdict CONFORME |
| Analyse isolée V2 | `dart analyze` → `No issues found!`, exit0 ; `/tmp/p06-qualified-analyze-v2.log` |
| Build isolé V2 | `dart compile exe bin/pokemap_authoring.dart -o /tmp/p06-qualified-authoring-v2` → `Generated`, exit0 ; `/tmp/p06-qualified-build-v2.log` |
| Adaptateur MCP isolé | `npm run check` et `npm run build` →exit0 ; `/tmp/p06-mcp-check-v1.log`, `/tmp/p06-mcp-build-v1.log` |
| Stdio MCP réel | Deux fichiers originaux resource_library_stdio/model3d_source_replace :2passés/0échec en4.67s, classifications/query/apply/reopen/undo réels ; `/tmp/p06-mcp-live-v2.log` |

Commande du groupe13suites, depuis packages/map_authoring : `dart test test/transactions/bulk_transaction_checkpoint_test.dart test/security/resource_pack_bulk_authorization_test.dart test/api/resource_pack_compact_result_test.dart test/security/authorization_policy_test.dart test/transactions/idempotency_contract_test.dart test/transactions/crash_boundary_test.dart test/transactions/recovery_idempotence_test.dart test/history/undo_redo_contract_test.dart test/history/file_backed_history_test.dart test/transactions/file_backed_payload_test.dart test/workspace/lazy_asset_snapshot_test.dart test/transactions/retained_dependency_window_test.dart test/history/history_retention_test.dart`. V2 ne modifie que les trois fichiers API/projection/test ; les parcours de journal10000 ne sont pas répétés sans motif. Les entêtes JSON des logs gardent chaque PID et commande exacte ; aucun résidu possédé et aucun processus étranger terminé.

Les premiers essais de la copie isolée manquaient du helper de benchmark puis de sources editor/runtime utilisées comme preuves de parité :30diagnostics de chemin et deux assertions de parité ont échoué. Les fichiers HEAD manquants ont été ajoutés, sans changer le code P06 ni absorber du working tree. Analyse finale sans diagnostic et20cas de parité passent. Le test de parité ciblé passe aussi sur HEAD pur, puis les19hashes du candidat ont été restaurés et vérifiés. Aucun de ces échecs de préparation du probe n'est attribué à P06.

Le MCP de test exécute l'AOT isolé V2 SHA256 `79147bc63cb288c375420b1857b7201dd55001b302f97191a0c7d5c21e13d858` via un shim dart limité au processus enfant ; tests et deadlines inchangés. Catalogue effectivement lu :416actions/60kinds sur le code committé, distinct du catalogue418du checkout partagé P05 qui contenait des actions étrangères. Aucun registre/action P06 n'est ajouté à ce lot. Métadonnées `/tmp/p06-mcp-aot-probe.json`. Les verbes/jobs de pages et payloadRefs relèvent de P09, l'UI de P10 ; ils restent N/A ici et le transfert produit n'est pas annoncé utilisable.

Auto-critique et limites : pas de vert global monorepo ni nouvelle suite complète, les réserves P05 restent ouvertes. Aucune mesure RSS, certification512Mio, build desktop ou preuve Player revendiquée ; ces gates restent P12. Le coût des JSON structurés est distinct de celui des binaires. Les références de projection sont éphémères ; après reconstruction, une nouvelle projection part du reçu canonique. Les données privées v1 d'un projet réel nécessitent une sauvegarde cohérente et une décision de propriétaire avant abandon de l'ancien historique ; aucune mutation de MAIN n'a été réalisée pour P06. Statut avant staging : main/97cb46796, index vide,333entrées concurrentes préservées ; commit envisagé uniquement sur les19sources qualifiées et ce plan, sans push/rebase.

Revue qualité V2 : six suites indépendantes donnent `00:37 +77: All tests passed!`, exit0, sans résidu possédé. Le probe `/tmp/p06-quality-revert-blob-subset.dart` prouve néanmoins qu'un import canonique valide1fichier logique+1blob, suivi d'un revert du seul blob, est accepté comme sous-ensemble exact mais refusé par `certifyHistory` : la garde blobs≤logical est réappliquée au seul sous-ensemble0logique/1blob. Correction demandée : séparer compteurs effectifs et plafond autorisé hérité de l'origine canonique ; préserver les quotas import et les bornes absolues, vérifier aussi l'origine du plafond après reconstruction/recovery. Les inventaires partiels doivent rester exacts, sans fichier logique fictif. Le commit reste suspendu à cette correction et à ses relectures, sans nouvelle demande d'autorisation humaine.


Qualification finale V3 : le finding qualité V2 est fermé. Le certificat schema2 distingue `logicalOutputLimit`, exact sur les sorties réelles de l'import puis hérité de l'origine canonique, et les compteurs effectifs de l'inventaire. Un revert de501blobs conserve0logique/501blobs/touched501 avec limite501. Le garde recovery compare explicitement le plafond du journal au certificat de l'origine avant toute promotion, puis vérifie l'inverse/forward/subset. Le probe disque original inchangé passe `certified` et `SERVICE_CERTIFIED`. Les cas de plafond/provenance altérés refusent sans promotion. Aucun quota d'import ni limite ordinaire n'est relevé.

Le delta V3 depuis V2 contient quatre fichiers : certificat bulk, history_store, test d'autorisation et helper streaming du gateway de test bulk. Manifeste `/tmp/avelune-p06-frozen-v3.json`, patch `/tmp/avelune-p06-owned-v3.patch`, SHA256 `3dcb8950b87332c041a89ee9322e8c06b9c65fe453f1499ba70394d2c9744895`. Le candidat isolé `/tmp/p06-commit-candidate-v3.json` vérifie les19hashes exacts. Le RED du sous-ensemble1/501blobs et le probe disque sont conservés dans `/tmp/avelune-p06-v3-red-subset.log` et `/tmp/avelune-p06-v3-red-oracle-subset.log`.

Validation finale du socle et du nouveau certificat : même commande13suites sur la copie HEAD+seulP06V3 → `01:16 +128: All tests passed!`, exit0, `/tmp/p06-qualified-focused-v3.log`. Cela rafraîchit aussi les octets de journal du tableau ci-dessus après ajout du champ sérialisé. `dart analyze` → `No issues found!`, exit0, `/tmp/p06-qualified-analyze-v3.log`. `dart compile exe bin/pokemap_authoring.dart -o /tmp/p06-qualified-authoring-v3` → `Generated`, exit0, `/tmp/p06-qualified-build-v3.log`. Conformité indépendante :6cas ciblés passés en21s, probe fichier inchangé GREEN, verdict CONFORME. Qualité indépendante :6cas ciblés passés en12s, même probe GREEN, verdict APPROUVÉE. Chaque passe retrouve19/19hashes avant/après et termine sans résidu possédé. Les gardes/projections V2 inchangées gardent leurs preuves20tests API/JSONL et28gardes ordinaires.

MCP final V3 : mêmes deux tests stdio originaux sur le binaire isolé V3,2passés/0échec en6.20s ; `/tmp/p06-mcp-live-v3.log`, métadonnées `/tmp/p06-mcp-aot-probe-v3.json`. SHA256 AOT `7e690792ca7511e4bca0b052a9c4a04b9e1271e0f73558c711a679a6e9e48442` ; catalogue416actions/60kinds effectivement relu, aucune deadline changée. npmcheck/build restent ceux des sources TypeScript inchangées. Aucune session MCP attachée d'un autre chantier n'est prétendue rechargée.

Auto-critique finale V3 : les trois findings reproduits sont corrigés et vérifiés, sans abandon du diff durable ni faux compteur. La séparation comptage effectif/plafond historique ajoute un champ interne nécessaire, pas une nouvelle abstraction. Les limites P05, les transports/jobs P09, l'UI P10 et les preuves de volume/native/Player P12 restent explicitement ouvertes. P13 reste différé. Les19sources techniques et ce plan sont les20chemins autorisés au staging, depuis le candidat qualifié ; le working tree partagé et l'index sont revérifiés juste avant commit.


### Commit P06 et démarrage P07

P06 est committé en5a6e2556fcd1bec89f6edbf8b5cd71ce4b804231, parent97cb467960f3d1fd8b6413dc6199df799742bab6. Les20chemins et leurs contenus d'index ont été vérifiés avant commit, puis les mêmes20chemins et SHA ont été vérifiés dans le commit. Reçu `/tmp/p06-commit-receipt.json` ; index vide,334entrées dirty préexistantes/concurrentes préservées, aucun push/rebase. Notion contient le SHA, les verdicts, les preuves et limites ; statut agrégé DOING, P06 proposé TO REVIEW, DONE réservé à Yoahn.

P07 démarre avec un seul implémenteur après les deux revues favorables P06. Sauvegarde de3738sources core/distribution/authoring/editor/MCP et du plan dans `/tmp/avelune-p07-before.json`, HEAD5a6e2556f, index vide. L'audit P07, ses décisions de remapping/publication/sink et les non-objectifs P08–P12 sont transmis. Les19sources P06 sont protégées sauf besoin démontré ; aucune galerie et aucune mutation des projets MAIN/NB2. Le chantier natif a reçu le SHA et la frontière de format privé2, avec conservation des anciennes métadonnées jusqu'à décision de propriétaire.

Pendant P07, un autre chantier a committé Bicycle en cd46a8a58a59155126653e60a06c7b438d7a13ec,74chemins, sans chevauchement avec les fichiers propres P07 identifiés. La copie privée de qualification a été rafraîchie avec ces seuls contenus committés ; la sauvegarde initiale reste la référence d'attribution des modifications propres. Index toujours vide après cette observation ; aucun hunk étranger n'est adopté par le lot.


### P07 — qualification du gel V3

Le candidat P07 V3 est proposé TO REVIEW après conformité et qualité indépendantes approuvées ; le commit ciblé des neuf chemins est préparé ci-dessous. L'audit initial a identifié le ZIP matérialisé du builder de jeu, la composition Border réservée à l'éditeur, les références natives Unicode et les identités typées des supports. L'implémentation ferme d'abord la sélection native, puis construit une copie portable sans modifier le projet. Elle préserve contexte, rôle, classification, références, édition et provenance. Les normalisations d'organisation exigent un acquittement ; les dimensions sont capturées dans la projection et ne sont plus des paramètres libres du service d'export.

La sauvegarde initiale contient 3738 sources, HEAD `5a6e2556fcd1bec89f6edbf8b5cd71ce4b804231`, index vide et 334 entrées dirty. Le commit Bicycle indépendant a ensuite avancé HEAD à `cd46a8a58a59155126653e60a06c7b438d7a13ec`. Le candidat parent part de ce HEAD committé et ne superpose que les huit fichiers ci-dessous : les trois fichiers existants correspondaient exactement à la sauvegarde initiale, sans hunk étranger. Les fichiers créés n'existaient pas dans HEAD. Aucun fichier core, P04 ou P06 n'est modifié.

| Fichier propre P07 | Zones modifiées et effet |
|---|---|
| `packages/map_authoring/lib/map_authoring.dart` | Exports de la projection et du composeur canoniques ; préservation du barrel public. |
| `packages/map_authoring/lib/src/domains/assets/resource_pack_projection.dart` | DTO natifs et projection ; fermeture/remapping typés ; normalisation sur copie ; preuve Border depuis les sources et métriques canoniques ; aliases vérifiés ; résultat possédé, export privé, réinspection et contrôle de révision. |
| `packages/map_authoring/lib/src/domains/maps/canonical_border_ground_composer.dart` | Composition partagée des vingt rôles, ordre des parts, timeline, transformations et résolution des cellules avec marges/gouttières ; callback PNG sans IO éditeur. |
| `packages/map_authoring/test/domains/assets/resource_pack_export_test.dart` | 23 cas et fixtures originales sept kinds/supports, atlas partagé, GLB texturé animé, classification et édition, Unicode, preuves source Border, refus pondéré/3D, mutations des aliases et collecte du cache. |
| `packages/map_distribution/lib/map_distribution.dart` | Export du nouveau builder, sans dépendance vers AuthoringPayload. |
| `packages/map_distribution/lib/src/resource_pack_builder.dart` | Descriptors et sink ; deux passes longueur/SHA/CRC, ordre UTF-8, profil ZIP STORE fixe, backpressure et abort, quotas avant ouverture de sources virtuelles. |
| `packages/map_distribution/test/resource_pack_builder_test.dart` | Cinq cas : profil déterministe exact, mutation entre passes, quotas virtuels, échec du sink et borne des chunks/backpressure. |
| `packages/map_editor/lib/src/features/border_studio/application/border_smart_tile_ground_snapshot_service.dart` | Délégation au composeur partagé ; validation du root, des chemins et des symlinks conservée dans l'adaptateur. Suppression de la composition locale dupliquée. |

Gel V3 : `/tmp/avelune-p07-frozen-v3.json`, candidat `/tmp/p07-commit-candidate-v3.json`, patch propre depuis la sauvegarde initiale SHA256 `bfb0b01da48e3cfb847e5100364cd963215e2eb47f1606d9631c8d25afe64241`. Les huit hashes de la copie qualifiée et du gel sont exacts. Le diff Git et ce patch font foi ; aucune copie intégrale des sources n'est créée dans le dépôt.

La campagne finale du checkout partagé a échoué au chargement sur le chantier étranger `MapEntity.interactiveEncounter` ; l'AOT partagé est sorti 254. Les logs restent `/tmp/p07-authoring-targeted-final.log`, `/tmp/p07-distribution-targeted-final.log`, `/tmp/p07-editor-targeted-final.log` et `/tmp/p07-authoring-build-final.log`. Ces erreurs n'ont pas été corrigées par P07 ni relancées en boucle. La qualification ci-dessous utilise exclusivement le candidat HEAD + P07. L'analyse complète partagée de l'éditeur est sortie 1 avec neuf diagnostics hors des fichiers modifiés ; ils ne sont pas qualifiés comme une analyse globale verte.

| Commande dans le package concerné | Résultat parent exact | Log |
|---|---|---|
| distribution : `dart test test/resource_pack_builder_test.dart test/resource_pack_inspector_test.dart test/game_package_builder_test.dart --reporter expanded` | `00:06 +57: All tests passed!`, exit 0 ; fichiers identiques V3. | `/tmp/p07-qualified-distribution-v1.log` |
| authoring V3 : `dart test test/domains/assets/resource_pack_export_test.dart test/domains/distribution/resource_library_export_test.dart --reporter expanded` | `00:17 +32: All tests passed!`, exit 0. | `/tmp/p07-qualified-authoring-v3.log` |
| editor : `flutter test --no-pub test/border_studio/border_smart_tile_ground_snapshot_service_test.dart` | `00:00 +9: All tests passed!`, exit 0 ; V2 n'ajoute que les accolades du catch, V3 inchangé. | `/tmp/p07-qualified-editor-v1.log` |
| authoring V3 : `dart analyze` | `No issues found!`, exit 0. | `/tmp/p07-qualified-authoring-analyze-v3.log` |
| distribution : `dart analyze` | Une info historique `unnecessary_library_name` dans le barrel, exit 0 ; aucune nouvelle alerte P07. | `/tmp/p07-qualified-distribution-analyze-v1.log` |
| editor V2 : `flutter analyze --no-pub lib/src/features/border_studio/application/border_smart_tile_ground_snapshot_service.dart` | `No issues found!`, exit 0 ; fichier identique V3. | `/tmp/p07-qualified-editor-analyze-v2.log` |
| authoring V3 : `dart compile exe bin/pokemap_authoring.dart -o /tmp/p07-qualified-authoring-v3` | `Generated: /tmp/p07-qualified-authoring-v3`, exit 0. | `/tmp/p07-qualified-build-v3.log` |
| authoring : `dart test test/parity/full_authoring_parity_test.dart --reporter expanded` | `00:36 +20: All tests passed!`, exit 0 ; registry/transports inchangés V3. | `/tmp/p07-qualified-parity-v1.log` |
| MCP : `npm run check` puis `npm run build` | Deux exits 0 sur les sources TypeScript committées inchangées. | `/tmp/p07-mcp-check-v1.log`, `/tmp/p07-mcp-build-v1.log` |
| MCP V3 : `node --import tsx --test --test-concurrency=1 test/resource_library_stdio.test.ts test/model3d_source_replace_stdio.test.ts` | Deux tests réels passés, zéro échec, 5.20 s ; catalogue relu : 416 actions et 60 kinds. | `/tmp/p07-mcp-live-v3.log` |

Le MCP V3 utilise l'AOT isolé SHA256 `317071875ae4793a73a63d7dc1bf1ae3307cb10477ef8a68488ad5f9e5e0235f`, avec shim dart limité au processus enfant, tests et délais inchangés ; métadonnées `/tmp/p07-mcp-aot-probe-v3.json`. Une invocation préparatoire avec un chemin de lanceur encore provisoire est sortie 2 avant tout test ; le chemin concret a été corrigé puis la commande réelle ci-dessus a passé. Aucun worker global ou projet réel n'a été rechargé. Les verbes sémantiques de transfert et leurs ressources restent PARTIAL jusqu'à P09 ; ces deux tests protègent les contrats déjà exposés, sans prétendre offrir le workflow d'import/export MCP.

La conformité V2 a trouvé un P1 réel : la déduplication par archivePath conservait les bindings natifs mais écrasait les descriptors de fichiers identiques. Un alias sélectionné modifié après projection n'était jamais lu ; l'export réussissait à tort. Le probe privé inchangé a été reproduit par le parent : `exportSucceeded:true`, trois bindings, un blob, `corruptSelectedAliasReads:0`. Log RED `/tmp/p07-qualified-alias-red-v2.log`, probe SHA256 `bf4f778d63507c0aa1d46589b53e8579fcc987cabc4ac874a16170c8e0bb00b8`.

V3 conserve un groupe immuable de tous les descriptors par blob. Chaque ouverture vérifie en flux les aliases non représentants puis laisse le builder contrôler le représentant : chacun est observé aux deux passes. Sept régressions couvrent mutation avant export et entre passes, deux lectures des trois aliases avec chunks de sept octets, mauvais chunks, octets hors plage, troncature/dépassement et absence de lecture d'une source hors sélection. Les trois bindings et l'unique blob sont conservés. Le delta V2 vers V3 ne contient que projection (+47/-11 lignes) et tests (+240 lignes), les six autres hashes restent identiques. Aucun buffer intégral ni nouveau port de stockage.

Re-revue conformité V3 : CONFORME, P1 fermé. Le probe original refuse maintenant `resource_pack.source_changed` ; sa sortie 255 est attendue car il ne capture volontairement pas le refus. Un second probe indépendant mute `image`, alias non représentant, et refuse aussi explicitement dans `_verifyNativeAlias`, runner 10558, sans descendant ni résidu. Le reviewer a vérifié les huit hashes et le patch avant/après, sans écriture dépôt. Revue qualité V3 : APPROUVÉE, aucun finding bloquant P1/P2 confirmé. La passe a relu les huit fichiers contre les contrats core et vérifié leurs hashes avant/après. Cinq tests builder passent à nouveau en moins d'une seconde (`/tmp/p07-quality-builder-v3.log`). Un probe privé à neuf assertions vérifie l'égalité du catalogue et des octets ZIP quand racines/fichiers sont inversés, les huit ressources réinspectées, l'absence de lecture hors sélection, la source intacte, le refus après dispose et l'abandon du sink si finish échoue (`/tmp/p07-quality-private-v3.log`), exit 0 et aucun résidu. Aucun fichier de source ni candidat modifié par la revue.

Tous les runs possédés utilisent `/tmp/avelune-assets-owned-run.py` ; les logs enregistrent runners et descendants, sans résidu confirmé ni terminaison étrangère. Aucun commentaire de code, dépendance, workflow CI ou nouveau Markdown. La garde Markdown est verte : `Markdown hygiene: no new Markdown files.`, exit 0, `/tmp/p07-markdown-hygiene-v3.log`.

Auto-critique et limites : pas de vert global monorepo, les réserves P05 restent ouvertes. La preuve couvre les fichiers sélectionnés aux observations de l'export, sans prétendre un verrou filesystem global. Les lectures supplémentaires des aliases sont nécessaires et seront comptées en P12. Un média candidat et les JSON restent matérialisables dans leurs limites natives ; aucun RSS ni volume réel n'est mesuré ici. Sol Border dérivé d'un modèle 3D et remapping pondéré changeant les pixels sont refusés en v1. Le cache P04 conserve les octets sans lease jusqu'au TTL/collectExpired/close, avec refus cache_full possible ; les fichiers de construction privés sont supprimés immédiatement. Import/certification apply P08, jobs/transports P09, UI P10/P11 et parcours natifs/Player P12 restent à livrer. P13 demeure différé.

Staging P07 autorisé : les huit sources techniques V3 et ce plan consolidé, neuf chemins seulement. Contrôler HEAD/index puis les hashes qualifiés de chaque blob indexé, committer une seule fois, et vérifier parent, liste des chemins et hashes du commit. Les 327 entrées dirty globales observées par la revue incluent les chantiers étrangers ; elles restent hors qualification et hors staging P07. Aucun push/rebase. Résultat et SHA seront consignés dans `/tmp/p07-commit-receipt.json` et Notion ; DONE reste réservé à Yoahn.


### Commit P07 et démarrage P08

P07 est committé en `cfad4b922909f0225ceaf022af227795d78d9b63`, parent `cd46a8a58a59155126653e60a06c7b438d7a13ec`. Les neuf chemins et leurs hashes d’index ont été vérifiés avant commit, puis les mêmes neuf chemins et contenus vérifiés dans le commit. Reçu `/tmp/p07-commit-receipt.json` ; index vide, 318 entrées dirty étrangères préservées, aucun push/rebase. Notion contient le SHA, les deux verdicts et les limites ; agrégat DOING et P07 proposé TO REVIEW. Le propriétaire terrain a reçu le SHA et la frontière de chevauchement probable du dispatcher, sans accès à MAIN/NB2.

P08 démarre après les revues favorables, avec une sauvegarde de 3983 sources core/gameplay/distribution/authoring/editor/MCP, des règles et du plan dans `/tmp/avelune-p08-before.json`. HEAD cfad4b922, index vide. Un seul implémenteur prend la projection/préparation additive, la certification finale P06 et le replay durable sécurisé ; les audits de raccord post-P06 et de réutilisation des helpers P03/P07 lui sont transmis. Les hunks étrangers de terrain, gateway, gameplay et Studio restent protégés. Aucun job, UI, galerie ou projet réel n’est ajouté à P08.

La copie de qualification parent `/tmp/p08-qualified-probe.json` contient les 9659 fichiers réguliers de HEAD seul ; l'inventaire Git a été comparé sans omission. Un lien historique absolu de file_picker est exclu, comme aux lots précédents. Les quatre `dart pub get --offline` des packages purs et `flutter pub get --offline` de l'éditeur passent ; l'ajustement du lockfile éditeur dans cette seule copie reste exclu du candidat.

Probe initial indépendant de reconstruction : `/tmp/p08-replay-reconstruction-probe.dart`, SHA256 `6fae457246ac78133b40337c17a71b926f5049ed11b6f3dca251df95398934d8`, reçu `/tmp/p08-replay-probe-receipt.json`. Sur HEAD cfad4b922, après apply resource.classify réussi et suppression normale du journal, fermeture puis reconstruction de worker/API/handles et réouverture : même plan/op refusé avec `validation_failed` / domainCode `plan.unknown`, sameReceipt false, projet et historique inchangés. Commande `dart --packages=<copie>/packages/map_authoring/.dart_tool/package_config.json /tmp/p08-replay-reconstruction-probe.dart`, via wrapper possédé ; log `/tmp/p08-replay-reconstruction-baseline-v2.log`, runner 32099, exit 0, aucun descendant ni résidu. Ce résultat caractérise le besoin P08 et ne prouve aucune correction. La première version du seul affichage JSON encodait un enum directement ; elle a été corrigée vers toJson avant de figer le probe, sans changement produit. Le probe restera inchangé lors de la qualification du replay sécurisé.

Le commit étranger Fishing `0e6dbc7b67e6f9bd4921cb1081136c2128781896` avance HEAD pendant P08. La copie parent est rafraîchie uniquement avec ses 37 blobs committés, après comparaison de chacun au précédent HEAD ; reçu `/tmp/p08-qualified-fishing-refresh.json`. La sauvegarde initiale P08 reste inchangée pour attribuer les hunks. Aucun fichier non committé de Fishing ou de terrain n'est ajouté à cette copie.

Une régression intermédiaire P08 bloque `describe` : `_contractTestFor` ne possède pas encore la preuve `resource_pack.import` et lève `No PMCP-085 contract evidence for resource_pack.import`, remonté `worker.internal`. RED `/tmp/p08-describe-red.log` et reproduction parent `/tmp/p08-shared-describe-probe.log`. Le raccord ciblé ajoute l'action et sa preuve directe, sans inventer d'exécution CLI/éditeur/MCP du workflow de transfert ; GREEN `/tmp/p08-describe-green.log`. Un AOT de checkpoint partagé compile dans `/tmp/p08-authoring-checkpoint-build.log` et son vrai JSONL describe passe, 423 actions, `/tmp/p08-parent-checkpoint-describe.log`, runner 44326, exit 0, aucun descendant. Le schéma de l'import n'accepte que preparedImportHandle. Cela vérifie la santé du checkpoint partagé, pas le candidat final isolé P08 ni les transports P09.

Coordination du chantier terrain : un gel temporaire des écritures de production P08 permet d'épingler un worker indépendant avant une mutation native autorisée de son côté. Une copie de notre checkpoint est conservée séparément avec SHA256 `c2be76b3d67ca45ad541541af8d54f0ecebbdaad2df18f03be466627c312ed50`, reçu `/tmp/p08-terrain-checkpoint-handoff.json`. Le propriétaire confirme finalement son propre AOT SHA256 `8d8c822ddb23982b637dea27a70ba30b463cb0f9731bbf2ef16497c224f2a2fc`, 961 sources/configs stables avant/après compilation, describe et test MCP terrain 1/1 ; ces derniers sont ses preuves, pas une qualification P08 du parent. Le gel est levé dès son épinglage. Aucun accès ou mutation MAIN/NB2 par ce chantier assets ; P08 continue sur fixtures privées.

### P08 — Candidat V1 et premières réserves indépendantes

L'audit d'implémentation confirme les frontières P03/P04/P06/P07 : le visiteur portable inventorie sans remapper, le store possède déjà les leases et lectures vérifiées, l'autorité bulk reste interne, et les helpers de réécriture typée/préparation Border sont extraits de l'export. Une projection native pure précède la fusion additive et sert aussi de référence pour les dépendances historiques. Aucun job, UI, galerie, donnée de projet réel, push ou rebase dans ce lot.

Le candidat V1 compte 24 fichiers techniques, neuf créations ; `/tmp/p08-final-candidate.json`, patch `/tmp/p08-final-owned.patch`, SHA256 `4d0b0a8c1f29781a463837c772ff79b278c003fa0df3c415cb37289167ae5dd9`. Le parent vérifie chaque contenu contre le candidat, le checkout, la sauvegarde initiale et HEAD `0e6dbc7b67e6f9bd4921cb1081136c2128781896`, puis le fige dans `/tmp/p08-parent-candidate-v1.json`. Les deux fichiers partagés contiennent uniquement les injections P08 au-dessus de HEAD ; leurs hunks étrangers restent exclus. La copie exécutable ne reçoit que ces 24 fichiers au-dessus de ses blobs committés.

| Fichier technique | Zones et effet attendu |
| --- | --- |
| packages/map_core/lib/src/models/resource_pack_installation_catalog.dart | Trace JSON des mappings internes déterministes ; aucun fingerprint supplémentaire de support |
| packages/map_distribution/lib/map_distribution.dart | Export limité des trois types du lecteur ZIP aléatoire existant |
| packages/map_authoring/lib/map_authoring.dart | Exports de l'action et du préparateur canonique |
| packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart | Composition par session, préflight replay durable, certification finale et préconditions sous verrou |
| packages/map_authoring/lib/src/application/map_mutation_dispatcher.dart | Injection du résolveur opaque et enregistrement de l'action, sans exemption de garde |
| packages/map_authoring/lib/src/parity/full_authoring_parity.dart | Contrat import et preuve directe ; aucune preuve de transfert distant inventée |
| packages/map_authoring/lib/src/security/secure_mutation_executor.dart | Contrôles de contexte et reçu ledger/historique, autorisation et audit du replay sans mutation |
| packages/map_authoring/lib/src/tooling/jsonl_worker.dart | Traduction des erreurs de préparation et d'index en refus de domaine |
| packages/map_authoring/lib/src/transactions/file_idempotency_store.dart | Lookup secondaire acteur/projet/opération sur l'index existant, matérialisation du seul record demandé |
| packages/map_authoring/lib/src/transactions/authoring_payload.dart | Cleanup d'association d'inventaire lié à l'owner du plan |
| packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart | Petit port de probe conservant missing/exists/inventoryUnavailable |
| packages/map_authoring/lib/src/domains/assets/asset_store.dart | Exclusion exacte de la trace historique du scan d'usages |
| packages/map_authoring/lib/src/domains/assets/resource_source_guards.dart | Même exclusion exacte de la garde de suppression |
| packages/map_authoring/lib/src/references/resource_usage_documents.dart | Même exclusion exacte des documents de références vivantes |
| packages/map_authoring/lib/src/domains/assets/resource_pack_projection.dart | Export raccordé aux helpers communs, preuve d'aliases P07 conservée |
| packages/map_authoring/lib/src/domains/assets/resource_pack_native_remapper.dart | Réécritures typées partagées des références, frames, propriétés et supports |
| packages/map_authoring/lib/src/domains/assets/resource_pack_border_sources.dart | Préparation Border commune avec marges, métriques et compilateur canonique |
| packages/map_authoring/lib/src/domains/assets/resource_pack_import_projection.dart | Projection des sept kinds/supports, namespace, GLB, classification et snapshots |
| packages/map_authoring/lib/src/domains/assets/resource_pack_import_preparer.dart | Sélection/préparation possédées, conflits, fichiers/CAS/licences, leases, expiration et inventaire final |
| packages/map_authoring/lib/src/domains/assets/resource_pack_actions.dart | Paramètre unique preparedImportHandle et garantie publique recoverable, sans atomic ambigu |
| packages/map_authoring/test/domains/assets/resource_pack_actions_test.dart | Révisions, dry-run, ownership multi-plans, expiration, Border réel, image collection, monde et discoverability |
| packages/map_authoring/test/domains/assets/resource_pack_transaction_test.dart | Apply/replay, contexte, rétention, fautes, certification et trajet réel de plus de 500 fichiers |
| packages/map_authoring/test/domains/assets/resource_pack_reimport_test.dart | Tableau de réimport, dépendances historiques, copie isolée et versions côte à côte |
| packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart | Fixtures possédées et reconstruction native ; aucun projet réel |

Preuves auteur V1 : cinq suites signées 57/57, `/tmp/p08-signed-final-v2.log` ; export 23/23, `/tmp/p08-export-final.log` ; analyse authoring `No issues found!`, `/tmp/p08-shared-analyze-final-v2.log`. Un premier helper redo retournait une Future sans await dans try/finally et libérait son plan trop tôt ; corrigé. Le trajet bulk complet dépassait ensuite 30 secondes dans un test ; il a été découpé en trois phases ordonnées partageant une fixture, sans augmenter les délais. Ces preuves partagées ne constituent pas une qualification isolée.

Commande parent V1, dans map_authoring qualifié, via `/tmp/avelune-assets-owned-run.py` : `dart test test/domains/assets/resource_pack_actions_test.dart test/domains/assets/resource_pack_transaction_test.dart test/domains/assets/resource_pack_reimport_test.dart test/domains/assets/content_addressing_test.dart test/domains/assets/asset_security_test.dart test/domains/assets/resource_pack_export_test.dart test/domains/distribution/resource_library_export_test.dart --concurrency=1 --reporter expanded`. Résultat exact : `02:25 +87 -2: Some tests failed.`, exit 1, `/tmp/p08-qualified-authoring-v1.log`. L'apply bulk prend environ 19 secondes ; undo dépasse 30 secondes, puis redo échoue car l'historique est encore mutation. Le teardown produit une erreur IO secondaire pendant l'undo encore actif. Trois descendants observés, aucun résidu confirmé. Aucun vert global ni augmentation d'un délai global ; diagnostic privé borné demandé avant décision sur ce test d'intégration.

Le probe parent original inchangé de reconstruction passe désormais sur V1 : `replayStatus: success`, `sameReceipt: true`, journal supprimé, worker/API reconstruits, projet et historique inchangés. `/tmp/p08-replay-reconstruction-green-v1.log`, runner 65310, exit 0, un descendant, aucun résidu. La même source avait donné plan.unknown sur les deux HEAD de référence.

Conformité indépendante V1 : **NON CONFORME, un P2**. Une classification ajoutée localement à une dépendance historique initialement non classée est ignorée lors d'une extension : la boucle compare seulement les entrées attendues présentes. Probe `/tmp/p08-spec-classification-probe.dart`, SHA256 `1d28188baebc64bb28c71445cfd7643cfe96cfa1f81bdf308bed324088fbea89`, log associé : extension character après import element et classement local interior du tileset requis retourne ready/conflicts vides. La correction doit comparer symétriquement présence et absence pour les seules dépendances historiques requises. Le probe restera inchangé pour la requalification.

La même revue altère directement le seul fingerprint privé du ledger : replay accepté avec reçu identique et projet inchangé, `/tmp/p08-spec-fingerprint-probe.dart` et `.log`. Limite d'intégrité privée explicite, sans finding P1/P2 : la menace de réécriture directe des fichiers privés reste hors contrat, et aucun nouveau champ/signature n'est introduit. Les 24 hashes gelés/qualifiés restent identiques avant/après la revue. Sa garde Markdown en copie sans dépôt Git sort 128 ; la garde réellement lancée au dépôt par le parent est verte, aucun nouveau Markdown. Qualité, AOT final, parité/MCP final et commit P08 restent ouverts.

### P08 — Correction, qualification V2r et avis de revue

Le P2 est corrigé dans `_definitionConflicts` : comparer symétriquement les classifications attendues et actuelles des seules ressources historiques requises, y compris absence/présence. Les nouvelles régressions vérifient ajout, suppression, importCopy sans modifier le classement local original, et modification hors fermeture conservée. L'oracle indépendant V1 reste byte-identique et retourne maintenant conflict avec classification_modified_or_missing. Aucun changement de politique pour une sélection déjà couverte.

Un diagnostic privé sur les sources V1 immuables garde la fixture jusqu'à la fin réelle des opérations et mesure une progression régulière jusqu'aux 506 changements physiques : apply 15,123 secondes, undo 22,360 secondes, reçu applied et zéro tileset après annulation ; `/tmp/p08-bulk-stages-probe.log`, exit 0 sans résidu. Il ne prouve pas la cause exacte du ralentissement du premier run. Le test volumineux devient une seule intégration apply → undo → redo → reopen, propriétaire de sa fixture dans le try/finally du même Future. Sa borne locale explicite est 180 secondes ; aucun délai global, SLA produit, workflow ou coût de runner CI n'est changé. Le premier parcours auteur complet se termine en 58,585 secondes ; `/tmp/p08-bulk-integration-v2.log`. Ce changement de test remplace le découpage artificiel en phases et empêche le teardown de supprimer les fichiers pendant une phase encore active.

Le gel final V2r contient 25 fichiers techniques, neuf créations : les 24 chemins du tableau précédent, plus `packages/map_distribution/test/resource_pack_inspector_test.dart`. Ce dernier retire une seule importation interne devenue redondante après l'export public du lecteur ZIP ; il était propre, byte-identique baseline/HEAD/checkout avant intervention. Cinq chemins seulement diffèrent de V1 : préparateur, trois tests/fixture authoring et ce test distribution. Les vingt autres SHA sont identiques. Aucun hunk étranger de dispatcher/parité/gateway n'est absorbé.

Manifeste parent `/tmp/p08-parent-candidate-v2r.json`, gel `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/avelune-p08-frozen-v2r-60qtah57`, copie exécutable indiquée dans le manifeste. Patch propre `/tmp/p08-final-v2r-owned.patch`, SHA256 `94e4e4d657ac76306a6d273de5e99c96dfe3f00ffe1f32b9b15ef6ab59196e21`. Les 25 contenus sont contrôlés depuis HEAD 0e6, la sauvegarde initiale, le checkout et le candidat ; les deux revues vérifient leurs SHA avant/après sans écart.

| Passe / commande fraîche du parent | Résultat exact et preuve |
| --- | --- |
| map_authoring : sept fichiers de tests de la commande V1, `--concurrency=1 --reporter expanded` | `01:27 +89: All tests passed!`, exit 0 ; `/tmp/p08-qualified-authoring-v2r.log` |
| map_authoring : `dart test test/transactions/idempotency_contract_test.dart test/security/authorization_policy_test.dart test/security/resource_pack_bulk_authorization_test.dart --concurrency=1 --reporter expanded` | `01:52 +38: All tests passed!`, exit 0 ; `/tmp/p08-qualified-security-v2r.log` |
| map_authoring : `dart test test/parity/full_authoring_parity_test.dart --concurrency=1 --reporter expanded` | `00:36 +20: All tests passed!`, exit 0 ; `/tmp/p08-qualified-parity-isolated-v2r.log` |
| map_core : quatre fichiers resource_pack_contract/publication/dependency_graph/installation_catalog, `--reporter expanded` | `00:07 +47: All tests passed!`, exit 0 ; `/tmp/p08-qualified-core-v1.log`. Sources core strictement identiques dans V2r |
| map_distribution : `dart test --reporter expanded` | `01:05 +355: All tests passed!`, exit 0 ; `/tmp/p08-qualified-distribution-v2r.log`, suite du candidat isolé. Les 357 tests du checkout partagé de l'auteur ne sont pas présentés comme ces 355 tests |
| map_authoring : `dart analyze` | `No issues found!`, exit 0 ; `/tmp/p08-qualified-authoring-analyze-v2r.log` |
| map_core : `dart analyze lib/src/models/resource_pack_installation_catalog.dart` | `No issues found!`, exit 0 ; `/tmp/p08-qualified-core-target-analyze-v2r.log` |
| map_core : `dart analyze` | 129 infos, zéro warning/erreur, exit 0 ; `/tmp/p08-qualified-core-analyze-v1.log`, toutes hors fichier modifié |
| map_distribution : `dart analyze` | Une info unnecessary_library_name hors delta, exit 0 ; `/tmp/p08-qualified-distribution-analyze-v2r.log`. L'info nouvelle unnecessary_import est supprimée |
| map_authoring : `dart compile exe bin/pokemap_authoring.dart -o /tmp/p08-qualified-authoring-v2r` | `Generated: /tmp/p08-qualified-authoring-v2r`, exit 0 ; `/tmp/p08-qualified-build-v2r.log` |
| tools/pokemap_mcp : `npm run check`, puis `npm run build` | Exit 0 chacun ; `/tmp/p08-mcp-check-v2r.log`, `/tmp/p08-mcp-build-v2r.log` |
| Deux tests MCP originaux resource_library_stdio et model3d_source_replace_stdio, puis probe privé du contrat d'import | 2/2 en 5,122 secondes, puis schéma strict/garantie recoverable/refus resource_pack.prepared_unknown avec manifeste inchangé ; exit 0, `/tmp/p08-mcp-live-v2r.log` |

Le MCP utilise un AOT épinglé du seul candidat HEAD+P08, SHA256 `bdcb29dfad8394e13e4d282b663f8fed0ed94b0c173cfa3222d221036c63762d`, reçu `/tmp/p08-mcp-aot-v2r.json`. Shim dart limité au child de cette vérification ; tests originaux et deadlines MCP inchangés. Le catalogue réel expose 417 actions et 60 kinds. Ce probe prouve l'action et ses refus, pas le workflow de transfert complet P09.

Deux oracles privés inchangés sont rejoués par le parent sur V2r : reconstruction après suppression du journal → même reçu, projet/historique inchangés, `/tmp/p08-replay-reconstruction-green-v2r.log`, exit 0 ; classification ajoutée → conflict, `/tmp/p08-parent-classification-green-v2r.log`, exit 0. Les SHA des sources d'oracle restent ceux consignés plus haut.

La vérification additionnelle groupée parité/registre/documentation donne initialement 30 passés et trois échecs, `/tmp/p08-qualified-parity-v2r.log` : deux sous-processus PMCP expirent à 30 secondes, et le registre manque cinematicMediaAsset. Les deux sous-processus passent ensuite sur HEAD pur (2/2 en 35 secondes, `/tmp/p08-head-pmcp-tool-tests.log`) et toute la parité V2r passe isolément (20/20 en 36 secondes), délais inchangés. La cause exacte des expirations du run groupé n'est pas affirmée ; elles restent consignées, sans vert global.

Le cas cinematicMediaAsset est reproduit exactement, sans P08, sur une archive Git de HEAD 0e6 contenant les quatre packages purs : `/tmp/p08-registry-baseline.json`, `dart test test/registry/action_registry_test.dart --plain-name 'registers every resource kind used by canonical mutations' --reporter expanded` → 0 passé, un échec, même Set cinematicMediaAsset, exit 1 ; `/tmp/p08-head-registry-baseline.log`. Il reste hors correctif P08. Une analyse core de cette archive partielle retourne exit 3 : les 129 infos du candidat y sont retrouvées, avec 70 diagnostics supplémentaires dus aux références externes non extraites ; `/tmp/p08-head-core-analyze.log`. Cette analyse partielle ne constitue pas un baseline global vert.

La commande autonome `dart run tool/pmcp085_conformance.dart` produit catalogComplete true, blockedOrMissingCount 0, 417 actions, mais transportCertificationComplete et itemTransportCertificationComplete false ; exit 1 attendu sans bundle des reçus Item, `/tmp/p08-qualified-pmcp085-v2r.log`. Aucun reçu de transport n'est fabriqué pour changer ce résultat. La parité de transfert du lot reste explicitement PARTIAL jusqu'à P09.

Conformité V2r : **CONFORME**, aucun P1/P2 restant. Le reviewer rejoue son oracle intact puis trois tests indépendants de classification/hors fermeture/importCopy : 3/3 en 14 secondes, `/tmp/p08-spec-classification-targeted-v2r.log`, exit 0. Qualité V2r : **APPROUVÉE**, aucun P1/P2 concret. Son probe original `/tmp/p08-quality-owned-probe.dart`, SHA256 `631c648d0bc49a42291d72f297ada3f34611737f3276e201bf9779e5819d1d48`, prouve apply après release de préparation/sélection/archive, nettoyage des inventaires indépendants, refus d'acteur sans mutation, reçu original reconstruit et rétention de 31 jours ; `/tmp/p08-quality-owned-probe-v2.log`, exit 0. Le premier essai de ce seul probe gardait le workspace vivant 31 jours et recevait workspace.handle_expired ; correction du probe par fermeture/réouverture, aucun changement produit.

Verdicts des passes : audit/architecture raccord conforme ; implémentation livrée sur le périmètre signé après correction P2 ; tests et build ciblés validés ci-dessus, réserves globales explicites ; conformité indépendante conforme ; critique qualité indépendante approuvée. Tous les runners parent sont possédés par le wrapper ; le run groupé parité réape deux descendants confirmés après timeout, les autres runs finaux n'ont aucun résidu non confirmé. Aucun processus ou application étrangère arrêté.

Auto-critique : aucune mesure RSS, saturation réelle de disque, capacité maximale, UI ou lecture Player n'est certifiée. Les fautes sont injectées aux checkpoints dans des fixtures originales temporaires. Le trajet bulk réel porte sur 501 aliases PNG et une licence, 502 sorties logiques et deux CAS ; il ne remplace pas P12. La limite d'intégrité privée du fingerprint et les refus v1 Border restent explicites. Les réserves globales P05, le registre cinématique antérieur et les expirations du premier run groupé restent visibles. P09 porte jobs/transports/annulation, P10/P11 les parcours Studio et P12 la certification native/volume ; P13 reste différé.

Préparation du commit P08 autorisé : 25 fichiers techniques qualifiés et ce plan consolidé, 26 chemins uniquement. HEAD attendu 0e6, index vide, 310 chemins dirty globaux avant staging. Contrôler chaque blob d'index contre le gel, puis committer et vérifier parent, liste des chemins et hashes ; reçu `/tmp/p08-commit-receipt.json`. Aucun push/rebase. P08 proposé TO REVIEW, décision DONE réservée à Yoahn ; agrégat Notion DOING et P09 prochaine étape après commit.

### Commit P08 et démarrage P09

Commit P08 créé : `a7653ee9a2be92e64312dd162919609abbcf7d7f`, parent `0e6dbc7b67e6f9bd4921cb1081136c2128781896`. Les 26 chemins et leurs SHA sont contrôlés dans l'index puis dans le commit ; reçu `/tmp/p08-commit-receipt.json`. Patch de staging avec plan SHA256 `07db5118999d2427fc313808b211264609af15e318369b6f9163da1bb2c2c07c`. Index vide après commit, 288 chemins dirty préservés, aucun push/rebase. Notion contient le SHA et les limites ; agrégat DOING, P08 proposé TO REVIEW.

P09 démarre avec une sauvegarde de 5446 fichiers source/configuration des quatre packages purs, de l'éditeur, de Studio, du MCP, des règles, du catalogue d'actions et du plan : `/tmp/avelune-p09-before.json`, HEAD a7653ee9a, index vide. Les sources étrangères et le catalogue Markdown déjà modifié restent protégés. Un seul implémenteur prend les jobs/transports après audit ; le parent conserve Git, Notion et la documentation. Les audits préparatoires P09 et les raccords P04/P08 sont transmis. Aucun accès MAIN/NB2 ni app native, aucun ajout de galeries.

### Audit initial P09 approuvé

Le service de jobs existant se limite aux DTO et au port ; son validateur de noms rejette les underscores de `resource_pack.*`. Le parcours P08 réinspecte encore synchroniquement l'archive lors de la sélection et de la préparation, comme l'export P07 après construction. P09 réutilise `LocalResourcePackStore.withSourceInIsolate` pour ces phases CPU et lie toute réutilisation d'inspection certifiée au même owner, payload, SHA brut et nombre d'octets ; aucun booléen ou DTO client ne peut certifier l'archive. Le contrôle d'intégrité P04 reste exécuté avant lecture ou réutilisation. Le mode de sélection `archive` requiert une inspection, le mode `native` conserve les références natives `{kind,id}` ; leur projection portable suit la sélection.

La barrière d'annulation sera placée sous le verrou canonique du projet immédiatement avant `_idempotency.execute`, et propagée dans apply, l'exécuteur sécurisé et les opérations d'historique. Le staging reste coopératif. Une annulation acceptée interdit toute promotion ; après réservation, le refus expose le job, la phase et `cancelAllowed=false`. Le premier jalon concret couvre stage/inspect avec poll/cancel, avant l'extension aux autres transferts et aux transports. Ce sont des décisions d'audit, pas encore des preuves d'implémentation.

La copie de qualification parent `/tmp/p09-qualified-probe.json` contient les seuls 9675 fichiers réguliers suivis du HEAD `a7653ee9a2be92e64312dd162919609abbcf7d7f`, inventaire vérifié contre Git, sans overlay du checkout vivant. Un lien de cache Flutter historique est exclu ; aucun fichier régulier n'a été omis par l'archive. Les quatre résolutions Dart offline ont terminé. L'implémenteur n'écrit pas dans cette copie. Le défaut antérieur du registre `cinematicMediaAsset` reste séparé de P09 ; aucune correction cinématique n'est autorisée implicitement par l'ajout de kinds de transfert.

Contrôle de départ sur cette copie HEAD pure, depuis `packages/map_authoring` : `python3 /tmp/avelune-assets-owned-run.py dart test test/contracts/job_contract_test.dart test/tooling/jsonl_worker_test.dart test/tooling/jsonl_resource_library_flow_test.dart --concurrency=1 --reporter expanded`, résultat 38 réussis et 1 échec en 22 s, exit 1, `/tmp/p09-head-contract-worker-library.log`. Les quatre tests des DTO de jobs et le parcours bibliothèque passent. Le seul échec est le golden `describe and malformed input are byte-for-byte stable`, déjà périmé face aux extensions natives committées (premier écart à l'offset 3057, dimension Event V2). Runner 4603, deux descendants observés, aucun résidu. Toute mise à jour de cette fixture pour les nouveaux kinds P09 devra distinguer ce rattrapage de la sémantique du lot.

La première lecture du squelette P09 détecte une fermeture qui lève `_Cancelled` après `enterFinalization`. Le probe parent indépendant `/tmp/p09-close-finalization-probe.dart`, SHA256 `824787ad251df38cb40f689574430c2f70f9c0221f66bc3604b984becd9cf5fb`, fige les trois sources nécessaires puis ferme pendant une finalisation suspendue. RED : `finalizingWorkSurvivedClose: false`, exit 255, `/tmp/p09-close-finalization-red.log`, runner 5946, un descendant observé et aucun résidu. L'implémenteur reçoit le constat : la fermeture doit attendre la finalisation engagée, conserver reçu ou recoveryRequired, et séparer la fermeture aux nouvelles commandes de l'annulation du travail réservé. Le probe reste inchangé pour la qualification finale.

### Checkpoint d'architecture et premier jalon P09

Le premier jalon auteur stage/inspect passe 5/5 tests en 5 s, exit 0, `/tmp/p09-stage-inspect.log`, runner 6133, un descendant et aucun résidu. Le test observe un isolate différent pour l'inspection P04 et couvre le refus d'un chemin arbitraire puis le grant local exact. Ce jalon ne prouve pas encore les transports ni tous les transferts. Le démarrage utilise ensuite effectivement la révision capturée à l'attachement, sans nouveau snapshot avant enregistrement.

La passe indépendante `p09_architecture_checkpoint`, strictement statique, confirme trois raccords : inspecter la recovery avant un snapshot natif potentiellement incohérent ; revérifier son blocage dans le verrou transactionnel commun aux handles d'un même projet ; marquer la session closing avant toute attente et partager la même Future de fermeture. Une erreur d'audit après commit doit rechercher d'abord le reçu durable : la phase recoveryRequired ne prouve pas à elle seule qu'un journal pending subsiste. Verdict d'architecture : raccords ciblés possibles sans framework ni nouveau format ; aucun verdict de conformité finale. Aucun fichier ni processus modifié par cette passe.

L'ouverture avec bulk pending est cadrée comme lecture seule avec statut consultable et récupération explicite via job autorisé ; elle ne reprend pas automatiquement une promotion native. La planification, l'application et l'historique mutateur restent interdits jusqu'à réconciliation canonique, y compris par un autre handle de la même racine. Les locks et métadonnées privées existants ne sont pas assimilés à une reprise native.

Un second oracle parent `/tmp/p09-concurrent-close-probe.dart`, SHA256 `5bd43be8e8b064e84a35b5d748734783ceda65f5b92dc615a4eeb8e8f239ae93`, démontre la deuxième fermeture qui termine avant le travail réservé : RED exit 255, `/tmp/p09-concurrent-close-red.log`, runner 13131, quatre descendants, aucun résidu. Les deux oracles inchangés passent sur le correctif intermédiaire : `finalizingWorkSurvivedClose: true` et `secondCloseReturnedBeforeFinalization: false`, exit 0, `/tmp/p09-close-finalization-green-interim-v2.log` et `/tmp/p09-concurrent-close-green-interim.log`, runners 14451/14460, aucun descendant ni résidu. Les sources RED et intermédiaires sont préservées ; métadonnées `/tmp/p09-close-oracles-interim-v2.json`. Ce n'est pas encore la qualification du gel final.

Autre baseline sur HEAD pur : `python3 /tmp/avelune-assets-owned-run.py node --import tsx --test --test-name-pattern 'all twelve tools publish strict schemas' test/conformance_security.test.ts`, depuis `tools/pokemap_mcp`, donne 0 réussite et 1 échec en 1 s, exit 1, `/tmp/p09-head-mcp-tools-schema.log`. Le serveur expose déjà 14 outils, la fixture attend 12 et omet les deux outils de création de projet committés. L'ajout P09 devra distinguer cette attente périmée de son propre outil, sans changer le comportement de création. Runner 13700, deux descendants et aucun résidu.

La baseline MCP complète des deux fichiers `test/conformance_security.test.ts test/authoring_client.test.ts`, avec `node --import tsx --test --test-concurrency=1`, donne 8 réussites et le même unique échec de liste d'outils, 1,257 s, exit 1, `/tmp/p09-head-mcp-security-client.log`. Les tests TypeScript sont ceux du HEAD pur ; le worker est le binaire isolé P08 committé, SHA256 `bdcb29dfad8394e13e4d282b663f8fed0ed94b0c173cfa3222d221036c63762d`, via un PATH limité au child, lanceur `/tmp/p09-head-mcp-baseline.py`. Aucun délai ni test original n'est changé. Le reçu golden map.create et les gardes UTF-8/rate passent. Runner 16090, quatre descendants et aucun résidu ; ne pas déduire de cette baseline un résultat du futur code P09.

Le contrôle du budget MCP signale que `operationSuccess` duplique data dans le texte et le contenu structuré : un chunk de 128 Kio dépasse ainsi 256 Kio une fois encodé en base64. Les nouveaux transferts doivent borner l'enveloppe réelle, les échappements et les ressources lues, avec texte court et un seul contenu détaillé lorsque nécessaire. Aucun refactor global du helper pour les autres domaines n'est demandé.


### Deuxième jalon P09 : annulation, reprise et budgets de transport

Les tests intermédiaires auteur ne constituent pas encore la qualification du candidat figé. Le parcours ciblé direct/JSONL termine avec 8/8 réussites en 24 s, exit 0, `/tmp/p09-final-targeted-flow.log`, runner 60584, deux descendants et aucun résidu. Le test de reprise après promotion partielle, reconstruction, ouverture en lecture seule, récupération autorisée et replay passe 1/1 en 7 s, `/tmp/p09-recovery-replay-green.log`, runner 35122, un descendant et aucun résidu. La comparaison du reçu récupéré avec l'historique appliqué normalise uniquement statut, date et marqueur recoveryOutcome=resumed ; les autres champs, l'autorisation et le certificat doivent rester stricts et seront revus sur le gel.

L'annulation coopérative est propagée au staging transactionnel par un payload emprunté qui conserve révision, digest et ownership. Le test suspend le deuxième de trois chunks de 64 Kio, accepte l'annulation puis vérifie deux chunks lus, zéro promotion, aucun journal et aucune libération prématurée de la source : `/tmp/p09-chunk-cancel-green.log`, 1/1, exit 0, runner 56578, un descendant et aucun résidu. Le DTO conserve bounded=false : aucune garantie d'arrêt en une seconde n'est prétendue.

Une contrepreuve révèle que les anciennes commandes JSONL peuvent contourner les jobs avec un plan bulk canonique. Le refus resource_pack.job_required repose désormais sur la provenance interne des plans, historiques et journaux, sans drapeau client ; les mutations ordinaires restent admises. RED `/tmp/p09-legacy-bypass-red.log`, puis GREEN `/tmp/p09-legacy-bypass-green.log`, 1/1 en 4 s, exit 0, runner 52742, un descendant et aucun résidu. Ce raccord est nécessaire pour rendre les délais de la boucle séquentielle honnêtes, tout en gardant les méthodes directes canoniques utilisées par les jobs.

L'export binaire réutilise les segments vérifiés P06 pour éviter de revérifier toute l'archive à chaque lecture de 128 Kio. Le coût quadratique initial estimé pour 500 Mio et environ 4000 lectures approchait 2 Tio : calcul explicatif, aucune mesure RSS ou certification P12. Les filtres serveur partagent la sémantique P02 pour contexte, famille et descendants, libellés et recherche ; la sélection demeure indépendante des lignes visibles. Des pins mémoire pris avant l'enregistrement protègent les archives contre release/TTL tant que le job les possède. Les réponses publiques sont figées pour empêcher un appelant direct de modifier les futurs polls par alias de Map/List.

Le premier test MCP réel passe 3/3 en 74,929 s, `/tmp/p09-mcp-flow.log`, runner 31564, neuf descendants et aucun résidu. Ce diagnostic JIT utilise explicitement authoring-timeout-ms=60000 ; il ne prouve pas les délais produit habituels. La qualification parent devra utiliser le binaire AOT du candidat figé avec les délais MCP/worker par défaut et vérifier aussi resources/read, les schémas stricts et l'enveloppe effective, échappements et base64 compris.

La coordination avec le chantier terrain reste séparée de la qualification : gel temporaire du 17 octobre 2026 de 01:15:23 à 01:16:48 UTC, 964 sources/configurations copiées par leur propriétaire, aucune variation pendant la copie. Ce gel est levé ; leur option reanchorInstances et leurs tests terrain restent étrangers au commit P09. Une tentative de formatage limité aux zones P09 crée ensuite trois raccords syntaxiques invalides, immédiatement détectés par analyze. Leur réparation est comparée au dernier source valide en format normalisé (`/tmp/p09-normalized-since-valid.patch`) ; l'analyse auteur redevient No issues found!, exit 0, `/tmp/p09-analyze-candidate.log`, runner 68075, un descendant et aucun résidu. Le gel final, les deux revues et le commit restent à effectuer ; agrégat DOING et P13 différé.


### Qualification parent P09 V1 et revue de conformité non approuvée

Le parent vérifie le manifest auteur SHA256 58e665ddd3821f01855af7d84cf54a7ec4b539f70133148fd1a938956b5a4065 et chacun des 43 chemins, dont 12 nouveaux. La projection propre des trois fichiers déjà étrangers exclut les changements de ctime du gateway, les actions terrain et les rencontres interactives. Patch technique HEAD+P09 `/tmp/p09-parent-owned-v1.patch`, SHA256 57a968dd911adee13b23aec8b478f571949d7d2998f2effed566adf38936140d ; reçu `/tmp/p09-parent-candidate-v1.json`. Les 9675 fichiers réguliers du HEAD sont revérifiés : aucune variation hors overlay autorisé, golden et catalogue P09.

Le générateur immuable de describe est rejoué sans modifier le test. Face au transcript généré sur HEAD pur, seuls cinq kinds P09 sont ajoutés, les 60 descripteurs précédents et toutes les autres données sont identiques. Le golden conserve aussi les cinq écarts de schéma préexistants déjà caractérisés. Fixture SHA256 f518d5c03ce0b005605a568fe39c1fd1006092dc9c847d08c7995c064d3ac340 ; reçu `/tmp/p09-parent-doc-fixture-v1.json`. L'ancien test byte-for-byte passe après cette mise à jour. Le catalogue existant reçoit un append P09 propre séparant les 18 verbes de l'unique action d'import ; ses hunks étrangers restent préservés.

Commandes parent sur la copie isolée, toutes sous wrapper d'ownership :

- Dart analyze : No issues found!, exit 0, `/tmp/p09-qualified-analyze-v1.log`, runner 73672, un descendant, aucun résidu.
- npm run build : exit 0, `/tmp/p09-qualified-npm-build-v1.log`, runner 73673, un descendant, aucun résidu.
- Dart compile exe bin/pokemap_authoring.dart -o /tmp/p09-qualified-authoring-v1 : Generated, exit 0, `/tmp/p09-qualified-build-v1.log`, runner 79817, quatre descendants, aucun résidu. Binaire AOT SHA256 c80dbf8c4d367919bfcd618003adb0179f5c1318d95a82004c78e4c0368b4294, `/tmp/p09-mcp-aot-v1.json`. Aucun test MCP exécuté sur cet AOT à ce stade ; les défauts de revue imposent un nouveau candidat.
- Deux oracles de fermeture inchangés, SHA déjà consignés : finalizingWorkSurvivedClose=true et secondCloseReturnedBeforeFinalization=false, exit 0, `/tmp/p09-close-finalization-final-v1.log` et `/tmp/p09-concurrent-close-final-v1.log`, runners 78192/78193, aucun descendant ni résidu. Sources exactes `/tmp/p09-close-oracles-final-v1.json`.
- Les 11 fichiers de tests jobs/transferts/JSONL/contrats/bibliothèque/payload/projections donnent 97 réussites et un échec en 52 s, exit 1, `/tmp/p09-qualified-focused-v1.log`, runner 77938, quatre descendants, aucun résidu. Le seul échec est every described resource kind has an executable query route, qui tente une liste globale de resourcePackJob. Le contrat temporaire exige un get par handle possédé ; le test doit vérifier ce refus, sans implémenter une liste factice.
- Les 14 fichiers transaction/historique/sécurité donnent 130/130 en 1 min 21 s, exit 0, `/tmp/p09-qualified-transaction-security-v1.log`, runner 79978, un descendant et aucun résidu. Ils couvrent staging/payload/cleanup, checkpoints/crash/recovery/idempotence/révisions, historique/undo/redo/rétention, autorisation/audit/capacité bulk. Les compteurs 10000 entrées relèvent ici des fixtures transactionnelles existantes, pas de la qualification de volume de packs P12.

La passe de conformité V1 trouve deux défauts concrets et des lacunes de preuve ; aucun commit P09 n'est encore autorisé par cette qualification :

1. Un vrai JournaledAuthoringTransaction dans la fixture mémoire BulkTransactionFixture réalise 1282 promotions et produit un reçu applied, puis P06 accepte une projection de 249696 octets. ResourcePackJobService la refuse au-delà de 240 Kio et publie failed/resource_pack.result_too_large/phase recoveryRequired, sans result. La projection canonique accepte jusqu'à 256 Kio. Sonde `/tmp/p09-spec-budget-probe.dart`, SHA256 53149a4541700290c836eda808775ccbb46c5e67abf384b44e819bf5ce8d9372 ; log `/tmp/p09-spec-budget-probe.log`. Oracle transaction/projection/job réel, gateway mémoire ; aucun import natif de 1282 fichiers prétendu.
2. Le transport JSONL accepte un id de corrélation sans maximum. Une petite fixture recovery_status reçoit une requête de 262295 octets sous la limite générique de 1 Mio et émet un succès de 262246 octets, au-delà des 262144 promis. Sonde `/tmp/p09-spec-jsonl-envelope-probe.dart`, SHA256 0bf66ffc63eba8a909d6ddcdb4445c7f41d7ca61b05ff8eb0f9bbb6e509361e2 ; log `/tmp/p09-spec-jsonl-envelope-probe.log`. Ce défaut hérité du canal générique doit être fermé pour sa nouvelle route P09 ; aucun gros binaire n'est nécessaire pour le reproduire.

La revue demande aussi les preuves transport signées de pagination, reconnexion/replay, erreur tardive, jobs d'historique et annulation contrôlée, ainsi qu'une contrepreuve de reçu resumed altéré. Les vrais bin/MCP courants ne couvrent encore qu'une partie de ces chemins ; les preuves directes ne les remplacent pas. L'auteur prépare un complément minimal de tests sans nouveau hook produit, et corrige les deux budgets via les contrats existants. Les sondes de revue restent immuables pour le candidat suivant. Agrégat DOING, pas d'approbation de conformité ou qualité, aucune revendication de vert global.


### Correctifs et gel final P09 V3t

La revue de conformité V1 reste NON CONFORME dans l'historique ; ses deux sondes sont conservées sans modification. V2 raccorde seulement la projection et la corrélation : la fast path des reçus pack/historique doit tenir dans 240 Kio sous forme JSON et sous forme échappée, avec 16 Kio réservés à l'enveloppe ; sinon le même mécanisme P06 produit diffRef/payloadRef. Aucun nouveau format ni hausse de quota. L'oracle de 1282 promotions conserve applied et donne une projection de 838 octets avec job succeeded. Le worker refuse un id dépassant 128 octets UTF-8 avant de le recopier, avec le sentinel canonique existant requestId=invalid ; l'oracle de 262295 octets d'entrée reçoit une erreur de 271 octets. Logs indépendants `/tmp/p09-spec-budget-probe-v2.log` et `/tmp/p09-spec-jsonl-envelope-probe-v2.log`, exit 0, aucun résidu.

La même revue caractérise un dernier chemin du défaut de budget : start_apply admet un plan ordinaire, auquel la compaction pack/history ne s'applique pas. Une vraie requête resource.family.create sur un projet valide contenant un nom de famille de 124000 caractères publie new-family puis annonce failed/result_too_large. Sonde supplémentaire figée `/tmp/p09-spec-ordinary-budget-probe.dart`, SHA256 339330b00b12e103b9454b85c768fb6bfe6c00b28852b5c66359fe0d5c767890 ; RED `/tmp/p09-spec-ordinary-budget-probe-v2.log`. V3 exige la provenance pack canonique via resourcePackRequiresJob avant applyMutation, puis recontrôle l'annulation. Le canal spécialisé refuse donc un plan ordinaire avant écriture. GREEN indépendant `/tmp/p09-spec-ordinary-budget-probe-v3.log` : projectHasNewFamily=false, job failed/plan_kind_invalid/phase failed, sans recoveryRequired. Le nouveau test API vérifie les octets de projet identiques, puis prouve que le même plan/opération reste applicable par le canal ordinaire. Ce raccord ferme le défaut initial sur toutes les opérations admises par le port, sans changer les mutations ordinaires.

Le HEAD partagé avance séparément vers e84ee98d008c9b3ac2ba6c8bfd9e7f82e3cb2e33, commit étranger de rencontres interactives, 42 chemins. Le parent vérifie qu'il ne contient aucun hunk P09, actualise la copie privée avec les seuls blobs committés et applique sans fuzz ses trois deltas partagés (registry, parité, catalogue). Aucun rebase ou autre écriture Git n'est effectué pour cette actualisation. Reçu `/tmp/p09-current-base-update.json`, 9686 fichiers réguliers HEAD. La regeneration describe ajoute exactement trois champs déjà committés au HEAD (interactiveEncounters et deux extensions encounterTables), distincts de P09 ; `/tmp/p09-current-base-golden-delta.json`. Golden final SHA256 aba103056b77cced27afa507a73016ddc6ddfacb8666da4b8e49da99ef3d73d7.

Le complément de tests utilise deux parcours distincts : vrais bin/serveur standards pour les workflows nominaux, pagination, historique et reconnexion ; vrai processus JsonlWorker + API canonique avec le faultInjector déjà existant pour suspendre précisément avant/après réservation et injecter la faute après première promotion. Les gates sont privées au test, pilotées par fichiers et watchers, sans hook produit ni course basée sur un sleep. API/JSONL/MCP couvrent les cinq kinds, query et resources/read, undo/redo/revert/recover, refus legacy, reconstruction, readonly et replay sans nouvelle promotion. Le test de reçu repris altéré accepte les seules différences statut/date/recoveryOutcome=resumed et refuse requestId, extension ou outcome modifiés. Studio reste PARTIAL jusqu'à P10/P11.

Sur le produit V3 et le HEAD actualisé, la qualification parent des 13 fichiers focused donne 106/106 en 57 s, exit 0, `/tmp/p09-qualified-focused-v3.log`, runner 91218, sept descendants et aucun résidu. Analyse No issues found!, `/tmp/p09-qualified-analyze-v3.log`, runner 91088 ; builds AOT produit et worker contrôlé Generated, `/tmp/p09-qualified-build-v3.log` et `/tmp/p09-qualified-controlled-build-v3.log`, runners 90697/90698, deux/trois descendants et aucun résidu. Builds/typecheck MCP V3 passent. Les binaires épinglés sont consignés dans `/tmp/p09-aot-v3.json` : produit SHA256 1efe72fd9a868c3106edda9eecba943d96d6ee71b9109affb95b256d0730d9cc ; worker de test SHA256 479bbb4fc393e9b1f41491545226297f311e7d492d1ca6efa9570102f6a767bf. Les délais produit restent request=15000 ms et worker=10000 ms.

Le premier ensemble MCP V3 donne 13 réussites et quatre échecs en 183,846 s, exit 1, `/tmp/p09-qualified-mcp-v3.log`, runner 91323, 28 descendants et aucun résidu. Le comparateur de schéma lève TypeError lorsque required=[] est absent côté Zod, deux formes équivalentes en JSON Schema. Les trois tests contrôlés perdent la variable POKEMAP_RESOURCE_PACK_TEST_WORKER au passage StdioClientTransport, dont le SDK filtre l'environnement par défaut ; ils relancent involontairement le JIT et expirent à open. Le workflow standard pagination/historique/reconstruction passe. V3t corrige seulement les deux fichiers de test TypeScript : normalisation du tableau required absent et transmission explicite de cette unique variable de test. Aucun produit ou délai n'est modifié ; les binaires précédents restent exacts. L'ensemble MCP est relancé, sans transformer ces quatre échecs en réussite rétrospective.

Gel technique final composé : `/tmp/p09-parent-final-v3t.json`, dossier privé avelune-p09-final-v3t-i4r5nr4l, manifest SHA256 bcb5e9bf389c015eb8f26e1696de92a1b6e158b22ce355eb753ce6168abcd388. Il contient 52 chemins techniques, dont 18 créations, plus le catalogue et le golden parent, soit 54 chemins vérifiés. Le plan consolidé sera le 55e chemin du commit, après qualification et revues ; aucun nouveau Markdown. Manifest produit V3 fdfff65ab45ac4da82ce4e3f160a310d056f741a8edcca64603c0b3a817c90ae, delta de test V3t 04c8167a372bc77ae7ac9573dc75810115970de6ce081400b4de53f9e7c8808f. La conformité globale et la qualité restent en attente ; aucun commit P09 à ce point.


### Inventaire final des zones P09

Les sources et les diffs Git restent la preuve canonique ; aucun contenu intégral n’est recopié. Le manifest final porte chaque SHA. Les 54 chemins ci-dessous et ce plan consolidé constituent le périmètre préparé de 55 chemins, sous réserve de la revue qualité. Aucun modèle, gameplay, rendu ou workflow CI étranger n’est inclus.

| Chemin | État | Zones et motif / impact attendu |
|---|---|---|
| packages/map_authoring/lib/src/api/resource_pack_transfer_api.dart | Créé | ResourcePackTransferApiPort, contrats des 18 verbes, capacité, schéma et cinq kinds temporaires. |
| packages/map_authoring/lib/src/api/local_resource_pack_transfer_api.dart | Créé | Composition des jobs, sélections révisionnées, pages/URI possédées, préconditions, export segmenté, récupération et fermeture ; garde de provenance avant start_apply. |
| packages/map_authoring/lib/src/application/resource_pack_job_service.dart | Créé | ResourcePackJobService/Context : états, événements, démarrage, barrière, annulation, résultat immuable et drain partagé. |
| packages/map_authoring/test/application/resource_pack_job_service_test.dart | Créé | États, cancel, close, pins, immuabilité et noms de jobs. |
| packages/map_authoring/test/application/resource_pack_transfer_api_test.dart | Créé | Isolation/roots, étapes du transfert et refus d’un plan ordinaire avant écriture. |
| packages/map_authoring/test/application/resource_pack_job_lifecycle_test.dart | Créé | Deux handles, réservation réelle, pending, readonly, recovery et replay. |
| packages/map_authoring/test/application/resource_pack_selection_test.dart | Créé | Filtres P02/familles/libellés, choix cachés et budgets échappés. |
| packages/map_authoring/test/application/resource_pack_preparation_cancellation_test.dart | Créé | Annulation au deuxième chunk, zéro promotion/journal et ownership de la source. |
| packages/map_authoring/test/tooling/jsonl_resource_pack_flow_test.dart | Créé | Vrai bin standard, pagination/historique/reconstruction, refus legacy et bornes ASCII/UTF-8. |
| packages/map_authoring/test/support/resource_pack_transport_fixture.dart | Créé | Génération rerunnable de la petite fixture native et du fichier .aveluneassets original. |
| tools/pokemap_mcp/src/tools/resource_packs.ts | Créé | Schémas Zod des verbes et enveloppe MCP détaillée unique, avec plafond réel. |
| tools/pokemap_mcp/test/resource_pack_stdio.test.ts | Créé | MCP réel, cinq kinds/resources/read, lifecycle/reconnexion/historique/cancel/fautes et schéma strict. |
| packages/map_authoring/lib/src/contracts/job_contracts.dart | Modifié | Validation précise des noms resource_pack.* dans les DTO de jobs existants. |
| packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart | Modifié | Attachement readonly/recovery, révision capturée, ports packs, hooks transactionnels, historique et replay durable avant résolution du plan. |
| packages/map_authoring/lib/src/infrastructure/local_resource_pack_store.dart | Modifié | Pins mémoire immédiats et durée de possession des sources durant les jobs ; isolation du travail d’inspection. |
| packages/map_authoring/lib/src/domains/assets/resource_pack_import_preparer.dart | Modifié | Inspection/certification par worker P04, préparation canonique et possession des archives/plans. |
| packages/map_authoring/lib/src/domains/assets/resource_pack_projection.dart | Modifié | Projection des entrées natives et métadonnées de sélection/export, sans confondre références natives et portables. |
| packages/map_authoring/lib/src/domains/assets/resource_pack_actions.dart | Modifié | Raccord du préparateur courant à l’unique action canonique resource_pack.import, paramètres inchangés. |
| packages/map_authoring/lib/src/transactions/journaled_transaction.dart | Modifié | Garde pending sous verrou, contrôles coopératifs durant préparation et barrière juste avant réservation. |
| packages/map_authoring/lib/src/transactions/authoring_payload.dart | Modifié | Décorateur transitoire de payload emprunté : contrôle par chunk, identité et ownership conservés. |
| packages/map_authoring/lib/src/transactions/local_transaction_file_gateway.dart | Modifié | Queue de writers par racine canonique et propagation de l’arrêt de préparation ; changements étrangers de ctime exclus. |
| packages/map_authoring/lib/src/security/secure_mutation_executor.dart | Modifié | Propagation des hooks et comparaison stricte du reçu récupéré avec l’historique canonique. |
| packages/map_authoring/lib/src/security/secure_recovery_executor.dart | Modifié | Raccord des callbacks canoniques de récupération au cycle du job. |
| packages/map_authoring/lib/src/history/undo_service.dart | Modifié | Propagation de préparation/barrière aux opérations undo/redo canoniques. |
| packages/map_authoring/lib/src/history/revision_revert_service.dart | Modifié | Propagation de préparation/barrière au revert canonique. |
| packages/map_authoring/lib/src/transactions/recovery_service.dart | Modifié | Classification canonique des opérations pack pending et reprise explicite. |
| packages/map_authoring/lib/src/api/authoring_result_projection.dart | Modifié | Segmentation binaire P06, lecture SHA bornée et compaction des reçus pack/historique selon budget du job et JSON échappé. |
| packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart | Modifié | Identité/attachement nécessaires aux sessions en lecture seule avant snapshot natif complet. |
| packages/map_authoring/lib/src/api/authoring_read_api.dart | Modifié | Découverte des contrats de transfert et routage des cinq vues temporaires avant lecture native. |
| packages/map_authoring/lib/src/registry/resource_kind_registry.dart | Modifié | Descripteurs et routes query des cinq kinds de session, sans listing global. |
| packages/map_authoring/lib/src/tooling/jsonl_worker.dart | Modifié | Canal resource_pack, refus du bulk synchrone, fermeture des sessions et corrélation UTF-8 bornée. |
| packages/map_authoring/bin/pokemap_authoring.dart | Modifié | Composition du transfert et finally de fermeture sur EOF. |
| packages/map_authoring/lib/map_authoring.dart | Modifié | Barrel public des contrats/jobs/transferts. |
| packages/map_authoring/lib/map_authoring_api.dart | Modifié | Barrel des ports et contrats de transfert. |
| packages/map_authoring/lib/map_authoring_local.dart | Modifié | Barrel des adaptateurs locaux de transfert. |
| tools/pokemap_mcp/src/server.ts | Modifié | Enregistrement de l’outil MCP de transfert. |
| tools/pokemap_mcp/src/tools/read_only.ts | Modifié | Projection bornée des queries MCP sur les kinds temporaires. |
| tools/pokemap_mcp/src/resources/read_only.ts | Modifié | Routage des URI temporaires et enveloppe resources/read bornée. |
| tools/pokemap_mcp/test/conformance_security.test.ts | Modifié | Liste d’outils : 14 sur HEAD plus le nouveau transfert, schémas et annotations. |
| packages/map_authoring/lib/src/parity/full_authoring_parity.dart | Modifié | Preuves API/CLI/MCP de l’import et cellules explicites des cinq kinds temporaires ; Studio reste PARTIAL. |
| packages/map_authoring/test/parity/full_authoring_parity_test.dart | Modifié | Parité des nouvelles vues/transport et statut Studio partiel. |
| packages/map_authoring/test/api/resource_pack_compact_result_test.dart | Modifié | Segments binaires, bornes inline/échappées après commit, reconstruction du diff. |
| packages/map_authoring/test/ports/file_backed_payload_store_test.dart | Modifié | Pin immédiat survivant à release/TTL jusqu’au règlement du job. |
| packages/map_authoring/test/support/resource_pack_test_gate.dart | Créé | Barrières de test par watchers et faultInjector existant, sans hook produit. |
| packages/map_authoring/test/support/resource_pack_controlled_jsonl_worker.dart | Créé | Processus JSONL de test composé des mêmes API canoniques avec acteur readonly optionnel et faultInjector. |
| packages/map_authoring/test/support/resource_pack_stdio_client.dart | Créé | Client stdin/stdout de test, polling, historique et fermeture ; injection explicite du binaire de test. |
| packages/map_authoring/test/tooling/jsonl_resource_pack_lifecycle_test.dart | Créé | Trois vrais processus contrôlés : cancel des deux côtés et faute/recovery/replay. |
| packages/map_authoring/test/security/resource_pack_recovered_replay_test.dart | Créé | Normalisations resumed autorisées et refus des champs supplémentaires altérés. |
| tools/pokemap_mcp/test/resource_pack_stdio_support.ts | Créé | Helpers MCP réels, contrôle des budgets et transmission explicite de la seule variable du worker de test. |
| packages/map_authoring/test/tooling/jsonl_worker_test.dart | Modifié | Les cinq kinds temporaires refusent la liste globale ; autres routes et golden conservés. |
| packages/map_authoring/test/registry/action_registry_test.dart | Modifié | Les cinq kinds temporaires rejoignent la liste exhaustive ; défaut cinematic antérieur non masqué. |
| packages/map_authoring/test/domains/assets/resource_pack_actions_test.dart | Modifié | La preuve de l’import passe de l’API seule aux trois transports, avec Editor absent. |
| packages/map_authoring/test/tooling/goldens/describe_and_error.jsonl | Modifié | Golden exact des cinq kinds P09 et des seuls écarts de schéma committés identifiés séparément. |
| pokemap_authoring_api_mcp_action_catalog.md | Modifié | Section transfert : verbes, action canonique, URI/ownership, bornes, refus et preuves ; hunks étrangers exclus. |

Le 55e chemin est ce plan consolidé : tableau d’avancement, audits, décisions, inventaire, commandes, résultats, réserves et verdicts. Les ajouts du catalogue sont isolés sur HEAD ; les modifications étrangères du checkout restent hors index.


### Verdicts finaux P09 et préparation du commit par lot

Le MCP V3t termine 17/17, zéro échec/cancel/skip, 162949.342833 ms, exit 0, `/tmp/p09-qualified-mcp-v3t.log`, runner 93892, 42 descendants observés et aucun résidu. Le catalogue réel de la connexion testée expose 418 actions, 65 kinds et 15 outils. Les délais restent 15000/10000 ms. Le succès ne certifie pas le rechargement de tous les serveurs MCP attachés aux autres conversations.

Les quatre fichiers natifs passent 63/63 en 1 min 27 s, exit 0, `/tmp/p09-qualified-native-packs-v3t.log`, runner 96917, un descendant et aucun résidu ; le trajet de 501 racines atteint redo, reopen verified et dispose. Le groupe final parité/registre/documentation donne 32 réussites et un échec en 36 s, exit 1, `/tmp/p09-qualified-parity-registry-v3t.log`, runner 99877, trois descendants et aucun résidu. Le seul échec est registers every resource kind used by canonical mutations, cinematicMediaAsset absent, action_registry_test.dart:238. La liste P09 passe. La passe indépendante confirme le même défaut dans la base e84ee98 : dialogue_audio_media_actions.dart:27 le déclare et le registre du même commit l’omet. Aucun élargissement cinématique n’est embarqué.

La commande autonome PMCP finale donne mutationActionCount=418, resourceCount=93, blockedOrMissingCount=0, catalogComplete=true, mais transportCertificationComplete=false et itemTransportCertificationComplete=false, exit 1, `/tmp/p09-qualified-pmcp085-v3t.log`, runner 1430, aucun descendant ni résidu. Le bundle Item global reste absent ; aucun reçu n’est fabriqué pour produire un vert global.

Commandes finales exécutées depuis packages/map_authoring, avec le wrapper d’ownership ; le lanceur AOT privé est celui de `/tmp/p09-aot-v3.json` :

~~~text
dart test test/application/resource_pack_job_service_test.dart test/application/resource_pack_transfer_api_test.dart test/application/resource_pack_job_lifecycle_test.dart test/application/resource_pack_selection_test.dart test/application/resource_pack_preparation_cancellation_test.dart test/tooling/jsonl_resource_pack_flow_test.dart test/tooling/jsonl_resource_pack_lifecycle_test.dart test/contracts/job_contract_test.dart test/tooling/jsonl_worker_test.dart test/tooling/jsonl_resource_library_flow_test.dart test/ports/file_backed_payload_store_test.dart test/api/resource_pack_compact_result_test.dart test/security/resource_pack_recovered_replay_test.dart --concurrency=1 --reporter expanded
dart test test/domains/assets/resource_pack_actions_test.dart test/domains/assets/resource_pack_reimport_test.dart test/domains/assets/resource_pack_export_test.dart test/domains/assets/resource_pack_transaction_test.dart --concurrency=1 --reporter expanded
dart test test/parity/full_authoring_parity_test.dart test/registry/action_registry_test.dart test/tooling/registry_documentation_test.dart --concurrency=1 --reporter expanded
dart run tool/pmcp085_conformance.dart
dart analyze
dart compile exe bin/pokemap_authoring.dart -o /tmp/p09-qualified-authoring-v3
dart compile exe test/support/resource_pack_controlled_jsonl_worker.dart -o /tmp/p09-qualified-controlled-worker-v3
~~~

Depuis tools/pokemap_mcp : npm run check, npm run build, puis la commande suivante avec les binaires épinglés, sans réécriture des tests ni des délais :

~~~text
node --import tsx --test --test-concurrency=1 test/resource_pack_stdio.test.ts test/conformance_security.test.ts test/authoring_client.test.ts test/resource_library_stdio.test.ts
~~~

Verdicts indépendants :

- Audit / Architecture : raccords ciblés à l’ouverture, à la garde canonique sous verrou et à la fermeture ; aucun nouveau framework nécessaire. Les constats initiaux sont traités.
- Implémentation : candidat produit V3 et delta de tests V3t livrés, sources gelées, aucun Git/Notion/Markdown par l’auteur.
- Conformité : CONFORME P09, aucun finding restant ; les trois sentinelles sont inchangées et corrigées, les preuves transport manquantes ont été ajoutées.
- Tests : favorable sur le delta P09 ; 106/106 focused, 17/17 MCP, 63/63 natifs, 32/1 parité/registre avec l’échec antérieur explicite. Les 108 empreintes gel+qualified sont vérifiées après tests.
- Build / Validation : validé pour authoring Dart et MCP, analyse sans diagnostic, deux AOT Generated, check/build TS exit 0 ; délais produit conservés.
- Qualité / Critique finale : APPROUVÉE, aucun P1/P2 concret. Une hypothèse selection.create/close est testée indépendamment et ne produit pas de fuite : selectionReturned=true, cachedBytesAfterCloseAndExpiry=0 après collecte à +25 h. Sonde `/tmp/p09-quality-close-selection-probe.dart`, SHA256 c6aa2e4714368b4c718b348acadd61d6fbd6c1f09195820fe573fffff4c060fd, `/tmp/p09-quality-close-selection-probe.log`, exit 0, runner 1180, aucun descendant ni résidu. Le manifeste final et ses 54 blobs sont revérifiés en fin de revue.

Auto-critique et limites : les tests contrôlés injectent leurs fautes dans une fixture canonique privée distincte du bin standard, également exercé. Les campagnes de volume/RSS et les vrais parcours Studio/Player restent P10–P12 ; P13 reste différé. L’annulation reste coopérative bounded=false, sans SLA inventé. Les réserves globales P05, l’échec cinématique antérieur, la certification Item globale absente et les premiers logs RED/échecs de harnais restent visibles. Aucune galerie, aucune CI coûteuse, aucune copie de projet utilisateur, aucun push/rebase.

Le commit local autorisé est `da27b76c50c43a745a003f2e16fe80a7b9e3620e`, parent `e84ee98d008c9b3ac2ba6c8bfd9e7f82e3cb2e33` : les 54 blobs qualifiés et ce plan, soit 55 chemins, 6736 insertions et 461 suppressions. L’état précommit comptait 308 chemins dirty, conservés dans `/tmp/p09-precommit-status.bin` et `.txt`. Le staging a reconstruit les fichiers partagés depuis HEAD et les seuls hunks P09, sans recopier leurs changements étrangers vivants. Chaque blob de l’index puis du commit, son parent et ses chemins ont été vérifiés ; reçu `/tmp/p09-commit-receipt.json`. État final : index vide, 256 chemins dirty étrangers préservés, aucun push/rebase. Ces résultats et le SHA ont été projetés puis relus dans Notion ; P09 proposé TO REVIEW, agrégat DOING, prochaine étape P10. La décision DONE appartient à Yoahn.

### Démarrage P10 — Installation Studio

Avant modification, HEAD `da27b76c50c43a745a003f2e16fe80a7b9e3620e`, index vide et 256 chemins dirty. Sauvegarde source/configuration de 5505 fichiers : `/tmp/avelune-p10-before.json`. Copie de qualification créée depuis les seuls 9704 fichiers réguliers suivis du HEAD, vérifiés contre leurs blobs Git : `/tmp/p10-qualified-probe.json`, sans overlay du checkout partagé. Le correctif étranger de chargement régional dans `workspace_lifecycle_binding.dart` est une baseline protégée, distincte des futurs raccords de session P10. Audit/Architecture et Implémentation démarrent par une lecture séparée ; aucun résultat UI ou natif P10 n’est encore revendiqué.

Verdict Audit / Architecture indépendant : favorable à une intégration sur P09 sans refonte. Réutiliser les guards de `ResourceNavigation` et la queue non réentrante `withResourceMutation`, sans rappeler une réconciliation qui reprendrait cette queue depuis son propriétaire. Une demande `cancel` doit attendre l’état `cancelled` ; `failed` avec phase `recoveryRequired` ne rend pas la fermeture possible. Convertir le reçu réellement appliqué, avec diff paginé et résolution des identités par `resourceStorageKeys` : `path: '/'` du diff ne désigne pas un fichier. Les révisions de snapshot canonique et de manifeste Studio restent distinctes. Le fingerprint par flux réutilise `NarrativeProjectFingerprintBuilder` et `LocalProjectFileReader.openRead`. Relecture et reprojection ne relancent jamais apply. Sélection serveur indépendante de la grille native, curseurs renouvelés après patch, réponses d’ancienne session rejetées et `alreadyInstalled` explicite. Audit initial de l’implémenteur concordant ; feu vert donné après ce checkpoint, sans commentaires code nouveaux ni changement P11/P13.

Baseline HEAD : `flutter pub get --offline` passe, runner 11268, log `/tmp/p10-head-pub-get.log`, trois descendants et aucun résidu possédé. `flutter analyze --no-pub` passe avec `No issues found! (ran in 46.8s)`, exit 0, `/tmp/p10-head-analyze.log`, runner 11512, un descendant et aucun résidu. Les deux suites de bibliothèque donnent **8/8**, `All tests passed!`, 1 min 46 s, exit 0, `/tmp/p10-head-library-tests.log`, runner 11513, 16 descendants observés et aucun résidu possédé ou laissé sans confirmation.

### Premier gel P10 : qualification technique et écarts de conformité

Le candidat V1 est figé dans `/tmp/p10-frozen-v1-candidate.json` : 28 chemins techniques, dont 10 nouveaux, 2387 insertions et 13 suppressions, sans baseline étrangère. Manifeste SHA256 `57160a6f6b0e444e4bbaecc1765b67c0cdbe7375a2d3517bc57d4d795f890d2c`, patch `245ab3a6dbb7506796830ddf1bdffaa53fa91beded56f4634a4be7f2b0d1080d`. Le parent a vérifié les 56 blobs gel+copie qualifiée et les 9704 fichiers HEAD : aucun changement inattendu hors des 28 overlays. Reçu `/tmp/p10-parent-candidate-v1.json`.

Les premiers RED conservent l'absence d'API/action UI et le refus canonique de libérer une preview. Le host réel a ensuite découvert l'alias snapshot `assetLogical` pour des ressources nommées `asset` dans le diff ; la résolution corrigée vérifie l'empreinte du reçu. Les essais à 501 puis 701 alias restent des reçus inline, pas des preuves de compaction. Le host à 1282 alias distincts produit réellement `diffRef`, vérifie la forme compacte et rouvre les 1282 tilesets, 4/4, 59 s, `/tmp/p10-native-host-green.log`. Le contrôleur, la petite fenêtre 700×500 avec texte ×1,8, Escape, l'annulation et une vraie faute après promotion suivie de la reprise de l'opération originale passent 11/11 dans `/tmp/p10-ui-recovery.log`.

Qualification parent V1 sur HEAD+gel, commandes possédées : les six suites Studio signées et les trois régressions `resource_navigation_receipt_recovery_test`, `resource_reconciliation_retry_test`, `resource_transaction_guard_test` donnent **34/34**, 1 min 43 s, exit 0, `/tmp/p10-qualified-studio-v1.log`, runner 28318, 12 descendants. `flutter analyze --no-pub` donne `No issues found! (ran in 45.6s)`, exit 0, `/tmp/p10-qualified-analyze-v1.log`, runner 28323, quatre descendants. Les tests `resource_pack_transfer_api_test` et `resource_pack_selection_test` donnent **4/4**, 21 s, exit 0, `/tmp/p10-qualified-api-v1.log`, runner 28319, deux descendants. `npm run check` passe, `/tmp/p10-qualified-npm-check-v1.log`. Aucun résidu possédé ou PID laissé sans confirmation. L'info étrangère du checkout vivant dans `spatial_map_editor_guidance.dart:7` n'est pas présente dans la copie HEAD qualifiée.

Ces succès ne clôturent pas P10 : la revue SPEC relève l'absence du résumé complet d'identité du pack et de la ventilation nouvelles/réutilisées/copies/octets, du filtre famille et de l'explication des dépendances par ressource choisie, ainsi que le picker annulé qui laisse la boîte ouverte. Les conflits bruts et l'absence de test widget du choix copie doivent aussi être corrigés. Une contrepreuve de fermetures concurrentes est préparée hors dépôt, SHA256 `5b7c3ba49c271064644d391b5284a6059b90388f1f2c4c605ecbdcd1e2662445`. Le test compact doit renforcer l'égalité exacte des chemins et les gardes doivent être prouvées via le shell existant. Les builds/transports actualisés, le parcours natif visible et la revue qualité finale attendent le candidat corrigé. Aucun commit P10, agrégat DOING.

Verdict SPEC V1 final : **NON CONFORME**, cinq findings P2. La sonde `/tmp/p10-spec-close-probe_test.dart` ci-dessus est exécutée sans modification du gel : première fermeture `true`, seconde `StateError(resource_pack.handle_unknown:selection)`, libérations `[selection, selection, inspection, archive]`. RED 0/1, exit 1, `/tmp/p10-spec-close-probe.log`, runner 31289, deux descendants, aucun résidu ni PID incertain. La fermeture doit partager sa Future en vol. Le bilan actuel utilise à tort l'union historique `installation.resources` lors d'un import incrémental et omet les motifs-supports : V2 doit décrire la sélection préparée réelle. La passe Tests confirme que ses succès V1 ne couvrent pas ce contre-exemple et ne suffisent pas à la conformité. Le premier audit avait validé les raccords de jobs/reçus sans vérifier toutes les données promises par le parcours Studio ; V2 complète le contrat canonique plutôt qu'un calcul parallèle dans l'interface. Feu vert donné pour les cinq corrections groupées, les gardes du shell et la sentinelle de dernière page ; sonde concurrente conservée inchangée pour le rejeu. Aucun build ou essai natif V1 n'est revendiqué, ni lancé inutilement avant ces corrections.

### Préparation native P10 pendant les corrections V2

Une courte fenêtre de gel source est coordonnée avec le chantier terrain déjà autorisé, de02:40:32 à02:41:56 UTC le17octobre : le parent vérifie5658 fichiers Dart sans variation, reçu `/tmp/p10-external-source-freeze-receipt.json`. La qualification terrain de l'autre chantier reste étrangère à P10. Le gel est levé et le writer reprend ; l'autre chantier confirme ensuite son app possédée fermée et Marionette déconnecté. Aucun projet ou jeu utilisateur n'est fermé par ce chantier.

L'audit natif indépendant relève qu'une miniature ou l'ouverture d'une famille ne prouve pas un usage. La fixture de transport2px n'a aucune carte ; sa bordure et son modèle exigent une cible3D, tandis que ses tileset, éléments et environnement sont2D. Deux cibles originales et jetables sont donc préparées hors dépôt, avec cartes16×12, cellules16px et atlas32×32 à frames distinctes, ainsi qu'un modèle GLB original recentré. Les sept kinds sont portés par huit ressources et treize supports, exportés par le service canonique dont les sources sont vérifiées identiques à HEAD. Fichier18776octets, SHA256 `c72b066eaab2e89e9e185b2a48dae42335493ab22c920d6788e9574d62c41332`, reçu et empreintes avant usage `/tmp/p10-native-usage-fixture.json`. Aucune galerie ni donnée utilisateur copiée.

Le générateur QA privé `/tmp/p10-create-native-usage-fixture.dart` a d'abord trois erreurs de construction Dart, puis un refus de frame personnage hors image ; le passage correct au binding `sourceAssetId` utilise des coordonnées pixel explicites. Logs conservés `/tmp/p10-native-usage-build.log`, `...-second.log`, puis `...-third.log` exit0, runner48117, zéro descendant ou résidu. Ces essais de génération ne sont ni des tests produit P10 ni une preuve native. Le parcours à exécuter sur V2 sera import/réouverture puis peinture d'atlas, pose de décor, peinture Smart Tile, génération d'environnement appliquée et pose de personnage en2D ; modèle posé et bordure tracée en3D ; chaque résultat devra être visible, enregistré puis rouvert. Aucun de ces gestes n'est encore revendiqué.

### Gel P10 V2 et qualification parent

Gel auteur `/tmp/p10-frozen-v2-candidate.json` :37chemins,11créations, manifest `d2922912e39a189baf22d0c5c8162b1839c9620739a9ebd23e3e703863743a4d`, patch `f9b42717930fd8af92fa3a31c165b16232ae66458e011e8c25ad9544e9053d3f`, base `da27b76c5`. Les37baselines sont propres et les blobs projetés sont vérifiés ; copie9715fichiers, sans overlay étranger. Le catalogue authoring P10 est ensuite ajouté par un overlay parent sur HEAD, en conservant ses hunks étrangers vivants. Gel composé38chemins `/tmp/p10-parent-final-v2.json`, manifest `94995ef741896fadef8e4a56c60942f6b361040f9a924d3a6b04bb6c8d6e736f`. Le golden read-only régénéré est strictement identique, delta `[]` : son worker n'injecte pas le transfert ; aucune preuve de schéma composé n'en est déduite et aucun golden source n'est modifié.

La qualification indépendante parent donne21/21pour le graphe,15/15pour API/sélection/réimport en1:01, analyses Studio et authoring sans diagnostic, deux AOT Generated et check/build TypeScript exit0. Binaire produit SHA256 `1b73908ab670f04e7b34cca99c6e080f4e2c32e7e9aa57e4f9bf0d631873fa6d`, contrôlé `f2effe5fcd8a79936b7120ce5f7317c50171eac3e7d47b0f054cde39e7078263`, `/tmp/p10-aot-v2.json`. La CLI composée décrit418actions,65kinds et les quatre sections. Le launcher épinglé ne modifie aucun délai ni test.

Premier run Studio groupé :39réussites/1échec, timeout2min du bulk1282puis projection nulle après timeout, `/tmp/p10-qualified-studio-v2.log`. Ce log reste un échec. Le même bulk, source et timeout inchangés, passe seul1/1en57s, `/tmp/p10-qualified-bulk-isolated-v2.log`. Toute la sélection de dix fichiers, sonde close immuable comprise, est rejouée en `--concurrency=1 --reporter expanded` :40/40en3:50, exit0,14descendants, aucun résidu, `/tmp/p10-qualified-studio-sequential-v2.log`. Cause définitive du premier timeout non établie ; ne pas transformer le rejeu en succès rétroactif du run initial.

Les cinq fichiers JSONL/lifecycle/worker/parité/documentation passent50/50en1:04, exit0, `/tmp/p10-qualified-jsonl-parity-v2.log`. Les quatre fichiers MCP réels passent17/17, zéro fail/cancel/skip,137478.99125ms, exit0,34descendants et aucun résidu, `/tmp/p10-qualified-mcp-v2.log`. La connexion testée expose418actions/65kinds ; cela ne certifie ni toutes leurs sémantiques ni le rechargement de toutes les sessions. Les réserves globales P05/cinématique/Item restent distinctes.

Core : analyse des deux fichiers P10 sans diagnostic. L'analyse complète du candidat donne129infos,0warning/error, exit0, `/tmp/p10-qualified-core-analyze-v2.log`. Un premier contre-run partiel HEAD est inéquivalent (504diagnostics, notamment chemins relatifs manquants) et reste conservé. La baseline est reconstruite avec les9704fichiers réguliers HEAD vérifiés et le même package_config à self-root relatif : analyse complète exit0,129infos exactement identiques, `/tmp/p10-core-head-complete-analyze-v2.log` et `/tmp/p10-core-complete-analyze-comparison-v2.json`. Aucun diagnostic Core nouveau, sans annoncer un package intégralement sans infos.

Avis SPEC technique V2 favorable, cinq findings V1 corrigés et aucun P1/P2 confirmé à cette passe ; gate natif encore PARTIAL. Une sonde additionnelle prouve le refus de fermeture pendant `selection.create`, puis sa réussite avec tous les handles libérés : `/tmp/p10-spec-selection-close-barrier-v2_test.dart`, SHA256 `89e50957a75a7f0df87b6fa6c06cea4e790679ef3d25eda127bbf8442427ac88`,1/1, exit0. L'ancienne sonde exploratoire attendait à tort une fermeture immédiate et n'est pas un défaut produit. Avis Tests/Build indépendant favorable sur les preuves ciblées et les hashes, avec native/qualité finale encore ouverts ; vérification indépendante des9704fichiers,283868930octets hors overlay, zéro écart.

### Premier passage natif P10 V2 — import acquis, usages encore ouverts

L'app privée est compilée et lancée par `flutter run -t dev/marionette_main.dart -d macos --debug --no-pub` avec les defines exacts de cible et de garde de capture, `/tmp/p10-native-studio-2d-v2.log`. Build `Built …/Avelune Studio.app`, backend MetalSDF. Les warnings de dépendances Swift sont conservés. L'extension debug confirme le chemin QA2D exact ; capture et éléments interactifs concordent. `get_logs` Marionette retourne `Server error` : limitation d'observation déclarée, journal `flutter run` capturé en remplacement, sans exception de démarrage trouvée. Le recorder n'est pas démarré ; sa garde existante est lue seulement, les images sont enregistrées dans la racine QA propre.

Annulation réelle du picker : retour à la bibliothèque vide, route fermée, cinq fichiers de fixture d'origine byte-identiques. Choix OS du pack18776octets puis sélection totale8 ; filtre Intérieur affiche5résultats sans perdre les8choix. Preview canonique :8ressources/13supports/17dépendances sources comprises,21nouvelles définitions,0copie/réutilisation,1664octets sources+25licence,3114sorties+25267métadonnées=28381octets prévus,1425nouveaux blobs. Application réelle terminée, huit cartes de bibliothèque visibles. Relecture disque :1tileset,2éléments,1modèle,1personnage,1terrain,1bordure,1environnement ; carte et archive inchangées. Reçu `/tmp/p10-native-2d-after-import-v2.json`,25fichiers natifs, captures00–04 sous la fixture QA. L'app est quittée et Marionette déconnecté : runner64189exit0,212descendants observés, aucun résidu. Relance froide de la même cible en cours dans `/tmp/p10-native-studio-2d-reopen-v2.log` ; aucun usage de pinceau ni réouverture visible n'est encore revendiqué.

Deux écarts de présentation observés nativement restent à corriger après ce passage : le nom de bordure du preview lit `draft.definition.name` alors que le pack publié porte `latestPublished.definition.name`, d'où le fallback erroné « Support d'édition · Bordure ». Après succès, le bilan préparé reste affiché avec «0présentes dans le projet» et «total à écrire», sans préciser sa photographie avant import. Corriger le getter du nom publié et rendre les libellés explicitement antérieurs/prévus, avec tests ciblés ; ne pas recalculer un bilan parallèle dans Studio. Aucun commit P10, aucune clôture SPEC ou qualité finale à ce stade.

### P10 V2 — usages 2D enregistrés et réouverture froide

La première relance de la cible exacte rouvre les huit ressources importées. Par les commandes et gestes réels de Studio, une tuile d'atlas est peinte en2,2, un décor posé en4,2, le preset Smart Tile peint en2,6, une zone d'environnement de25cellules génère13décors puis est appliquée, et le personnage partagé est posé en6,8. Chaque étape est enregistrée et l'interface affiche « Enregistré ». L'inspecteur du personnage affiche « Sprite partagé : Original » et « Carte : Atelier2d ·6,8 ». Aucun JSON de projet n'est écrit directement par le harnais.

La corroboration disque retrouve14décors (un placé et treize générés), une entité avec son `characterId` importé, la cellule sémantique Smart Tile98, la tuile d'atlas34 et les13références de génération dans la zone de25cellules. Reçu complet avant fermeture `/tmp/p10-native-2d-uses-before-reopen-v2.json`. La seconde session est quittée normalement : `/tmp/p10-native-studio-2d-reopen-v2.log`, exit0,30descendants observés, aucun résidu possédé ni PID incertain.

Une nouvelle compilation/lance native, `/tmp/p10-native-studio-2d-uses-reopen-v2.log`, rouvre ensuite la même carte ; les cinq usages sont visibles et le personnage conserve son sprite partagé dans l'inspecteur. Les empreintes carte `4b89b261ed1776713aa6208cd79adaf4ab24578eaa3f097ed956dfc517763075`, projet `888ee72578a381f6600af20fc94d39eb4a6d5746cce117d1e178e59b617b8e06` et archive `c72b066eaab2e89e9e185b2a48dae42335493ab22c920d6788e9574d62c41332` sont exactement identiques avant/après relance, reçu `/tmp/p10-native-2d-uses-after-reopen-v2.json`. Captures05–11 dans la racine QA propre, notamment vue des cinq usages et inspecteur après relance. Fin normale du runner74464, exit0,23descendants observés, Marionette déconnecté, aucun résidu possédé ni PID incertain. Le créneau natif est rendu au chantier terrain autorisé pendant les corrections de présentation.

Les usages 2D de P10 sont acquis sur V2 ; aucun mouvement, collision jouée, animation visible, autonomie Player ou mesure RSS n'en est déduit. Les usages modèle et bordure3D restent ouverts. Feu vert donné au writer pour les deux seuls correctifs de présentation et leurs tests ciblés, suivis d'un nouveau gel V2t ; les sources des autres chemins restent inchangées. P10 n'est pas committé et l'agrégat reste DOING.

### Gel P10 V2t — deux corrections de présentation

Le getter canonique utilise le nom de `latestPublished.definition` pour une bordure publiée sans draft ; le bilan Studio est désormais intitulé « Bilan préparé avant cet import » et précise « présentes avant cet import » et « écritures prévues ». Les compteurs et le même objet `preparedSummary` sont conservés après succès. Quatre fichiers seulement diffèrent de V2 : `resource_pack_import_review.dart`, `resource_pack_transfer_api_test.dart`, `resource_pack_transfer_dialog.dart` et `resource_pack_transfer_dialog_test.dart`. Les deux RED reproduisent les constats natifs exacts ; GREEN API4/4 et widgets5/5, rejoués dans la copie qualifiée avec les mêmes résultats. Les premiers runs Dart directs n'avaient pas de suivi owned-run ; logs conservés tels quels. Le rejeu qualifié API4/4 possède le reçu runner78820,2descendants, aucun résidu ; widget5/5 runner78484,12descendants, aucun résidu. Deux analyses ciblées sans diagnostic.

Gel auteur `/tmp/p10-frozen-v2t-candidate.json`,37chemins/11créations, manifest `93fd29ba39150b8398b167a6eda97e88f888f67b3e7b32c127fd0aa8c87c5ca9`, patch `7a47e0c67f883ae668e0820dc22a90d04e0c8256cffd024fece79c253c4b85cb`, delta4chemins SHA256 `34956e9a622448781323516b7190de6c54f4661a1584ab60b0cc2bac4d730b6c`. Gel composé parent38chemins `/tmp/p10-parent-final-v2t.json`, manifest `16d234f2785d8926acfc6233a844ac2dfc1d08e03d5c654b0dc0667511144ba6`. Les9704fichiers HEAD et38overlays sont recontrôlés sans écart, `/tmp/p10-parent-integrity-v2t.json`. SPEC technique du delta favorable, aucun P1/P2 ; clôture toujours PARTIAL avant les deux usages3D et revue qualité après SPEC finale.

Deux AOT V2t sont reconstruits, `/tmp/p10-aot-v2t.json` : produit `0aeb2e82b99ee4e2098214aef779cf7767a5d286a7f5e911cab80fffb47cfffa`, worker contrôlé `0d98d75c00ade7a723324522679a5e14b4b56e7779586c8f453a9d4f7da0a836`. Les deux compilations terminent exit0, respectivement2et3descendants observés, aucun résidu. Le launcher reste limité aux chemins de binaires sans modifier les délais. API et JSONL réels sont rejoués sur ces binaires :8/8,22s, exit0,3descendants, aucun résidu, `/tmp/p10-qualified-api-jsonl-v2t.log`. Build natif V2t debug/Marionette ciblant3D : `✓ Built …/Avelune Studio.app`, exit0,53descendants observés, deux résidus possédés réidentifiés puis récoltés, aucun PID laissé sans confirmation, `/tmp/p10-qualified-native-build-v2t.log`. Cela ne remplace pas le parcours visible3D encore à exécuter. La suite MCP stdio du transfert est rejouée sur les mêmes binaires V2t :7/7,0fail/cancel/skip,157234.700833ms, exit0,37descendants observés et aucun résidu, `/tmp/p10-qualified-mcp-v2t.log`. Les contrats non modifiés et les autres suites MCP restent appuyés par leurs preuves V2 distinctes, sans répéter inutilement ces suites.

### P10 V2t — refus de préparation dans la cible native 3D

Le lancement `/tmp/p10-native-studio-3d-v2t.log` compile et ouvre la cible3D exacte, confirmée par l'extension debug ; la carte vide est visible sous MetalSDF. Le vrai picker ouvre le même pack original18776octets, l'inspection et les attributions réussissent, les huit ressources sont sélectionnées. Le clic « Vérifier l'import » aboutit cependant à « Le pack a été refusé (resource_pack.operation_failed) », avant preview et écriture. Capture12 dans la fixture, inventaire `/tmp/p10-native-3d-prepare-failure-inventory-v2t.json` : carte et manifeste strictement identiques à l'origine, seulement deux locks vides créés. La route se ferme normalement et la bibliothèque reste à zéro résultat.

Ce résultat est un RED natif P10, pas un usage3D acquis. Le code générique provient du normaliseur d'erreur de job pour une exception sans champ `code`, sans stack dans le journal Flutter. Diagnostic systématique demandé au writer en lecture seule, sur copie jetable pour remonter à l'exception avant normalisation ; aucun correctif ni nouveau gel autorisé avant cause prouvée. Le gelV2t reste inchangé et P10 PARTIAL ; aucune revue qualité finale ni commit ne peut encore être revendiqué.

Le diagnostic contrôlé identifie ensuite une erreur de construction de la fixture : `settings.spatialCamera` est absent du manifeste3D créé par le parent. La validation initiale échoue déjà, avant import, avec `ValidationException: A 3D project requires its camera profile.` La stack de préparation est `ProjectValidator.validate`, `validators.dart:114`, appelée par `ResourcePackImportPreparer.prepare`, ligne527. L'exception n'a pas de code ; le normaliseur produit donc le code générique observé. Une copie changeant uniquement ce champ en `SpatialCameraProfile()` passe la validation initiale puis prépare les mêmes8racines/13supports/21définitions en `ready`, archive inchangée. Reçu `/tmp/p10-3d-prepare-diagnostic-receipt.json`, log `/tmp/p10-3d-prepare-diagnostic.log`, runner87578exit0, aucun descendant ni résidu.

Ce RED n'est donc pas attribué au produit. Aucun correctif source ni nouveau gel n'est requis ; V2t reste intact. La cible fautive, les captures et les reçus sont conservés, et une nouvelle cible `target-3d-valid` sera créée par un petit générateur QA typé avec prévalidation. L'ancienne génération complète n'est pas relancée afin de préserver les usages2D déjà acquis. Fin de l'app3D initiale : runner83800exit0,49descendants suivis, un compilateur possédé récolté, aucun PID incertain, Marionette déconnecté ; créneau rendu au chantier terrain autorisé.

### P10 V2u — couverture host 3D et inventaire gelé

La nouvelle cible `target-3d-valid` est créée sans écraser une destination existante, puis prévalidée par `ProjectValidator` et `MapValidator` avant écriture et après relecture disque. Manifeste SHA256 `166399af00fe328203178094409a055c8835ca7dec5fe80e08158c0aa6a5ca95`, carte strictement identique à la cible initiale, inventaires complets2D/ancienne3D/archive préservés. Script `/tmp/p10-create-native-3d-valid-fixture.dart`, SHA256 `b4bcac8d15cb1c3d0df14dc2509a72a0f2dfacbe84d1ce15b5669b2c12a8984a`, reçu `/tmp/p10-native-3d-valid-fixture.json`. Aucun essai visible sur cette nouvelle cible n'est encore revendiqué : la session macOS est verrouillée et la demande humaine de déverrouillage reste en attente.

Un seul fichier de test est enrichi depuis V2t : `resource_pack_import_host_test.dart`. Le helper accepte une carte initiale prévalidée et ferme la session indépendamment du nettoyage de fixture. Le nouveau cas v9/caméra importe les8ressources et13supports par le vrai contrôleur/adaptateur, vérifie les sept kinds et la réconciliation terminée, ferme la session puis recharge avec un nouvel adaptateur. Caméras, ressources, carte et octets persistés sont conservés. Run ciblé1/1en3s, runner91449,5descendants ; fichier complet7/7en34s, runner92513,2descendants, bulk1282passé ; analyse ciblée `No issues found!`, runner94397,1descendant. Tous exit0, aucun résidu, logs `/tmp/p10-qualified-v2u-host-3d.log`, `...-host-suite.log`, `...-host-analyze.log`.

Gel auteur `/tmp/p10-frozen-v2u-candidate.json` :37chemins/11créations, manifest `b2cd2523e2fe5d5adb2f7a97514508e095bbecb91988d4df47076b6d80cb513b`, patch `bd7fbb3bbce45042c6ec713deced0dd7031db46bc3d2235803312a5866e5d693`, delta unique versV2t SHA256 `30c4122b780426f8801902271656935cb716d56dd15fddbee5c18f55b3edd9ff`. Parent composé38chemins `/tmp/p10-parent-final-v2u.json`, manifest `5990b072ee7188792b192a2b4e5be0b12008f8b52eab20f21c91895764511b3f`. Sources produit et AOT strictement identiques àV2t. SPEC du delta conforme, aucunP1/P2,38overlays revérifiés. Le verdict global reste PARTIAL : libellés corrigés visibles, modèle/bordure3D posés/tracés, sauvegarde et réouverture native restent à prouver, puis SPEC et critique qualité finales.

Inventaire technique complet des38chemins du gel, auquel seul ce plan sera ajouté au moment du commit. Les zones indiquent le changement P10 ; les parties étrangères vivantes du catalogue ne font pas partie du gel.

| Fichier | Zones, raison et effet attendu |
|---|---|
| apps/avelune_studio/lib/app/di/resource_providers.dart | Injection du picker et du port canonique dans la session de ressources |
| apps/avelune_studio/lib/app/studio_bootstrap.dart | Composition du picker natif sans lecture globale de l'archive dans les widgets |
| apps/avelune_studio/lib/features/resources/application/resource_pack_transfer_controller.dart | États du transfert, sélection serveur, filtres, préparation, application, reprise et fermeture concurrente partagée |
| apps/avelune_studio/lib/features/resources/data/local_resource_pack_adapter.dart | Session authoring possédée, transfert/query, application unique et acceptation du reçu réellement appliqué |
| apps/avelune_studio/lib/features/resources/data/local_resource_reconciliation.dart | Relecture paginée des chemins certifiés et fingerprint par flux, sans second apply |
| apps/avelune_studio/lib/features/resources/domain/resource_pack_port.dart | Port injectable, picker par chemin, monitoring des jobs et distinction du succès committé non réconcilié |
| apps/avelune_studio/lib/platform/files/native_resource_pack_picker.dart | Sélection native du fichier `.aveluneassets` sans matérialiser ses octets |
| apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_screen.dart | Ownership du contrôleur et raccord aux vrais guards du shell |
| apps/avelune_studio/lib/presentation/features/map_workspace/workspace_close_actions.dart | Fermeture soumise à l'annulation terminale et au reçu restant à réconcilier |
| apps/avelune_studio/lib/presentation/features/map_workspace/workspace_export_binding.dart | Blocage du changement de projet pendant finalisation ou reprise |
| apps/avelune_studio/lib/presentation/features/map_workspace/workspace_session_loader.dart | Chargement de session lié au contrôleur courant, rejet des réponses d'ancienne session |
| apps/avelune_studio/lib/presentation/features/resources/resource_library_header.dart | Action d'import partagée entre bibliothèque et menu compact |
| apps/avelune_studio/lib/presentation/features/resources/resource_library_screen.dart | Transmission des actions du transfert à la bibliothèque |
| apps/avelune_studio/lib/presentation/features/resources/resource_navigation.dart | Busy et propriété du transfert intégrés à la navigation existante |
| apps/avelune_studio/lib/presentation/features/resources/resource_navigation_management.dart | Raccord de fermeture et de mutation, sans nouvelle queue réentrante |
| apps/avelune_studio/lib/presentation/features/resources/resource_pack_selection.dart | Liste virtualisée, filtres contexte/type/famille et sélection totale indépendante des lignes visibles |
| apps/avelune_studio/lib/presentation/features/resources/resource_pack_transfer_dialog.dart | Identité, attributions, bilan canonique préparé, conflits lisibles et clavier/fermeture de route |
| apps/avelune_studio/lib/presentation/features/resources/resource_reconciliation_notice.dart | Relecture après succès connu sans proposer une nouvelle application |
| apps/avelune_studio/lib/presentation/features/resources/resource_workspace_actions.dart | Orchestration de l'import et retour dans la bibliothèque native |
| apps/avelune_studio/lib/presentation/features/resources/resource_workspace_pane.dart | Injection du transfert dans le panneau de ressources existant |
| apps/avelune_studio/lib/presentation/shell/studio_workspace_host.dart | Raccord des dépendances de session au shell |
| apps/avelune_studio/test/application/resource_pack_transfer_controller_test.dart | Sélection10000simulée sans IDs sérialisés, réponses obsolètes, guards, annulation et fermeture partagée |
| apps/avelune_studio/test/presentation/resource_pack_transfer_dialog_test.dart | Vraie route annulée, conflit/copie applicable, bilan complete, petite fenêtre et texte agrandi |
| apps/avelune_studio/test/resource_io/resource_pack_cancellation_host_test.dart | Vrais guards MapWorkspaceScreen : close/switch, réservation, recovery et reçu restant |
| apps/avelune_studio/test/resource_io/resource_pack_import_host_test.dart | Import/reopen des sept kinds, bulk1282 avec oracle exact et dernière page altérée, reprise unique et cible3D prévalidée |
| packages/map_authoring/lib/src/api/local_resource_pack_transfer_api.dart | Sections paginées familles/auteurs/sources et résumé de la sélection préparée courante |
| packages/map_authoring/lib/src/api/resource_pack_transfer_api.dart | Contrat découvrable des sections et limites de projection |
| packages/map_authoring/lib/src/domains/assets/resource_pack_import_preparer.dart | Production de la review canonique avec statut no-op/conflit/copie et sélection actuelle |
| packages/map_authoring/lib/src/domains/assets/resource_pack_import_review.dart | Dispositions exclusives, présence antérieure, octets distincts, labels publiés et exemple de racine dépendante |
| packages/map_authoring/test/application/resource_pack_transfer_api_test.dart | Pagination Unicode/enveloppe, curseurs inter-sections et bordure publiée sans draft |
| packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart | Variante de fixture permettant l'oracle des définitions importées |
| packages/map_authoring/test/domains/assets/resource_pack_reimport_test.dart | Bilan incrémental et no-op, copies, modifications et suppressions locales conservées |
| packages/map_authoring/test/tooling/jsonl_resource_pack_flow_test.dart | Trajet réel du worker avec nouvelles sections, résumé et identité de corrélation bornée |
| packages/map_core/lib/src/operations/resource_pack_dependency_graph.dart | Racines représentatives par parcours itératif O(V+E), motifs sélectionnables comme racines |
| packages/map_core/test/resource_pack_dependency_graph_test.dart | Dépendances, racines choisies et motifs autonomes |
| tools/pokemap_mcp/src/tools/resource_packs.ts | Schéma de sections et projection bornée d'une seule enveloppe détaillée |
| tools/pokemap_mcp/test/resource_pack_stdio.test.ts | Vrai MCP, sections paginées, résumé et refus de curseur inter-section |
| pokemap_authoring_api_mcp_action_catalog.md | Documentation des sections de transfert, du bilan et de ses limites sémantiques |

Les anciens points de branchement proposés `local_resource_adapter.dart`, `workspace_secondary_content.dart` et `workspace_lifecycle_binding.dart` n'exigent pas de hunk P10 : le nouvel adaptateur et les raccords de session/guards existants suffisent. Le lifecycle étranger reste préservé. Le golden read-only reste identique ; il ne décrit pas la composition du port de transfert. Les preuves10000de sélection widget utilisent un port simulé, tandis que bulk1282, API, JSONL, MCP et usages natifs2D constituent leurs preuves séparées. Aucun RSS, gros fichier ou autonomie Player déduit de ces tests.

### Qualification authoring élargie avant P11

Une seule campagne complète est exécutée sur la copie HEAD+P10 qualifiée, avec les binaires V2t épinglés et sans nouveau code authoring entre V2t etV2u : `python3 /tmp/avelune-assets-owned-run.py python3 /tmp/p10-run-qualified-v2t.py dart test --reporter expanded`, depuis `packages/map_authoring`. Résultat exact `02:30 +1992 -40: Some tests failed.`, exit1,18descendants observés, aucun résidu, `/tmp/p10-qualified-authoring-full-pre-p11-v2t.log`, SHA256 `e77088a9d540ae5055abb9b2b4aa56c6254f85a45ef73cb18ff4941c0e72f73f`. Le reçu indépendant `/tmp/p10-authoring-full-diagnostic-receipt-v2t.json`, SHA256 `496fc705b798f7e60768917486b6ed0649c3ef16a50b92776f4523b14a21ccb3`, conserve les40noms exacts et leurs signatures.

| Classe de diagnostic | Noms en échec | Recoupement |
|---|---:|---|
| Deux suites benchmark | 8 | setUp/tests/tearDown échouent d'abord sur `build/test` absent ; le répertoire apparaît ensuite pendant la campagne |
| Contrats Border | 8 | Noms déjà présents dans P05 ; attentes de propriétés, codes ou orientation divergents |
| Codec du catalogue Smart Tile | 9 | Noms déjà présents dans P05 ; normalisation, extensions et identité |
| Exports spatiaux HGSS | 6 | Même fixture `apps/hgss_first_map/` absente qu'en P05 |
| Frontières des packages | 4 | Mêmes noms qu'en P05 |
| Cinématiques | 2 | Même refus `must differ from beforeBytes` |
| Registre des kinds | 1 | `cinematicMediaAsset` toujours absent |
| Réparation Smart Tile M01 | 1 | Même validation globale sans catalogues Pokémon |
| Ancien test de budget JSONL | 1 | Son identifiant géant viole le contrat de corrélation128octets introduit avantP10 |
| Total | 40 |31noms historiquesP05 et9noms supplémentaires, pas un vert global |

La sonde budget ne change que le `reason` de l'assertion pour afficher la réponse, sans modifier requête ou délai : `/tmp/p10-budget-envelope-diagnostic-v2t_test.dart`, SHA256 `5ea081e197008cc768d3efc2ab3befd2e6d93998f30faeff50f58b68f7889387`. Run nominatif0/1, exit1, domaine observé `worker.request_id_invalid`, « The correlation identity must contain between 1 and 128 UTF-8 bytes. » Le helper remplit le champ `id` jusqu'à1Mio ; ce refus ne démontre donc pas une régression du budget d'entrée. Test et worker sont byte-identiques au HEAD avantP10. Le test de limite devra être remis en accord avec le contrat lors de P14 ; aucune source publique n'est modifiée par cette sonde.

L'ancien cas P05 `JSONL batch plans exclude existing models and unrelated large presets` n'apparaît pas parmi les échecs, puis passe nominativement1/1en7s, exit0,2descendants, aucun résidu, `/tmp/p10-model-batch-nominative-v2t.log`. Le batch d'instances spatiales, trois actions CLI Smart Tile et le golden read-only ne reproduisent pas non plus leurs anciens échecs dans cette campagne. Cela ne prouve ni stabilité absolue ni cause rétroactive de l'ancien incident.

Les deux suites benchmark sont rejouées seules, séquentiellement, après constat que `build/test` existe déjà :2pass/2fail en30s, les deux cas positifs refusant l'absence d'identitéGit avec exit64. Un dernier rejeu utilise les métadonnées réelles en lecture seule, `GIT_DIR` du dépôt, `GIT_WORK_TREE` de la copie et `GIT_OPTIONAL_LOCKS=0` ; aucun init/worktree Git ni staging n'est lancé. Les commandes internes inspectées sont rev-parse/status/diff/ls-files. Les quatre tests passent en40s, exit0,15descendants observés et aucun résidu, `/tmp/p10-benchmarks-git-readonly-v2t.log`, SHA256 `b2f6f2df40c61795f46c4760c73ce97bbda82fd24d39669e7ac53b04c2d1e830`. La source reste déclarée copie sans `.git`, base `da27b76c5` et overlay dirty ; aucune performance P12 ni commit propre n'est certifié.

Le contrôle brut de l'index partagé varie pendant cette dernière fenêtre : SHA256 avant `d5f07c392b45822417cd94e287bd1fc6e36597468155528780c15cca28d1dfe8`, après `64f6fc7231a465428fd1366ed7c5c659d87e4a4be5fe92fd77f744d6d4bbb1fc`, mtime03:47:29.210854UTC. HEAD et `.git/HEAD` restent identiques ; `git diff --cached HEAD` reste vide. Aucune cause de la variation brute n'est attribuée et aucun rollback d'index n'est tenté. Les reçus `/tmp/p10-benchmarks-git-readonly-before-v2t.json` et `...-after-v2t.json` conservent cette limite ; seul le compte43du statut avant avait été enregistré, les43lignes après sont présentes. Les cinq chemins hors des38overlays sont deux fichiers aux octets identiques àHEAD signalésM, le symlink historique omis de la copie régulière, un lock de fixture et le lien node_modules. Rien n'est nettoyé pour fabriquer un checkout propre.

Verdict Tests/Build élargi : aucun nouvel échec démontré comme régression P10 ; campagne complète toujours en échec et réserves exposées. Les sources produit, le manifeste V2u et les AOT sont revérifiés sans changement. Aucun autre run large n'est lancé sans changement ou défaut nouveau le justifiant.


### Reprise native 3D après déverrouillage

Yoahn confirme le déverrouillage de la session. Le lancement V2u qualifié, ciblant explicitement target-3d-valid, démarre un build depuis la copie temporaire et non le checkout partagé. Avant toute connexion VM/Marionette ou geste, le créneau natif est cédé à la revue NB2 coordonnée afin d’éviter deux pilotes UI concurrents. Le runner79108 est réidentifié par PID/PPID/PGID/commande puis interrompu ; son wrapper termine avec54descendants observés,6résidus appartenant à son build récoltés après nouvelle vérification, aucun processus incertain. L’application installée `/Applications/Avelune Studio.app`, PID57627, reste intacte ; aucun app de test P10 ne reste ouvert. Le build a été interrompu : exit0 du runner signifie arrêt propre, pas compilation réussie ni preuve native. Les deux fichiers de la cible3D et le pack source restent aux SHA initiaux. Log `/tmp/p10-native-studio-3d-valid-v2u.log`, reçu `/tmp/p10-native-unlock-slot-yield-receipt.json`, SHA `596f52a10fc59ca1e72c5c5c677721bd78b3820208e6b3378d275e02aa60c20b`. La session est désormais déverrouillée ; la recette reprend après fermeture de la copie QA NB2. P11 demeure exclusivement privé pendant ce créneau. Une compilation distincte sans lancement termine ensuite avec succès : `flutter build macos --debug --no-pub -t dev/marionette_main.dart`, avec les mêmes deux dart-defines explicites, copie qualifiée V2u. Runner 7805 exit 0, 50 descendants observés, deux résidus du build récoltés après réidentification, aucun processus incertain. Les 38 sources P10, les deux fichiers de la cible 3D et le pack source restent identiques. Reçu `/tmp/p10-native-3d-build-only-v2u-receipt.json`, SHA `9826236e4722fd767f43f25f7b41f0426449fccb6b05d5dea9c07d62a9196ab8`, empreintes de l’exécutable et du kernel incluses. Ce build ne remplace pas les gestes 3D, la sauvegarde et la réouverture natives.

### P10 V2u — import et usages natifs 3D, sauvegarde et réouverture froide

La session réelle qualifiée importe l’archive originale de 18 776 octets depuis le picker natif dans target-3d-valid. Les huit ressources, treize supports et 21 nouvelles définitions sont installés. Avant puis après application, le dialogue conserve les libellés Bilan préparé avant cet import, présentes avant cet import et Écritures prévues ; aperçu original border visible. Le modèle importé est placé par le canvas en (7,5 ; 0 ; 6,5) puis enregistré. Le premier tracé est refusé à juste titre : la fixture publiée ne contenait que lineStraight, alors que le resolver exige lineCap, lineStraight et lineCorner. Le brouillon est annulé, la preuve du refus conservée, aucun code produit changé. Une archive originale complémentaire distincte, 7 253 octets SHA `0226bd323fd3406135f109f74ef5b219652b183535888bc32c38e65341259fba`, apporte les trois rôles ; l’archive originale reste immuable. Ce pack de deux ressources/deux supports est importé par le même parcours natif. Deux clics puis Terminer le tracé créent une feature de neuf points et neuf placements spatiaux ; sauvegarde effective, modèle et bordure rendus. La preuve utilise donc le pack initial et un complément de fixture explicite, pas une correction silencieuse de son contenu.

Après fermeture complète du premier processus et nouveau lancement, le chemin actif est revérifié par l’extension ; le modèle et la bordure restent visibles, le tracé Original border complete est sélectionnable dans le vrai border-feature-picker. Les six SHA (carte et projet3D, carte et projet2D, les deux packs) sont strictement identiques de part et d’autre du redémarrage. Carte finale `c50e158268b89fd78422f5645fe88f1740e60fddbda44750020418ff247f7399`, projet `33d0154e3c48a620875e5803c27914749a1e4483fb935b8d3224ab08818089a0`, dix instances dont une indépendante et neuf de bordure, une feature persistée. Reçu `/tmp/p10-native-v2u-complete-receipt.json`, SHA `c31935bf47e9894780ce64209d6cf51fbdf33cb36058c151f7ec75cd53e8e561`, neuf captures13–21 et deux fichiers de sémantique hachés. Runners 28451 puis 43551, premier footer 34 descendants, second 28, exit 0 et aucun résidu. Les 38 sources qualifiées restent identiques. Marionette est déconnecté, aucun processus de la copie P10 ne reste, PID57627 de Studio utilisateur intact, créneau rendu à NB2. Le get_logs Marionette a renvoyé Server error ; logs de lancement et états visibles employés, échec de foreground récupéré par sélection CUA du chemin exact.

Le GLB P10 reste une petite géométrie triangulaire : cette passe ne prouve pas collision volumique, contact Player, animation, RSS ou performance. Les volumes cohérents P12 sont une autre fixture. Aucune preuve d’export Studio P11 ou de réédition avancée n’est déduite. Le candidat P10 conserve sa base qualifiée da27 ; les deux commits partagés converter_core 9028 et converter_adapters 280b modifient quatre fichiers disjoints des overlays, leurs packages sont absents du graphe Studio, reçu actualisé `/tmp/p10-p11-foreign-head-qualification-v2.json`, SHA `28ba532a12e81712450ab788643d12100d767bcc6c22e975075106b9b896f739`. SPEC finale puis qualité requises avant commit ; P11/P12 restent privés et exclus du staging P10.
