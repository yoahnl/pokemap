# Politique de versions et capacités

## Objectif

HUB-003 produit une décision déterministe avant extraction, installation,
activation de version et chargement de save. Les axes sont indépendants :
aucun « grand numéro de version » ne remplace les autres.

## Axes

| Axe | Forme | Règle v1 |
|---|---|---|
| `packageFormat` | entier | `1` exact ; toute autre valeur rejetée |
| `gameVersion` | SemVer | ordonne les releases d’un même `gameId` |
| `minHubVersion` | SemVer | version du Hub doit être supérieure ou égale |
| `runtimeApi` | range SemVer | API embarquée doit appartenir à la range |
| capability | `name@major` | chaque required doit être supportée exactement |
| `projectFormat` | token `vN` | `v1`/`v2` supportés ; `v1` migré sur copie vers `v2` |
| `saveFormat` | entier | v1 supporté ; ancien seulement avec chaîne moteur |
| `compatibilityId` | token | égalité exacte entre package et save |

L’ordre d’évaluation est : structure/package → Hub → runtime API → capabilities
→ projet → save. Le diagnostic rapporte tous les blocages déductibles sans
extraire, mais n’accède jamais au payload si la structure est hostile.

## Capacités

Le Hub embarque un registre : nom, major, version d’implémentation et plateformes.
Une capability requise inconnue, au mauvais major ou indisponible sur la cible
bloque installation/launch avec une explication. Une capability non requise ne
peut jamais être activée parce qu’un fichier la mentionne.

Les services boutique, Centre Pokémon et PC sont disponibles uniquement via une
interaction monde ou une capability déclarée, éventuellement conditionnée par
Facts. Ils ne sont pas des actions globales implicites.

## Updates

Une update valide :

1. conserve exactement `gameId` ;
2. a un `gameVersion` supérieur au courant pour le parcours Update ;
3. ne réutilise jamais le couple ID/version avec un autre tree hash ;
4. est installée et validée côte à côte ;
5. capture un backup de chaque save susceptible d’être migrée ;
6. devient courante par remplacement atomique de `current.json`.

Une version inférieure peut être importée comme version latérale mais n’est pas
présentée comme update. L’activation downgrade exige confirmation.

## Saves et migrations

- `gameId` doit être identique.
- `compatibilityId` doit être identique. Un changement signifie une famille de
  save différente ; le Hub garde l’ancienne version installable/chargeable.
- une save au `saveFormat` courant est lue directement après checksum.
- une save ancienne n’est migrée que par une chaîne de migrations moteur
  embarquées et testées ; chaque étape travaille sur une copie.
- une save future est conservée mais jamais ouverte par un Hub plus ancien.
- une migration métier arbitraire fournie par package est interdite en v1.
- ouvrir/écrire avec une version plus récente crée d’abord un snapshot de
  rollback. Une version plus ancienne ne charge pas directement la save
  réécrite ; le rollback restaure le snapshot compatible.

Une migration échouée ou un checksum invalide ne remplace jamais la dernière
save valide. La version courante du jeu n’est pas basculée tant que le smoke et
les migrations préparatoires ne passent pas.

## Project format

Les valeurs sont exactement celles sérialisées par `ProjectVersion` :
`"v1"` et `"v2"`, jamais les entiers `1`/`2`. Les migrations de projet
existantes v1 → v2 s’exécutent dans le staging et la
projection migrée est revalidée. Le payload signé/installé reste immuable ; le
résultat de migration va dans un cache scoppé par game/version/tree hash. Un
format futur est rejeté. Aucun downgrade de projet n’est effectué.

## Rollback, repair et conflits

- rollback change le pointeur courant vers un receipt déjà valide et propose le
  snapshot save compatible ;
- repair exige le même tree hash que le receipt ;
- même ID/version avec tree différent : `releaseConflict`, jamais overwrite ;
- uninstall d’une version courante choisit explicitement une autre version
  compatible ou retire le jeu de la library ; les saves restent.

## Tests futurs

La fixture [`compatibility-matrix.json`](compatibility-matrix.json) devient un
test table-driven. Ajouter : prerelease SemVer, bornes de ranges, capability
major, project v1/v2/futur, save ancien/courant/futur, compatibilityId,
update/downgrade, conflict et migration failure.

## DONE, risques et dépendances

DONE exige un résultat unique `accept`, `acceptWithWarning`, `migrate` ou
`reject` pour chaque combinaison. Le risque principal est une fausse promesse
éditeur via `compatibilityId` ; elle est limitée par backups, version côte à
côte et rollback. HUB-003 dépend de HUB-001/002 et précède saves/installer.
