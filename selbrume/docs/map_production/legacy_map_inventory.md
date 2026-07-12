# SEL-MAP-001 — inventaire des maps legacy Selbrume

## Objet et périmètre

Cet inventaire fige la baseline de **Task 0 — Selbrume Maps & Assets Beta** avant le cutover vers les IDs canoniques. Il couvre uniquement les dix entrées `maps` actuellement déclarées dans `selbrume/project.json`. Aucun fichier de map, manifeste, sauvegarde, test ou historique n'est modifié par cette tâche.

Les tailles ci-dessous sont les dimensions de grille déclarées dans chaque JSON. Les tableaux complets de terrain et de collisions des coquilles font 2 025 cellules par couche, mais ne constituent pas du contenu utile : ils ne contiennent que les valeurs par défaut (`none` et `false`).

## Provenance Git initiale

- Worktree : worktree Git isolé dédié au lot `SEL-MAP-001`
- Branche : `codex/selbrume-map-assets-beta`
- Base et `HEAD` initial : `fdaf4e5ddfb82981353c104c89377f061b207e2e`
- `git status --short --untracked-files=all` initial : aucune sortie, worktree propre.

## Audit des dix entrées du manifeste actif

L'ordre est celui de `selbrume/project.json`. Pour les métriques, « éléments » signifie `placedElements`; « zones » signifie `gameplayZones`.

| # | ID actuel | Chemin relatif | Taille | Contenu utile observé | Niveau | Rôle prévu |
|---:|---|---|---:|---|---|---|
| 1 | `route 1` | `maps/route 1.json` | 45×45 | 6 couches, 68 éléments, 1 PNJ, 5 zones de rencontre, 1 connexion; 0 trigger, warp ou event | Élevé : carte jouable existante | Source de migration vers `map_marais_salants` |
| 2 | `Selbrume` | `maps/Selbrume.json` | 55×55 | 17 couches, 307 éléments, 3 entités, 3 warps, 1 connexion; 0 trigger, zone ou event | Élevé : hub existant substantiel | Source de migration vers `map_bourg_selbrume` |
| 3 | `house 1` | `maps/house 1.json` | 45×45 | 3 couches par défaut, aucun élément/entité/zone/trigger/event, 1 warp retour vers `Selbrume` | Faible : squelette | Référence de squelette seulement; hors manifeste actif après cutover |
| 4 | `house 2` | `maps/house 2.json` | 45×45 | 3 couches par défaut, aucun élément/entité/zone/trigger/event, 1 warp retour vers `Selbrume` | Faible : squelette | Référence de squelette seulement; hors manifeste actif après cutover |
| 5 | `house 3` | `maps/house 3.json` | 45×45 | 3 couches par défaut; aucun élément, entité, zone, trigger, event, warp ou connexion | Nul : coquille vide | Fichier legacy conservé sur disque; hors manifeste actif après cutover |
| 6 | `house 4` | `maps/house 4.json` | 45×45 | 3 couches par défaut; aucun élément, entité, zone, trigger, event, warp ou connexion | Nul : coquille vide | Fichier legacy conservé sur disque; hors manifeste actif après cutover |
| 7 | `house 5` | `maps/house 5.json` | 45×45 | 3 couches par défaut; aucun élément, entité, zone, trigger, event, warp ou connexion | Nul : coquille vide | Fichier legacy conservé sur disque; hors manifeste actif après cutover |
| 8 | `pokémon center` | `maps/pokémon center.json` | 45×45 | 3 couches par défaut; aucun élément, entité, zone, trigger, event, warp ou connexion | Nul : coquille vide | Fichier legacy conservé sur disque; hors manifeste actif après cutover |
| 9 | `pub` | `maps/pub.json` | 45×45 | 3 couches par défaut; aucun élément, entité, zone, trigger, event, warp ou connexion | Nul : coquille vide | Fichier legacy conservé sur disque; hors manifeste actif après cutover |
| 10 | `lab` | `maps/lab.json` | 45×45 | 3 couches par défaut; aucun élément, entité, zone, trigger, event, warp ou connexion | Nul : coquille vide | Fichier legacy conservé sur disque; hors manifeste actif après cutover |

Les dix IDs du manifeste correspondent aux champs `id` de leurs fichiers. Seuls `Selbrume.json` et `route 1.json` portent assez de composition et de gameplay pour servir de sources de migration. `house 1.json` et `house 2.json` ne servent qu'à comprendre la forme minimale d'un intérieur et d'un warp de retour.

Commande compacte de reproduction des métriques de l'inventaire, dans l'ordre du manifeste :

```bash
jq -cs '.[0].maps as $entries | .[1:] as $maps | $entries | map(. as $entry | ($maps[] | select(.id == $entry.id)) as $map | {id:$entry.id,path:$entry.relativePath,size:$map.size,layers:($map.layers|length),placedElements:($map.placedElements|length),entities:($map.entities|length),triggers:($map.triggers|length),gameplayZones:($map.gameplayZones|length),events:($map.events|length),warps:($map.warps|length),connections:($map.connections|length)})' selbrume/project.json selbrume/maps/*.json
```

## Décisions de cutover et de compatibilité

1. Les IDs canoniques remplacent les anciens IDs dans le manifeste actif : `Selbrume` devient `map_bourg_selbrume` et `route 1` devient `map_marais_salants`. Les anciens IDs ne restent pas des alias actifs.
2. La compatibilité des sauvegardes pré-bêta qui référencent `Selbrume` ou `route 1` n'est pas garantie. **SEL-MAP-001 n'implémente aucune migration de sauvegarde.**
3. Les dix fichiers legacy restent présents sur disque et ne sont pas supprimés pendant le cutover. Les références et artefacts historiques restent intouchés; `selbrume/project.shadow59.before.json` est explicitement hors scope et ne doit pas être modifié.

## Empreintes sémantiques de référence

Les empreintes excluent les champs d'identité et ne couvrent que les données de composition et de gameplay destinées à être migrées.

```bash
jq -S '{size,tilesetId,layers,placedElements,entities,triggers,gameplayZones,events}' 'selbrume/maps/Selbrume.json' | shasum -a 256
# cb2625eae6e98c3f58523502cd0309004172eb3b4897f5e24ef91bd22f49f0df  -

jq -S '{size,tilesetId,layers,placedElements,entities,triggers,gameplayZones,events}' 'selbrume/maps/route 1.json' | shasum -a 256
# fffdbcb06192b20bdf693e1d2c47c81db56db2681b717ac3ec8772d1cb53feaf  -
```

Ces résultats ont été recalculés dans le worktree de Task 0 et correspondent à la baseline attendue.

### Empreintes navigation-inclusive

La paire complémentaire ci-dessous ajoute explicitement `connections` et `warps`. Elle doit être utilisée pour détecter une dérive de navigation que les empreintes sémantiques imposées ci-dessus ne couvrent pas.

```bash
jq -S '{size,tilesetId,layers,placedElements,entities,triggers,gameplayZones,events,connections,warps}' 'selbrume/maps/Selbrume.json' | shasum -a 256
# 4c7c8255997e9ff04f8802c0cc8fa167900cce538e2a3437a8f67f3b9f935418  -

jq -S '{size,tilesetId,layers,placedElements,entities,triggers,gameplayZones,events,connections,warps}' 'selbrume/maps/route 1.json' | shasum -a 256
# 72f416179b676ec73d64cb63ffa080d756fe7394db5fc182d6c3167acfd90212  -
```

## Baseline Flutter pré-cutover

Baseline fraîche déjà exécutée dans ce worktree avant Task 0 :

```bash
cd packages/map_runtime && flutter test --no-pub test/p6_*selbrume*.dart
```

- Résultat : code de sortie `1`, résumé `+5 -3`; la suite n'est donc pas verte.
- `P6-01` : `defaultSpawnId` attendu `null`, valeur actuelle `spawn`. Cet écart est lié aux maps et le contrat sera intentionnellement mis à jour lors du cutover canonique.
- `P6-07` et `P6-05` : membre d'équipe attendu `metapod`, valeur actuelle `dratini`. Ces deux écarts d'équipe sont hors scope de SEL-MAP-001 et ne doivent pas être corrigés dans le chantier maps/assets.

## Limites conservées

- Task 0 n'effectue ni cutover du manifeste, ni copie/renommage de map, ni migration de sauvegarde.
- Aucun échec d'équipe Pokémon n'est corrigé ici.
- Les fichiers legacy et historiques sont conservés tels quels afin que les prochaines tâches puissent comparer la migration à cette baseline.
