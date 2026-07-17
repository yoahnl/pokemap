# NS-EVENT-V2 — S0 Stabilization Baseline

Date d'ouverture : 2026-07-17

Lot exact : `S0 — Stabiliser et sécuriser l'état courant`

Statut courant : `DONE`

## Résumé exécutif

Le checkpoint de départ Event Builder V2 est récupérable dans le commit
`11c956ac2c37be15fe07c708443ecf7a39b1663b`
(`feat(events): complete Event Builder V2 workflow`). Le commit porte 240
fichiers, 270489 insertions et 733 suppressions. Les neuf éléments initiaux ont
été attribués ; les failure artifacts et le lock orphelin ont été supprimés.
S0 est donc fermé. Le checkpoint final et la reproductibilité du corpus
graphique relèvent de L2 et restent les deux conditions opérationnelles ouvertes.

## Scope et non-objectifs

S0 attribue le checkout, élimine les artefacts orphelins, réconcilie la
documentation avec le checkpoint et enregistre les baselines. Il n'ajoute
aucun comportement Event, Scene, Map ou runtime. Les corrections visuelles et
release appartiennent respectivement à K2 et aux lots correctifs précédant L2.

## Audit initial

État observé au début de la campagne cinq lots :

- branche : `main` ;
- HEAD : `11c956ac2c37be15fe07c708443ecf7a39b1663b` ;
- modifications suivies : aucune ;
- éléments non suivis : neuf ;
- `git diff --check` : exit `0` ;
- le plan d'exécution local sous `docs/superpowers/plans/` est ignoré par la
  règle historique `.gitignore:7:/docs/*` et n'est pas un livrable Git S0.

## Attribution des neuf éléments initiaux

| Élément | Attribution | Décision |
|---|---|---|
| 4 PNG `test/failures/ns_scenes_v1_39_*` | artefacts golden Scene étrangers à Event V2 | supprimés, non publiables |
| 4 PNG `test/ui/canvas/failures/event_builder_v2_product_route_1672x941_*` | comparaison golden RED K2 | conservés pendant l'itération K2, à supprimer après GREEN |
| `selbrume/.pokemap-project-1f1a60297a27b0b0.lock` | lock éditeur local vide et orphelin | `lsof` sans propriétaire, supprimé |

## Références visuelles gelées

| Fichier | SHA-256 |
|---|---|
| North star `1 - événements.png` | `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` |
| Produit avant nouvelle itération K2 | `eda012eafc3ecbdafd17396c2b7810005f1687a9796f7cf58d93ae34dde1d673` |

## Commandes initiales et résultats exacts

```text
git show --shortstat --oneline HEAD
11c956ac feat(events): complete Event Builder V2 workflow
240 files changed, 270489 insertions(+), 733 deletions(-)

lsof selbrume/.pokemap-project-1f1a60297a27b0b0.lock
exit 1, aucun processus propriétaire

git diff --check
exit 0, aucune sortie
```

Après attribution et nettoyage des cinq artefacts immédiatement sûrs, seuls
les quatre PNG RED K2 restent non suivis.

## Risques conservés

- le checkpoint unique de 240 fichiers reste grossier pour un rollback par
  phase, mais il est restaurable ;
- les documents K/L contiennent un historique exact sur l'ancien HEAD
  `2f68328…` qui ne doit pas être réécrit ; une section terminale post-commit
  doit le superséder ;
- le checkpoint S0 protège l’état initial, pas les octets de la campagne
  courante ;
- aucune opération Git d'écriture n'a été autorisée pendant cette campagne ;
- L2 reste par conséquent `BLOCKED` jusqu'au checkpoint final explicite et à
  une décision reproductible sur le corpus externe.

## Clôture S0

- K2 : `DONE`, route produit 1672 × 941 inspectée et Design QA `passed` ;
- matrice technique : verte sur les six packages ;
- corpus graphique approuvé retrouvé sous
  `/Users/karim/Documents/playable_projects/selbrume/assets/sources/v2`, avec
  `68/68` hashes conformes au manifeste ;
- pipelines initialement skippés : rejoués, `+3`, `All tests passed!` ;
- hygiène : aucun fichier sous les dossiers `test/failures`, aucun lock
  Selbrume, `git diff --check` vert.

Verdict : **S0 DONE**. Le rapport ne confond pas ce checkpoint initial avec le
checkpoint de publication encore requis par L2.
