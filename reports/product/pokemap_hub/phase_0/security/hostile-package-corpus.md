# Corpus hostile `.pokemapgame` v1

Le builder de fixtures de Phase 1 doit pouvoir produire les cas impossibles à
représenter par un simple JSON (doublons, liens, offsets, tailles forgées).

| ID | Fixture | Résultat attendu |
|---|---|---|
| HP-001 | absence de manifest | `manifestMissing` |
| HP-002 | deux manifests | `duplicateEntry` |
| HP-003 | `/absolute`, `C:/drive`, `\\server` | `invalidPath` |
| HP-004 | segment `..`, `.`, vide ou backslash | `invalidPath` |
| HP-005 | NUL, contrôle, UTF-8 invalide | `invalidPath` |
| HP-006 | NFD au lieu de NFC | `invalidPath` |
| HP-007 | `A.png` et `a.png` | `pathCollision` |
| HP-008 | deux entrées raw identiques | `duplicateEntry` |
| HP-009 | symlink, hardlink, device, fifo | `unsupportedEntryType` |
| HP-010 | mode exécutable | `executableContent` |
| HP-011 | DEFLATE, chiffrement, data descriptor | `unsupportedZipFeature` |
| HP-012 | regions/offsets qui se chevauchent | `invalidZipStructure` |
| HP-013 | 20 001 fichiers | `entryCountExceeded` |
| HP-014 | fichier 256 MiB + 1 | `entryTooLarge` |
| HP-015 | payload 1 GiB + 1 | `archiveTooLarge` |
| HP-016 | manifest 1 MiB + 1 | `manifestTooLarge` |
| HP-017 | profondeur 33 / segment 256 / path 513 | `invalidPath` |
| HP-018 | taille centrale fausse | `sizeMismatch` |
| HP-019 | hash fichier faux | `hashMismatch` |
| HP-020 | tree hash faux | `treeHashMismatch` |
| HP-021 | fichier non inventorié | `unlistedFile` |
| HP-022 | entrée inventoriée absente | `missingFile` |
| HP-023 | mêmes ID/version, tree différent d’un receipt | `releaseConflict` |
| HP-024 | Dart/shell/PE/ELF/Mach-O | `executableContent` |
| HP-025 | archive imbriquée ou plugin | `executableContent` |
| HP-026 | `mistralApiKey` non vide | `probableSecret` |
| HP-027 | clé privée PEM / URI avec credentials | `probableSecret` |
| HP-028 | référence `file:` ou hors racine dans JSON | `referenceEscapesRoot` |
| HP-029 | image >8192 ou >64M pixels | `decodedAssetQuotaExceeded` |
| HP-030 | signature invalide | `signatureInvalid` |
| HP-031 | non signé depuis catalogue | `signatureRequired` |
| HP-032 | package valide exactement aux limites | accepté |
| HP-033 | annulation à mi-extraction | staging retiré, courant intact |
| HP-034 | kill avant promotion | courant intact, staging récupérable |
| HP-035 | kill après version move, avant current | ancienne version courante, repair finalise/nettoie |
| HP-036 | JSON trop profond ou >1 000 000 nœuds | `entryTooLarge` |
| HP-037 | hiérarchie/collections projet hors budget | `projectComplexityExceeded` |
| HP-038 | save/cache/debug/fixture dans la projection | `executableContent` |
| HP-039 | secret explicite dans manifest ou média binaire | `probableSecret` |

Répartition d’exécution : `map_distribution` couvre en Phase 1 HP-001 à
HP-032 et HP-036 à HP-039 sur les ports mémoire et random-access lorsque le
cas est matérialisable sans allocation hostile. HP-033 à HP-035 dépendent du
staging, de la promotion atomique et de `current.json` ; ils sont des kill
tests obligatoires de la Phase 3, pas des tests unitaires du codec ZIP.

Chaque fixture doit vérifier qu’aucun fichier n’est créé hors du staging, que
`current.json` et les saves restent identiques et que le code diagnostic ne
contient pas de secret.
