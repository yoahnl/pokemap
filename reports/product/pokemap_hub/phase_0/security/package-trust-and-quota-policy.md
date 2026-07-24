# Politique de confiance et quotas v1

## Canaux de confiance

| Canal | Signature | Comportement |
|---|---|---|
| export local installé directement | optionnelle | confirmation explicite, badge « local non signé » |
| import fichier local | optionnelle | avertissement persistant, intégrité obligatoire |
| catalogue public futur | Ed25519 obligatoire | clé éditeur approuvée, signature invalide/inconnue rejetée |

Une signature valide n’assouplit aucun quota ou contrôle data-only. Une
signature absente n’autorise aucun bypass. Le trust store est géré par le Hub,
jamais embarqué comme autorité dans le package.

## Quotas installateur v1

Toutes les limites sont inclusives. Tout dépassement est bloquant.

| Ressource | Limite |
|---|---:|
| fichier `.pokemapgame` | 1 073 741 824 octets (1 GiB) |
| payload total déclaré et extrait | 1 073 741 824 octets |
| `game-manifest.json` | 1 048 576 octets |
| nombre d’entrées payload | 20 000 |
| fichier payload individuel | 268 435 456 octets (256 MiB) |
| chemin UTF-8 normalisé | 512 octets |
| segment de chemin UTF-8 | 255 octets |
| profondeur | 32 segments |
| fichier JSON individuel | 33 554 432 octets (32 MiB) |
| largeur ou hauteur image | 8 192 pixels |
| pixels décodés par image | 67 108 864 |
| progression/log diagnostic en mémoire | 4 MiB par session |

L’espace libre requis avant staging est
`max(536870912, archiveBytes * 5 / 2)` en plus de l’archive source. Les
compteurs d’extraction sont calculés à partir des octets réellement lus. V1
accepte seulement STORED ; toute entrée compressée, chiffrée ou utilisant un
data descriptor est rejetée.

Une plateforme peut appliquer une limite **plus basse** pour sa certification,
mais doit l’annoncer avant sélection et produire un diagnostic compatible. Elle
ne peut accepter plus sans réviser la policy.

## Chemins

Le validateur exige UTF-8 strict et NFC. Il rejette : NUL/contrôles, `.` ou
`..` comme segment, chemin absolu, drive/UNC, backslash, slash final, segment
vide, caractères réservés Windows `< > : " | ? *`, noms DOS réservés, et
espaces/points terminaux. La clé de collision est `casefold(NFC(path))`.

Seuls les fichiers réguliers mode `0644` sont valides. Les offsets/regions ZIP
ne peuvent se chevaucher ou aliaser.

## Politique data-only

Extensions autorisées :

- projet : `.json` ;
- images : `.png`, `.jpg`, `.jpeg`, `.webp` ;
- audio : `.ogg`, `.wav`, `.mp3`, `.flac`, `.m4a` ;
- polices : `.ttf`, `.otf`, `.woff2` ;
- légal : `.txt`, `.md`.

L’extension, le media type et la signature magique doivent être cohérents.
Sont toujours interdits : `.dart`, `.js`, `.wasm`, shells, PowerShell,
executables PE/ELF/Mach-O, bibliothèques dynamiques, APK/IPA, archives imbriquées,
plugins, raccourcis et documents à macros. Aucun URI `file:`, chemin absolu ou
référence réseau n’est résolu par le runtime.

## Secrets

Blocage sur :

- clés JSON/YAML comme `mistralApiKey`, `apiKey`, `accessToken`, `clientSecret`,
  `privateKey`, `password` lorsqu’elles ont une valeur non vide ;
- blocs PEM privés ;
- préfixes de tokens connus et credentials dans URI ;
- fichiers `.env`, keystore, certificat privé ou nom contenant `secret`.

Les heuristiques d’entropie seules produisent un diagnostic de review côté
export, pas un rejet installateur, afin d’éviter de classifier des hashes et
assets. Les règles explicites ci-dessus sont bloquantes.

## Codes de diagnostic

`archiveTooLarge`, `entryCountExceeded`, `entryTooLarge`, `invalidPath`,
`pathCollision`, `unsupportedZipFeature`, `unlistedFile`, `missingFile`,
`hashMismatch`, `treeHashMismatch`, `executableContent`, `probableSecret`,
`referenceEscapesRoot`, `insufficientDisk`, `signatureRequired`,
`signatureInvalid`.

## Repair et uninstall

Repair relit le receipt, recalcule chaque hash et remplace uniquement par une
copie validée. Uninstall ne touche jamais à `saves/<gameId>`. Aucune opération
ne supprime la version courante avant promotion d’un remplacement valide.
