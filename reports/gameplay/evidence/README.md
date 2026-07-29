# Preuves structurées des lots FG

Les rapports Markdown restent des documents d’ingénierie, mais ils ne prouvent
pas à eux seuls qu’un lot est valide pour la révision candidate courante.

Le dashboard FG charge récursivement les fichiers versionnés
`reports/gameplay/**/*.fg-evidence.json`. Pour certifier le commit courant sans
créer de référence circulaire, la CI doit générer les reçus **après** le
checkout et les validations, dans un dossier d’artefacts externe au dépôt,
puis fournir ce dossier avec `--evidence-directory`. Un reçu peut couvrir
plusieurs lots et doit respecter ce contrat :

```json
{
  "schemaVersion": 1,
  "lotIds": ["FG-180", "FG-181"],
  "statusByLot": {
    "FG-180": "DONE",
    "FG-181": "PARTIAL"
  },
  "candidateSha": "git-sha-exact",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {
      "command": "dart test",
      "exitCode": 0,
      "outputDigest": "sha256:digest-of-preserved-output"
    }
  ],
  "sourcePaths": [
    "packages/map_core",
    "reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md"
  ]
}
```

Règles :

- `candidateSha` doit être exactement la révision certifiée ;
- chaque commande doit conserver son code de sortie réel ;
- `outputDigest` identifie la sortie complète archivée par la CI ;
- un code de sortie non nul ne peut jamais prouver un lot ;
- deux reçus du **même candidat** proposant des statuts différents pour le
  même lot sont contradictoires ; les reçus historiques ne contaminent pas le
  candidat courant ;
- un lot `DONE` sans reçu frais apparaît `MISSING`, et le mode strict le bloque ;
- les fichiers Markdown historiques ne promeuvent jamais un statut.

Validation structurelle :

```bash
cd packages/map_core
dart run tool/generate_gameplay_roadmap_dashboard.dart --check ../..
```

Certification stricte d’une révision :

```bash
cd packages/map_core
dart run tool/generate_gameplay_roadmap_dashboard.dart \
  --check \
  --candidate-sha "$GITHUB_SHA" \
  --evidence-directory "$RUNNER_TEMP/fg-evidence" \
  --require-fresh-evidence \
  ../..
```

Le mode strict doit être activé seulement lorsque les lots `DONE` exigés par la
release possèdent leurs reçus externes. Un reçu versionné ne peut pas certifier
le commit qui l’ajoute, car l’ajout du reçu modifie le SHA ; il reste une preuve
historique. Les sorties complètes désignées par `outputDigest` doivent être
conservées dans le même artefact CI.
