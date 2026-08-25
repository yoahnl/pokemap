# Audit — FG-184 — Roadmap Status Dashboard Generator V0

Date : 2026-08-20
Type : vérification de l'outil et de son layout documentaire, sous BETA-SYS-008
Verdict : `DONE` — le générateur fonctionne et lit le layout canonique ; ce qu'il affiche de vide l'est réellement.

Proposed status: DONE

## 1. Ce qui a été mesuré

La commande de preuve du ticket, exécutée telle quelle depuis la racine :

```
(cd packages/map_core && dart test test/gameplay_roadmap_dashboard_test.dart \
  test/mvp_release_gate_test.dart test/project_gameplay_readiness_test.dart \
  && dart analyze) \
  && dart run packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart --check "$PWD"
```

Sortie **0**. Les trois suites passent (42 cas), `dart analyze` rend 121 `info` et sort
tout de même 0, et le générateur produit ses 114 lignes.

Le constat qui a créé BETA-SYS-008 est donc périmé. L'outil ne cherche plus
`/reports/gameplay` : il lit `documentation/reports/gameplay`, récursivement, et
le code de sortie n'est plus 2. Ces deux points sont épinglés par des tests
existants — vérifié par sabotage, `recursive: false` fait tomber un cas et
remettre le chemin racine en fait tomber cinq.

## 2. Ce qui manquait vraiment

Un seul trou de preuve, et c'est la forme la plus probable du retour de la
panne : **rien n'interdisait de lire l'ancien layout EN PLUS du canonique.**
Mesuré avant d'écrire le garde — en faisant scanner les deux arborescences, les
43 tests du périmètre restaient verts. Un repli ajouté « pour être gentil »
serait passé sans un mot.

Couvert désormais par `dashboard CLI ignores the legacy reports layout entirely`
(`packages/map_core/test/gameplay_roadmap_dashboard_cli_test.dart`), sur un dépôt
temporaire portant délibérément les deux layouts, avec le même nom de fichier et
le même contenu valide de chaque côté.

## 3. Pourquoi le tableau de bord est vide, et pourquoi ce n'est pas un bug

Les 114 lignes affichent `Evidence 0` et `Freshness MISSING`. Ce n'est pas
l'outil qui échoue à trouver, c'est le dépôt qui n'a rien à donner :

| Constat | Chiffre |
|---|---|
| Rapports présents dans `documentation/reports/gameplay/` avant ce lot | 3 |
| Rapports qui s'attachaient effectivement à un lot canonique | **0** |
| Reçus `.fg-evidence.json` dans tout le dépôt | 0 |
| Chemins de preuve cités par la roadmap (hors gabarit `fg_xxx_<slug>`) | 8 |
| Ces citations satisfaites par un fichier réel | **1** (celle de ce lot) |
| Ces citations pointant un fichier inexistant | 7 |
| Ces fantômes utilisant l'ancien chemin `reports/gameplay/` | 6 |

Trois causes distinctes, à ne pas confondre :

1. **`fg_017_runtime_startup_intro_title_audit_2026-08-08.md`** s'attache à
   FG-017, qui n'est pas un lot de la roadmap. Le rapport existe, il est
   rattaché à un identifiant fantôme.
2. **Les deux autres rapports** (`item_system_v1_final_target_audit`,
   `audit_exhaustif_mecaniques_pokemon_pokemap`) ne portent pas de `fg_NNN` dans
   leur nom. L'appariement se faisant sur le nom de fichier
   (`(?:^|/)fg_(\d{3})(?:_|\.)`), ils sont **écartés sans un mot**.
3. **Aucun des trois** n'écrit `Proposed status: …`. La convention réellement
   utilisée dans le dépôt est `Verdict : \`PARTIAL\``, que l'outil ne sait pas
   lire. La proposition de statut de ces audits n'est donc jamais confrontée à la
   roadmap.

Les reçus, eux, sont absents **par conception** : ils portent un `candidateSha`
et l'outil sait les lire depuis un répertoire externe (`--evidence-directory`,
clés `external:`). Ce sont des artefacts de CI, pas des fichiers à committer. Un
reçu committé serait périmé au commit suivant.

## 4. Ce qui reste, et à qui

Rien pour FG-184 : l'outil fait son travail. Ce qui précède est de la dette
**documentaire**, et elle appartient à la certification produit (BETA-SYS-007) :
sept citations de la roadmap promettent des preuves qui n'existent pas, et la
convention de statut lisible par la machine n'est appliquée par aucun rapport
antérieur à celui-ci.

Les deux ensembles sont figés à l'identique par
`gameplay_roadmap_repository_consistency_test.dart` : ajouter un fantôme fait
échouer la suite, et en résoudre un aussi. La dette ne peut donc ni grossir, ni
être payée sans que le compteur en rende compte.

Deux décisions attendent un arbitrage humain, parce qu'elles rendraient la
commande CI rouge du jour au lendemain :

- **Signaler un rapport écarté** plutôt que l'ignorer. Deux fichiers du dépôt
  déclencheraient immédiatement le diagnostic.
- **Signaler une citation de preuve fantôme** dans la roadmap. Sept citations
  déclencheraient immédiatement le diagnostic.

Les deux sont souhaitables et aucun des deux n'est un effet de bord acceptable
de ce ticket.
