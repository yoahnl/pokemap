# Threat model `.pokemapgame` v1

## Objectif et périmètre

HUB-002 protège le poste, les données du Hub, les autres jeux et les saves
contre un package local ou téléchargé hostile. Il couvre inspection, extraction,
validation, installation, repair et lecture runtime. Le code du Hub, l’OS
compromis et la modération juridique d’un catalogue sont hors périmètre.

## Actifs et frontières de confiance

Actifs : Application Support/PokeMap, versions installées, `library.json`,
saves/backups, préférences, logs, clés de catalogue et disponibilité du Hub.

```text
package non fiable
  → parser ZIP borné
  → manifest non fiable
  → staging isolé
  → validateur projet + smoke
  → version installée immuable
  → runtime data-only
```

Aucune donnée ne franchit une frontière sans validation. L’archive, son
manifest, ses hashes et sa signature restent non fiables jusqu’à la fin de leur
vérification respective.

## Menaces et contrôles

| Menace | Exemple | Contrôle | Résultat |
|---|---|---|---|
| traversal | `../../save.json` | chemin NFC relatif sous racine, segments validés | rejet avant extraction |
| path absolu | `/etc`, `C:`, UNC | rejet `/`, drive, `\\`, backslash | rejet |
| lien/fichier spécial | symlink vers saves | type Unix régulier uniquement, mode 0644 | rejet |
| doublon/alias | deux central entries, casse/Unicode | unicité raw + collision key NFC/casefold | rejet |
| ZIP bomb / DoS | tailles forgées, trop de fichiers | STORED seulement, quotas central + streaming | rejet/annulation |
| overwrite | target déjà installé | staging unique et promotion atomique | ancienne version intacte |
| contenu caché | fichier absent de l’inventaire | bijection archive/inventaire | rejet |
| falsification | taille/hash/tree hash faux | comptage streaming + SHA-256 | rejet |
| code exécutable | Dart, shell, Mach-O | allowlist data, extension+magic+mode | rejet |
| secret | `mistralApiKey`, PEM | projection export + scan noms/contenu | rejet |
| référence externe | path JSON hors package | resolver confiné, aucun URI fichier/réseau | rejet |
| usurpation éditeur | signature absente/fause | Ed25519 + trust store pour catalogue | warning ou rejet selon canal |
| rollback malveillant | downgrade vulnérable | politique de compatibilité, consentement | blocage/warning |
| fuite interjeu | gameId/path forgé | IDs validés, racines scopées, handles | rejet |
| fuite token session | argv/env/log lisible | pipe anonyme ou endpoint OS protégé, redaction | fermeture du canal |
| TOCTOU | package changé après inspect | lecture depuis handle/staging, rehash avant promotion | rejet |
| logs sensibles | stack avec données | codes sûrs, redaction, rétention bornée | diagnostic local |

## Ordre non négociable

1. ouvrir en lecture seule et vérifier taille archive ;
2. parser le central directory avec limites ;
3. valider types, flags, noms, collisions et méthode ;
4. lire le seul `game-manifest.json` sous limite ;
5. valider schéma, compatibilité, quotas et politique de confiance ;
6. exiger une bijection inventaire/entries ;
7. créer un staging imprévisible sur le même volume ;
8. extraire en streaming avec compteurs réels et no-follow ;
9. vérifier tailles/hashes/tree hash et scanner le contenu ;
10. valider les références et le projet, puis smoke borné ;
11. fsync/fermer, produire le receipt, promouvoir atomiquement ;
12. mettre à jour la bibliothèque/current seulement après succès.

Une annulation suit le même teardown et ne modifie jamais la version courante.

## Résiduels

Les décodeurs image/audio restent une surface native ; tailles et dimensions
sont bornées, puis le desktop public isole le player. SHA-256 ne prouve pas
l’auteur. Le secret scanning peut avoir des faux positifs : la correction se
fait dans le projet auteur puis par nouvel export, jamais par bypass install.

## Tests futurs et DONE

Le corpus hostile doit générer de vraies archives, pas seulement des manifests.
Chaque ligne de [`hostile-package-corpus.md`](hostile-package-corpus.md) doit
produire le code attendu avant création du staging. DONE exige aussi des tests
aux limites exactes et un kill test pré/post-promotion.
