# `.pokemapgame` package format v1

Version normative : `packageFormat = 1`.

## Objectif, périmètre et dépendances

HUB-001 définit une unité installable, déterministe et data-only. Son futur
codec appartient à `map_distribution` et dépend de `map_core`, `archive`,
`crypto`, `path` et `pub_semver` déclarés directement. Il ne couvre ni
l’installateur, ni la bibliothèque, ni le catalogue public.

## Layout

```text
<slug>-<gameVersion>.pokemapgame
├── game-manifest.json
├── project/
│   ├── project.json
│   ├── maps/
│   ├── assets/
│   ├── dialogues/
│   └── data/
├── presentation/
│   ├── icon.png
│   ├── cover.png
│   └── hero.png
└── legal/
    ├── LICENSE.txt
    └── CREDITS.txt
```

Seuls `game-manifest.json` et `project/project.json` sont obligatoires. Le nom
du fichier archive n’a aucune valeur d’identité.

## Identité

`gameId` :

- est choisi une seule fois par l’auteur et persiste entre versions ;
- est une chaîne ASCII minuscule de 3 à 128 octets ;
- suit `^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2,}$` ;
- ne peut être dérivé du titre, du slug, du dossier ou d’un hash ;
- ne peut être modifié par update ; un nouvel ID crée un autre jeu.

Exemple : `games.studio.example.adventure`. `gameVersion` est un SemVer strict
sans préfixe `v`. Deux packages de même `gameId` et `gameVersion` mais de
`treeSha256` différents constituent un conflit de publication et sont rejetés.

## Manifeste

Le manifeste respecte
[`game-manifest-v1.schema.json`](game-manifest-v1.schema.json). Les propriétés
inconnues sont rejetées en v1. Il contient :

- identité, titre, auteur et éditeur optionnel ;
- compatibilité Hub/runtime/projet/save et capabilities requises ;
- locales et branding déclaratif ;
- inventaire exhaustif de chaque fichier payload ;
- tailles, SHA-256, compte, total et tree hash ;
- signature éditeur optionnelle.

`content.files` inventorie toutes les entrées sauf `game-manifest.json`.
Chaque entrée est présente exactement une fois ; aucun fichier hors inventaire,
répertoire ZIP explicite ou entrée vide additionnelle n’est admis. Les références
de branding doivent désigner une entrée inventoriée du bon préfixe.

## Projection runtime

Le builder ne zippe jamais le workspace auteur directement. Il construit une
projection propre qui exclut au minimum :

- saves, backups et `runtime_host_launch_save.json` ;
- `.dart_tool`, `build`, caches, logs, temporaires, locks et fichiers IDE ;
- seeds, fixtures, diagnostics et métadonnées propres au host/éditeur ;
- `mistralApiKey`, tokens, mots de passe, clés privées et secrets probables ;
- Dart, scripts, plugins natifs, binaires et extensions moteur arbitraires.

La projection est validée comme un projet neuf avant packaging.

## ZIP déterministe

V1 fixe volontairement un profil simple :

- ZIP non chiffré ; méthode **STORED (0)** uniquement ;
- noms UTF-8 NFC, séparateur `/`, chemins relatifs ;
- aucune entrée répertoire, symlink, hardlink ou fichier spécial ;
- ordre lexicographique des noms normalisés par octets UTF-8 ;
- timestamp DOS `1980-01-01 00:00:00` pour toutes les entrées ;
- mode Unix fichier régulier `0100644`, attributs plateforme neutralisés ;
- aucun extra field, commentaire, data descriptor ou archive comment ;
- `game-manifest.json` utilise UTF-8 sans BOM et JCS (RFC 8785).

STORED évite la dépendance à une implémentation/level DEFLATE pour obtenir des
octets identiques. Les médias sont déjà généralement compressés. Un autre
algorithme exigera un nouveau `packageFormat`.

## Canonicalisation du contenu

Les entrées sont triées comme ci-dessus. Le préimage UTF-8 du tree hash est :

```text
pokemap-content-tree-v1\n
<path>\t<size-base10>\t<sha256-lowercase>\n
...
```

Les chemins ne peuvent contenir tabulation ou newline. `treeSha256` est le
SHA-256 hexadécimal minuscule du préimage. `totalBytes` est la somme exacte des
tailles payload ; `fileCount` est la longueur de `files`.

## Signature

`signature` est optionnelle pour le sideload v1. Si présente :

- `algorithm` vaut `ed25519` ;
- `keyId` identifie une clé publique hors package ;
- `value` est la signature base64 de
  `UTF8(JCS(manifest sans la propriété signature))`.

Les hashes fournissent l’intégrité, pas l’identité éditeur. Un futur catalogue
public exige une signature valide par une clé approuvée.

## Inspection et installation

L’ordre obligatoire est : lire le central directory sans extraire, appliquer
les quotas et règles structurelles, lire/valider le manifest, confronter
inventaire et entrées, extraire en staging avec bornes, vérifier chaque hash et
le tree hash, valider le projet, effectuer le smoke, puis promouvoir. La
politique détaillée est dans le lot HUB-002.

## Tests futurs

- codec/schema avec exemples valides et invalides ;
- déterminisme octet-à-octet sur deux builds ;
- invariance à l’ordre/timestamps source ;
- cohérence count/size/file hash/tree hash ;
- rejet des champs inconnus, IDs/SemVer invalides et signature auto-référente.

## DONE et risques

DONE exige schéma, exemples et vecteurs recalculés par tests. Les risques sont
le coût disque du mode STORED, la divergence JCS entre plateformes et les
collisions Unicode ; HUB-002 les borne ou les rejette.
