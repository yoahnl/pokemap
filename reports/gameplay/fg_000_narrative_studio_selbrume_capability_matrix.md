# FG-000 — Index de compatibilité Narrative Studio / Selbrume

| Métadonnée | Valeur |
|---|---|
| Date de mise à jour | 2026-07-19 |
| Nature | Source secondaire de compatibilité |
| Lot de mise à jour | `NSC-00 — Matrice de capacités et contrat d'acceptation` |

## Source de vérité

La matrice canonique vivante est désormais :

`reports/narrativeStudio/completion/ns_completion_capability_matrix.md`

Elle inventorie 54 capacités et relie, pour chacune, schema, authoring, persistence, validation, preview, runtime, preuve et propriétaire NSC. En cas de divergence, la matrice canonique prévaut.

Le verdict courant du projet Selbrume, ses preuves fraîches, ses limites E2E et le statut FG-185 restent dans :

`reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md`

NSC-00 n'a produit aucune nouvelle preuve produit et n'édite donc pas ce
réaudit. Comme celui-ci était déjà non suivi, son SHA-256 observé à la
vérification est consigné dans l'Evidence Pack plutôt que de prétendre à une
comparaison Git antérieure impossible.

## Vocabulaire de compatibilité

| État | Usage |
|---|---|
| `Supported` | Contrat et preuve fichier/test présents. |
| `Partial` | Tranche existante, manque affecté à un lot NSC unique. |
| `Rejected by design` | Capacité volontairement exclue. |
| `Legacy` | Lecture/migration historique uniquement. |

Les anciens états français, scores en pourcentage, priorités locales et `GATE ROUGE` datés du 18 juillet sont retirés de ce fichier. Ils ne doivent pas concurrencer le réaudit post-correction du 19 juillet ni la matrice NSC.

## Correspondance des anciennes rubriques

| Ancienne rubrique | Lignes canoniques | Prochain propriétaire principal |
|---|---|---|
| Storylines, Chapters, Steps et graph | ST-01 à ST-06 | NSC-20 à NSC-23 |
| Scenes, branches et conséquences | SC-01 à SC-13 | NSC-30 à NSC-37 |
| Dialogues et outcomes | DG-01 à DG-04 | NSC-34 à NSC-36 |
| Event Builder et Map Events | EV-01 à EV-08 | NSC-40 à NSC-45 |
| Facts et World Rules | FA-01 à FA-03, WR-01 à WR-03 | NSC-50 à NSC-53 |
| Validator et jouabilité | VA-01 à VA-06 | NSC-54 à NSC-58 |
| Cinematics, audio et FX | CI-01 à CI-11 | NSC-60 à NSC-67 |
| Reconstruction, campagne et release Selbrume | Contrats 4.1 à 4.3 | NSC-80 à NSC-83 |
| Gros projet et performance | Section 6 | NSC-74 |

## Limites Selbrume à ne pas perdre

Les limites suivantes sont reprises sans les requalifier :

- pas de defeat→retry physique dédié pour le gardien 2 ;
- round-trip `SaveData` JSON pour la matrice retry, pas une preuve disque entre défaite réelle et retry ;
- pas de walkthrough humain de 2 à 3 heures ;
- pas de preuve de signature, notarisation, Intel ou package autonome incluant directement le projet ;
- les cinématiques canoniques restent simples et audio/FX incomplets ;
- FG-185 reste gouverné par sa roadmap et son Evidence Pack, jamais par transitivité depuis Selbrume.

## Maintenance

Ce fichier reste volontairement court. Il ne duplique plus les verdicts ligne par ligne et ne doit recevoir que :

- un changement de chemin canonique ;
- une nouvelle table de correspondance ;
- une correction lorsqu’une preuve fraîche rend l’index secondaire trompeur.

Toute modification de capacité doit être faite d’abord dans la matrice canonique, avec preuve et propriétaire.
