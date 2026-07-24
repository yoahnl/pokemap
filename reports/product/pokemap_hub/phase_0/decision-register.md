# Registre des décisions Phase 0

Autorité : propriétaire produit PokeMap. Le lancement explicite de la Phase 0
le 2026-07-25 ratifie les recommandations annoncées ; les décisions détaillées
ont été vérifiées contre l’audit du 2026-07-24.

| ID | Décision | Statut | Owner | Date | Source / artefact |
|---|---|---|---|---|---|
| P0-D01 | Hub public séparé ; host conservé comme harness interne | Accepted | Product + Architecture | 2026-07-25 | ADR-0001 |
| P0-D02 | `map_distribution` Dart pur, `map_player_ui` Flutter, dépendances dirigées vers les contrats | Accepted | Architecture | 2026-07-25 | ADR-0001, ownership |
| P0-D03 | Ownership de GameIdentity, SaveEnvelope, distribution, runtime, UI et library | Accepted | Architecture | 2026-07-25 | ownership |
| P0-D04 | `gameId` reverse-DNS ASCII minuscule, stable et immuable | Accepted | Distribution | 2026-07-25 | pokemapgame-v1 |
| P0-D05 | ZIP v1 déterministe à entrées STORED et JSON JCS | Accepted | Distribution | 2026-07-25 | pokemapgame-v1, vectors |
| P0-D06 | inventaire exhaustif, tree hash et signature Ed25519 optionnelle | Accepted | Distribution + Security | 2026-07-25 | pokemapgame-v1 |
| P0-D07 | quotas numériques, chemins sûrs, data-only, rejet des secrets | Accepted | Security | 2026-07-25 | trust-and-quota-policy |
| P0-D08 | sideload local non signé avec avertissement ; catalogue futur signé | Accepted | Product + Security | 2026-07-25 | trust-and-quota-policy |
| P0-D09 | compatibilité évaluée sur package, Hub, runtime, capacités, projet et save | Accepted | Distribution + Runtime | 2026-07-25 | compatibility policy |
| P0-D10 | saves scoppées game/profile/slot, atomiques, préservées à l’uninstall | Accepted | Core + Hub | 2026-07-25 | save lifecycle |
| P0-D11 | save globale historique importée uniquement par action explicite | Accepted | Product + Migration | 2026-07-25 | save lifecycle |
| P0-D12 | même processus jetable sur mobile/V0 ; enfant sur desktop public | Accepted | Architecture | 2026-07-25 | ADR-0002 |
| P0-D13 | desktop : même binaire signé en mode privé `--player-session` | Accepted | Architecture + Release | 2026-07-25 | ADR-0002, session port |
| P0-D14 | états Hub, titre, pause, erreurs et actions conditionnelles normés | Accepted | Product + Player UI | 2026-07-25 | product contracts |
| P0-D15 | `GameCompleted`, save complétée, résultat, crédits et sortie normés | Accepted | Runtime + Product | 2026-07-25 | game completion |

## Règles de gouvernance

- Changer une décision `Accepted` exige un nouvel ADR ou une révision
  explicitement versionnée de l’artefact normatif.
- Une implémentation qui diverge ne modifie pas implicitement le contrat.
- Une évolution rétrocompatible incrémente la version mineure de la politique ;
  une rupture de format incrémente `packageFormat`, `saveFormat` ou le major de
  `runtimeApi`, selon l’axe concerné.
- Les preuves Selbrume ne suffisent jamais à fermer un lot Hub générique.
